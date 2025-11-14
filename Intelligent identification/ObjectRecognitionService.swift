//
//  ObjectRecognitionService.swift
//  Intelligent identification
//
//  Created by Jiahong Chen on 10/24/25.
//

import UIKit

class ObjectRecognitionService {
    static let shared = ObjectRecognitionService()
    
    private let geminiAPIService = GeminiAPIService.shared
    private init() {}
    
    func recognizeObject(in image: UIImage, targetLanguage: String = "en", completion: @escaping (String?) -> Void) {
        print("🚀 [识别] 开始使用Gemini API识别图片，目标语言: \(targetLanguage)")
        print("📊 [识别] 图片尺寸: \(image.size)")
        
        geminiAPIService.recognizeObject(in: image, targetLanguage: targetLanguage) { result in
            DispatchQueue.main.async {
                if let objectName = result, !objectName.isEmpty {
                    print("✅ [识别成功] 结果: \(objectName)")
                    completion(objectName)
                } else {
                    print("❌ [识别失败] 无法识别物体")
                    completion(nil)
                }
            }
        }
    }
    
    func askAboutImage(_ question: String, image: UIImage, targetLanguage: String = "en", completion: @escaping (String?) -> Void) {
        print("🚀 [识别] 基于图片回答问题: \(question)")
        
        geminiAPIService.askAboutImage(question, image: image, targetLanguage: targetLanguage) { result in
            DispatchQueue.main.async {
                if let answer = result, !answer.isEmpty {
                    print("✅ [问答成功] 结果: \(answer)")
                    completion(answer)
                } else {
                    print("❌ [问答失败] 无法获取答案")
                    completion(nil)
                }
            }
        }
    }
    
}

