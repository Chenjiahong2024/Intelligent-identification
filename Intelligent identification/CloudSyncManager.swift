import Foundation
import CloudKit
import Network
import Combine

struct CloudSyncStatus {
    enum AccountState {
        case unknown
        case available
        case noAccount
        case restricted
        case couldNotDetermine
        
        var description: String {
            switch self {
            case .unknown: return "未知"
            case .available: return "已登录"
            case .noAccount: return "未登录"
            case .restricted: return "受限"
            case .couldNotDetermine: return "无法确定"
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .available: return true
            default: return false
            }
        }
    }
    
    enum SyncState: Equatable {
        case idle
        case syncing
        case success
        case failure(String)
        
        var description: String {
            switch self {
            case .idle: return "待命"
            case .syncing: return "同步中"
            case .success: return "同步成功"
            case .failure(let message): return "失败：\(message)"
            }
        }
    }
    
    var isEnabled: Bool = false
    var networkReachable: Bool = true
    var accountState: AccountState = .unknown
    var syncState: SyncState = .idle
    var lastSyncDate: Date?
    var lastError: String?
    
    var canSync: Bool {
        isEnabled && networkReachable && accountState.isAvailable
    }
    
    var warningMessages: [String] {
        var messages: [String] = []
        if !networkReachable {
            messages.append("网络连接不可用")
        }
        if isEnabled && !accountState.isAvailable {
            messages.append("iCloud 账号不可用")
        }
        if case .failure(let message) = syncState {
            messages.append(message)
        }
        if let lastError {
            messages.append(lastError)
        }
        return Array(Set(messages))
    }
}

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published private(set) var status = CloudSyncStatus()
    
    private let container: CKContainer?
    private let database: CKDatabase?
    private let recordType = "LearningRecord"
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.intelligentidentification.cloudsync.network")
    private let isPreviewEnvironment: Bool
    
    private init() {
        let env = ProcessInfo.processInfo.environment
        self.isPreviewEnvironment = env["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || env["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
        if isPreviewEnvironment {
            self.container = nil
            self.database = nil
        } else {
            let container = CKContainer.default()
            self.container = container
            self.database = container.privateCloudDatabase
            startNetworkMonitor()
            refreshAccountStatus()
        }
    }
    
    func configure(isEnabled: Bool) {
        status.isEnabled = isEnabled
        guard !isPreviewEnvironment else { return }
        if isEnabled {
            refreshAccountStatus()
        } else {
            status.syncState = .idle
            status.lastError = nil
        }
    }
    
    func refreshStatus() {
        guard !isPreviewEnvironment else { return }
        refreshAccountStatus()
    }
    
    func sync(records: [LearningRecord]) {
        guard status.isEnabled else { return }
        guard !isPreviewEnvironment else { return }
        guard status.canSync else {
            status.syncState = .failure("当前无法同步，请检查网络或 iCloud 状态。")
            return
        }
        
        status.syncState = .syncing
        status.lastError = nil
        
        guard let database else { return }
        let ckRecords = records.map { makeCKRecord(from: $0) }
        let operation = CKModifyRecordsOperation(recordsToSave: ckRecords, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        operation.modifyRecordsResultBlock = { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success:
                    self.status.syncState = .success
                    self.status.lastSyncDate = Date()
                    self.status.lastError = nil
                case .failure(let error):
                    self.status.syncState = .failure(error.localizedDescription)
                    self.status.lastError = "iCloud 同步失败：\(error.localizedDescription)"
                }
            }
        }
        
        database.add(operation)
    }
    
    func deleteRecords(withIDs ids: [UUID]) {
        guard status.isEnabled else { return }
        guard !isPreviewEnvironment else { return }
        guard status.canSync else { return }
         
        guard let database else { return }
        let recordIDs = ids.map { CKRecord.ID(recordName: $0.uuidString) }
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.qualityOfService = .userInitiated
        operation.modifyRecordsResultBlock = { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success:
                    self.status.syncState = .success
                    self.status.lastSyncDate = Date()
                case .failure(let error):
                    self.status.syncState = .failure(error.localizedDescription)
                    self.status.lastError = "删除云端数据失败：\(error.localizedDescription)"
                }
            }
        }
        database.add(operation)
    }

    func fetchAllRecords(completion: @escaping (Result<[LearningRecord], Error>) -> Void) {
        guard status.isEnabled else {
            completion(.success([]))
            return
        }
        guard !isPreviewEnvironment else {
            completion(.success([]))
            return
        }
        guard status.canSync else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前无法同步。"])) )
            return
        }
        
        guard let database else {
            completion(.success([]))
            return
        }
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)
        var fetched: [LearningRecord] = []
        
        operation.recordMatchedBlock = { [weak self] recordID, result in
            switch result {
            case .success(let record):
                if let learningRecord = self?.makeLearningRecord(from: record) {
                    fetched.append(learningRecord)
                }
            case .failure:
                // 忽略单个记录的错误，继续处理其他记录
                break
            }
        }
        
        operation.queryResultBlock = { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success:
                    self.status.lastError = nil
                    completion(.success(fetched))
                case .failure(let error):
                    self.status.lastError = "拉取云端数据失败：\(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
        
        database.add(operation)
    }
    
    // MARK: - Private helpers
    
    private func startNetworkMonitor() {
        guard !isPreviewEnvironment else { return }
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.status.networkReachable = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func refreshAccountStatus() {
        guard !isPreviewEnvironment else { return }
        guard let container else { return }
        container.accountStatus { [weak self] accountStatus, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.status.accountState = .couldNotDetermine
                    self.status.lastError = "获取 iCloud 状态失败：\(error.localizedDescription)"
                    return
                }
                
                switch accountStatus {
                case .available:
                    self.status.accountState = .available
                case .noAccount:
                    self.status.accountState = .noAccount
                case .restricted:
                    self.status.accountState = .restricted
                case .couldNotDetermine:
                    self.status.accountState = .couldNotDetermine
                case .temporarilyUnavailable:
                    self.status.accountState = .couldNotDetermine
                @unknown default:
                    self.status.accountState = .unknown
                }
            }
        }
    }
    
    private func makeCKRecord(from record: LearningRecord) -> CKRecord {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: recordType, recordID: recordID)
        
        ckRecord["objectName"] = record.objectName as CKRecordValue
        ckRecord["nativeTranslation"] = record.nativeTranslation as CKRecordValue
        ckRecord["learningTranslation"] = record.learningTranslation as CKRecordValue
        ckRecord["nativeLanguageCode"] = record.nativeLanguageCode as CKRecordValue
        ckRecord["learningLanguageCode"] = record.learningLanguageCode as CKRecordValue
        ckRecord["createdAt"] = record.createdAt as CKRecordValue
        
        return ckRecord
    }
    
    private func makeLearningRecord(from record: CKRecord) -> LearningRecord? {
        guard
            let objectName = record["objectName"] as? String,
            let nativeTranslation = record["nativeTranslation"] as? String,
            let learningTranslation = record["learningTranslation"] as? String,
            let nativeCode = record["nativeLanguageCode"] as? String,
            let learningCode = record["learningLanguageCode"] as? String,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        
        return LearningRecord(
            id: id,
            createdAt: createdAt,
            objectName: objectName,
            nativeTranslation: nativeTranslation,
            learningTranslation: learningTranslation,
            nativeLanguageCode: nativeCode,
            learningLanguageCode: learningCode
        )
    }
}

