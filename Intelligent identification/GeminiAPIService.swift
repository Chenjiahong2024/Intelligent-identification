//
//  GeminiAPIService.swift
//  Intelligent identification
//
//  Created by Assistant on 10/31/25.
//

import Foundation
import UIKit

class GeminiAPIService {
    static let shared = GeminiAPIService()
    
    // 读取用户配置（用于中转站/自定义网关）
    private var configuredApiKey: String {
        (UserDefaults.standard.string(forKey: "api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var configuredModelName: String {
        (UserDefaults.standard.string(forKey: "model_name") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var configuredBaseURL: String {
        (UserDefaults.standard.string(forKey: "api_base_url") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private init() {}
    
    func recognizeObject(in image: UIImage, targetLanguage: String = "en", completion: @escaping (String?) -> Void) {
        print("🚀 [GeminiAPI] 开始识别图片，目标语言: \(targetLanguage)")
        
        guard let base64String = prepareBase64Image(image) else {
            print("❌ [GeminiAPI] 无法转换图片为JPEG格式")
            completion(nil)
            return
        }
        
        print("📝 [GeminiAPI] 图片已编码为Base64，大小: \(base64String.count) 字符")
        
        let requestBody = createRecognitionRequestBody(with: base64String, targetLanguage: targetLanguage)
        
        sendAPIRequest(with: requestBody, completion: completion)
    }
    
    func askAboutImage(_ question: String, image: UIImage, targetLanguage: String = "en", completion: @escaping (String?) -> Void) {
        print("🚀 [GeminiAPI] 基于图片回答问题: \(question)")
        
        guard let base64String = prepareBase64Image(image) else {
            print("❌ [GeminiAPI] 无法转换图片为JPEG格式")
            completion(nil)
            return
        }
        let requestBody = createQuestionRequestBody(with: base64String, question: question, targetLanguage: targetLanguage)
        
        sendAPIRequest(with: requestBody, completion: completion)
    }
    
    private func sendAPIRequest(with requestBody: [String: Any], completion: @escaping (String?) -> Void) {
        let base = configuredBaseURL
        let model = configuredModelName
        let key = configuredApiKey
        guard !base.isEmpty else {
            print("❌ [GeminiAPI] Base URL 为空，请在设置中填写。")
            completion(nil)
            return
        }
        guard !model.isEmpty else {
            print("❌ [GeminiAPI] 模型名称为空，请在设置中填写。")
            completion(nil)
            return
        }

        let isGoogleAPI = base.contains("googleapis.com")
        let isOpenAICompatible = !isGoogleAPI
        print("🧩 [GeminiAPI] 配置摘要 -> base: \(base), googleAPI: \(isGoogleAPI), openaiCompat: \(isOpenAICompatible))")

        if isGoogleAPI && key.isEmpty {
            print("⚠️ [GeminiAPI] Google Gemini 端点需要 API Key（key=... 查询参数）。请在设置中填写 API Key。")
            completion(nil)
            return
        }
        if !isGoogleAPI && key.isEmpty {
            print("⚠️ [GeminiAPI] OpenAI 兼容端点通常需要 Bearer Token。请在设置中填写 API Key。")
            completion(nil)
            return
        }

        let urlString: String = {
            if isOpenAICompatible {
                // 适配 OpenAI Chat Completions 风格中转站
                if base.hasSuffix("/v1/chat/completions") {
                    return base
                } else if base.hasSuffix("/v1") || base.hasSuffix("/v1/") {
                    return "\(base)/chat/completions"
                } else {
                    return "\(base)/v1/chat/completions"
                }
            } else {
                // 原生 Gemini 端点（需要 key 查询参数）
                if base.hasSuffix("/models") {
                    return "\(base)/\(model):generateContent?key=\(key)"
                } else {
                    return "\(base)/models/\(model):generateContent?key=\(key)"
                }
            }
        }()
        print("🔗 [GeminiAPI] 完整URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [GeminiAPI] 无效的API URL: \(urlString)")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if isOpenAICompatible {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 30.0
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            // 打印请求体（用于调试）
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📝 [GeminiAPI] 请求体: \(jsonString.prefix(500))...")
            }
        } catch {
            print("❌ [GeminiAPI] JSON序列化失败: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        print("🌐 [GeminiAPI] 发送API请求到: \(url.host ?? "unknown")")
        print("🔑 [GeminiAPI] 使用模型: \(configuredModelName)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [GeminiAPI] 网络请求失败: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("❌ [GeminiAPI] 错误代码: \(nsError.code), 域: \(nsError.domain)")
                }
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [GeminiAPI] 无效的HTTP响应")
                completion(nil)
                return
            }
            
            print("📡 [GeminiAPI] HTTP状态码: \(httpResponse.statusCode)")
            print("📡 [GeminiAPI] 响应头: \(httpResponse.allHeaderFields)")
            
            guard let data = data else {
                print("❌ [GeminiAPI] 响应数据为空")
                completion(nil)
                return
            }
            
            print("📦 [GeminiAPI] 响应数据长度: \(data.count) 字节")
            
            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [GeminiAPI] API错误响应 (\(httpResponse.statusCode)): \(errorString)")
                }
                completion(nil)
                return
            }
            
            self.parseResponse(data: data, completion: completion)
        }.resume()
    }
    
    private func createRecognitionRequestBody(with base64Image: String, targetLanguage: String) -> [String: Any] {
        let languagePrompt = getLanguagePrompt(for: targetLanguage)
        let prompt = """
        请识别这张图片中的主要物体。用\(languagePrompt)回答，只返回物体名称，不要包含任何其他描述（例如：apple、book、car）。
        If multiple objects exist, return the most prominent one. Respond with only the object name.
        """
        
        let useHeaderAuth = !configuredApiKey.hasPrefix("AIza") || !configuredBaseURL.contains("googleapis.com")
        let isOpenAICompatible = useHeaderAuth && !configuredBaseURL.contains("googleapis.com")
        if isOpenAICompatible {
            // OpenAI chat completions 兼容格式
            return [
                "model": configuredModelName,
                "temperature": 0.1,
                "messages": [
                    ["role": "system", "content": "You are an image recognition assistant. Reply only with the object name in \(languagePrompt)."],
                    [
                        "role": "user",
                        "content": [
                            ["type": "text", "text": prompt],
                            [
                                "type": "image_url",
                                "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]
                            ]
                        ]
                    ]
                ]
            ]
        }
        
        // Gemini 原生格式
        return [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topK": 1,
                "topP": 0.8,
                "maxOutputTokens": 50
            ]
        ]
    }
    
    private func createQuestionRequestBody(with base64Image: String, question: String, targetLanguage: String) -> [String: Any] {
        let languagePrompt = getLanguagePrompt(for: targetLanguage)
        let prompt = """
        基于这张图片回答用户的问题。用\(languagePrompt)回答，保持回答简洁明了。
        
        用户问题: \(question)
        
        Answer the user's question based on this image. Respond in \(languagePrompt), keep the answer concise and clear.
        
        User question: \(question)
        """
        
        let useHeaderAuth = !configuredApiKey.hasPrefix("AIza") || !configuredBaseURL.contains("googleapis.com")
        let isOpenAICompatible = useHeaderAuth && !configuredBaseURL.contains("googleapis.com")
        if isOpenAICompatible {
            return [
                "model": configuredModelName,
                "temperature": 0.3,
                "messages": [
                    ["role": "system", "content": "You are a helpful vision assistant. Answer in \(languagePrompt)."],
                    [
                        "role": "user",
                        "content": [
                            ["type": "text", "text": prompt],
                            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                        ]
                    ]
                ]
            ]
        }
        
        return [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "topK": 3,
                "topP": 0.9,
                "maxOutputTokens": 200
            ]
        ]
    }
    
    private func getLanguagePrompt(for languageCode: String) -> String {
        switch languageCode.lowercased() {
        case "zh", "zh-cn", "zh-hans":
            return "简体中文"
        case "zh-tw", "zh-hant":
            return "繁体中文"
        case "en":
            return "English"
        case "ja":
            return "日本語"
        case "ko":
            return "한국어"
        case "fr":
            return "Français"
        case "de":
            return "Deutsch"
        case "es":
            return "Español"
        case "it":
            return "Italiano"
        case "pt":
            return "Português"
        case "ru":
            return "Русский"
        case "ar":
            return "العربية"
        case "hi":
            return "हिन्दी"
        case "th":
            return "ไทย"
        case "vi":
            return "Tiếng Việt"
        default:
            return "English"
        }
    }
    
    private func parseResponse(data: Data, completion: @escaping (String?) -> Void) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📦 [GeminiAPI] 解析JSON响应...")
                
                // 打印完整响应用于调试
                if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("🔍 [GeminiAPI] 完整响应: \(jsonString)")
                }
                
                // 1) Gemini 原生格式
                if let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first {
                    if let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]] {
                        let joined = parts.compactMap { $0["text"] as? String }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                        if !joined.isEmpty {
                            print("✅ [GeminiAPI] 解析(Gemini): \(joined)")
                            completion(joined)
                            return
                        }
                    }
                }
                
                // 2) OpenAI Chat Completions 兼容格式
                if let choices = json["choices"] as? [[String: Any]], let first = choices.first {
                    if let message = first["message"] as? [String: Any], let content = message["content"] as? String {
                        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("✅ [GeminiAPI] 解析(OpenAI message): \(trimmed)")
                        completion(trimmed)
                        return
                    }
                    if let text = first["text"] as? String {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("✅ [GeminiAPI] 解析(OpenAI text): \(trimmed)")
                        completion(trimmed)
                        return
                    }
                }
                
                // 3) 其它常见字段
                if let outputText = json["output_text"] as? String, !outputText.isEmpty {
                    let trimmed = outputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✅ [GeminiAPI] 解析(output_text): \(trimmed)")
                    completion(trimmed)
                    return
                }
                if let dataText = json["text"] as? String, !dataText.isEmpty {
                    let trimmed = dataText.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✅ [GeminiAPI] 解析(text): \(trimmed)")
                    completion(trimmed)
                    return
                }
                
                // 4) 错误信息
                if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                    print("❌ [GeminiAPI] API错误: \(message)")
                }
                
                print("❌ [GeminiAPI] 无法解析响应内容")
                completion(nil)
            } else {
                print("❌ [GeminiAPI] JSON解析失败")
                completion(nil)
            }
        } catch {
            print("❌ [GeminiAPI] JSON反序列化失败: \(error.localizedDescription)")
            completion(nil)
        }
    }

    // 压缩并Base64编码，降低中转站压力
    private func prepareBase64Image(_ image: UIImage, maxDimension: CGFloat = 1024, jpegQuality: CGFloat = 0.7) -> String? {
        let size = image.size
        let maxSide = max(size.width, size.height)
        let scale = max(1, maxSide / maxDimension)
        let targetSize = CGSize(width: size.width / scale, height: size.height / scale)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let jpg = scaled?.jpegData(compressionQuality: jpegQuality) else { return nil }
        return jpg.base64EncodedString()
    }
}
