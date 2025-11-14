import Foundation
import CoreML
import Vision
import os

final class AIModelManager {
    enum ModelSource: String {
        case appleIntelligence
        case fastVLM
        case visionDefault
        
        var displayName: String {
            switch self {
            case .appleIntelligence:
                return "Apple Intelligence"
            case .fastVLM:
                return "FastVLM"
            case .visionDefault:
                return "Vision Default"
            }
        }
        
        var detail: String {
            switch self {
            case .appleIntelligence:
                return "System intelligence model"
            case .fastVLM:
                return "Bundled FastVLM Core ML model"
            case .visionDefault:
                return "Vision framework classifier"
            }
        }
    }
    
    struct ModelSelection {
        let source: ModelSource
        let model: VNCoreMLModel?
    }
    
    static let shared = AIModelManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "IntelligentIdentification", category: "AIModelManager")
    private var cachedSelection: ModelSelection?
    private(set) var currentSource: ModelSource = .visionDefault
    
    private init() {}
    
    func preferredModel() -> ModelSelection {
        if let cachedSelection {
            print("📦 [模型] 使用缓存的模型: \(cachedSelection.source.displayName)")
            return cachedSelection
        }
        
        print("🔍 [模型] 开始选择最佳模型...")
        
        if let appleSelection = loadAppleIntelligenceSelection() {
            cachedSelection = appleSelection
            currentSource = appleSelection.source
            logger.debug("Using Apple Intelligence model")
            print("✅ [模型] 选择 Apple Intelligence 模型")
            return appleSelection
        }
        
        if let fastSelection = loadFastVLMSelection() {
            cachedSelection = fastSelection
            currentSource = fastSelection.source
            logger.debug("Using bundled FastVLM model")
            print("✅ [模型] 选择 FastVLM 模型")
            return fastSelection
        }
        
        let fallback = ModelSelection(source: .visionDefault, model: nil)
        cachedSelection = fallback
        currentSource = fallback.source
        logger.debug("Falling back to Vision default classifier")
        print("⚠️ [模型] 使用 Vision 默认分类器 (降级方案)")
        return fallback
    }
    
    func resetCachedSelection() {
        cachedSelection = nil
        currentSource = .visionDefault
    }
    
    private func loadAppleIntelligenceSelection() -> ModelSelection? {
        print("🍎 [模型] 检查 Apple Intelligence 支持...")
        guard supportsAppleIntelligence else {
            print("❌ [模型] 当前系统不支持 Apple Intelligence")
            return nil
        }
        
        print("✅ [模型] 系统支持 Apple Intelligence")
        guard let modelURL = appleIntelligenceModelURL() else {
            logger.info("Apple Intelligence model not found on system")
            print("❌ [模型] 未找到 Apple Intelligence 模型文件")
            return nil
        }
        
        print("📁 [模型] 找到模型路径: \(modelURL.path)")
        guard let model = makeModel(from: modelURL) else {
            logger.error("Failed to load Apple Intelligence model at \(modelURL.path, privacy: .public)")
            print("❌ [模型] 加载 Apple Intelligence 模型失败")
            return nil
        }
        
        print("✅ [模型] Apple Intelligence 模型加载成功")
        return ModelSelection(source: .appleIntelligence, model: model)
    }
    
    private func loadFastVLMSelection() -> ModelSelection? {
        print("🚀 [模型] 检查 FastVLM 模型...")
        guard let url = fastVLMModelURL() else {
            logger.error("FastVLM model missing from bundle. Add FastVLM.mlmodelc to the target.")
            print("❌ [模型] FastVLM 模型未添加到项目中")
            print("💡 [提示] 需要将 FastVLM.mlmodelc 添加到项目以使用自定义模型")
            return nil
        }
        
        print("📁 [模型] 找到 FastVLM 模型: \(url.path)")
        guard let model = makeModel(from: url) else {
            logger.error("Failed to load FastVLM model at \(url.path, privacy: .public)")
            print("❌ [模型] 加载 FastVLM 模型失败")
            return nil
        }
        
        print("✅ [模型] FastVLM 模型加载成功")
        return ModelSelection(source: .fastVLM, model: model)
    }
    
    private func makeModel(from url: URL) -> VNCoreMLModel? {
        do {
            let mlModel: MLModel
            if url.pathExtension == "mlmodel" {
                let compiledURL = try MLModel.compileModel(at: url)
                mlModel = try MLModel(contentsOf: compiledURL)
            } else {
                mlModel = try MLModel(contentsOf: url)
            }
            return try VNCoreMLModel(for: mlModel)
        } catch {
            logger.error("Model loading error: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    private var supportsAppleIntelligence: Bool {
        guard #available(iOS 18.0, *) else { return false }
        if ProcessInfo.processInfo.environment["FORCE_APPLE_INTELLIGENCE"] == "1" {
            return true
        }
        if NSClassFromString("AICoreWorkspace") != nil {
            return true
        }
        return false
    }
    
    private func appleIntelligenceModelURL() -> URL? {
        if let overridePath = ProcessInfo.processInfo.environment["APPLE_INTELLIGENCE_MODEL_PATH"],
           FileManager.default.fileExists(atPath: overridePath) {
            return URL(fileURLWithPath: overridePath)
        }
        
        if let bundleURL = Bundle.main.url(forResource: "AppleIntelligenceObjectClassifier", withExtension: "mlmodelc") {
            return bundleURL
        }
        
        let candidateSystemPaths = [
            "/System/Library/PrivateFrameworks/AppleIntelligence.framework/Models/ObjectUnderstanding.mlmodelc",
            "/System/Library/CoreServices/AppleIntelligence/ObjectUnderstanding.mlmodelc"
        ]
        for path in candidateSystemPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    private func fastVLMModelURL() -> URL? {
        if let bundleURL = Bundle.main.url(forResource: "FastVLM", withExtension: "mlmodelc") {
            return bundleURL
        }
        if let rawURL = Bundle.main.url(forResource: "FastVLM", withExtension: "mlmodel") {
            return rawURL
        }
        return nil
    }
}
