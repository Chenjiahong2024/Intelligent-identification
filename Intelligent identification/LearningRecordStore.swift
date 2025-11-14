import Foundation
import SwiftUI
import Combine

struct LearningRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let objectName: String
    let nativeTranslation: String
    let learningTranslation: String
    let nativeLanguageCode: String
    let learningLanguageCode: String
    
    var normalizedKey: String {
        "\(objectName.lowercased())|\(nativeLanguageCode)|\(learningLanguageCode)"
    }
}

@MainActor
final class LearningRecordStore: ObservableObject {
    @Published private(set) var records: [LearningRecord] = []
    
    private let storageKey = "learning_records_v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let cloudSyncPreferenceKey = "icloudSyncEnabled"
    private var isCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: cloudSyncPreferenceKey) }
        set { UserDefaults.standard.set(newValue, forKey: cloudSyncPreferenceKey) }
    }
    
    private let cloudSync = CloudSyncManager.shared
    private var isPreviewEnvironment: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || env["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }
    
    init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        loadRecords()
        if !isPreviewEnvironment {
            cloudSync.configure(isEnabled: isCloudSyncEnabled)
            if isCloudSyncEnabled {
                fetchRemoteRecords()
            }
        }
    }
    
    var totalEntries: Int {
        records.count
    }
    
    var uniqueItems: Int {
        Set(records.map { $0.normalizedKey }).count
    }
    
    var recentRecords: [LearningRecord] {
        Array(records.prefix(5))
    }
    
    func addRecord(objectName: String,
                   nativeTranslation: String,
                   learningTranslation: String,
                   nativeLanguageCode: String,
                   learningLanguageCode: String) {
        let trimmedObject = objectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedObject.isEmpty else { return }
        
        let newRecord = LearningRecord(
            id: UUID(),
            createdAt: Date(),
            objectName: trimmedObject,
            nativeTranslation: nativeTranslation,
            learningTranslation: learningTranslation,
            nativeLanguageCode: nativeLanguageCode,
            learningLanguageCode: learningLanguageCode
        )
        
        if shouldMergeWithLatest(newRecord) {
            records[0] = LearningRecord(
                id: records[0].id,
                createdAt: Date(),
                objectName: records[0].objectName,
                nativeTranslation: nativeTranslation,
                learningTranslation: learningTranslation,
                nativeLanguageCode: nativeLanguageCode,
                learningLanguageCode: learningLanguageCode
            )
        } else {
            records.insert(newRecord, at: 0)
        }
        
        persistRecords()
    }
    
    func remove(_ record: LearningRecord) {
        if let index = records.firstIndex(of: record) {
            records.remove(at: index)
            persistRecords()
            if isCloudSyncEnabled {
                cloudSync.deleteRecords(withIDs: [record.id])
            }
        }
    }
    
    func setCloudSyncEnabled(_ enabled: Bool) {
        guard isCloudSyncEnabled != enabled else { return }
        isCloudSyncEnabled = enabled
        if isPreviewEnvironment { return }
        cloudSync.configure(isEnabled: enabled)
        if enabled {
            fetchRemoteRecords()
            cloudSync.sync(records: records)
        }
    }
    
    func syncWithCloud() {
        guard isCloudSyncEnabled else { return }
        guard !isPreviewEnvironment else { return }
        cloudSync.sync(records: records)
    }
    
    private func shouldMergeWithLatest(_ record: LearningRecord) -> Bool {
        guard let latest = records.first else { return false }
        guard latest.normalizedKey == record.normalizedKey else { return false }
        return latest.createdAt.timeIntervalSinceNow > -180
    }
    
    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try decoder.decode([LearningRecord].self, from: data)
            records = decoded.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            records = []
        }
    }
    
    private func persistRecords() {
        do {
            let data = try encoder.encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
            if isCloudSyncEnabled {
                if !isPreviewEnvironment {
                    cloudSync.sync(records: records)
                }
            }
        } catch {
            // Ignore persistence errors for now.
        }
    }
    
    private func fetchRemoteRecords() {
        cloudSync.fetchAllRecords { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let remoteRecords):
                guard !remoteRecords.isEmpty else { return }
                Task { @MainActor in
                    self.mergeRemoteRecords(remoteRecords)
                }
            case .failure:
                break
            }
        }
    }
    
    private func mergeRemoteRecords(_ remoteRecords: [LearningRecord]) {
        var combined: [UUID: LearningRecord] = [:]
        
        for record in records {
            combined[record.id] = record
        }
        
        for record in remoteRecords {
            if let existing = combined[record.id] {
                if record.createdAt > existing.createdAt {
                    combined[record.id] = record
                }
            } else {
                combined[record.id] = record
            }
        }
        
        records = combined.values.sorted(by: { $0.createdAt > $1.createdAt })
        persistRecords()
    }
}

