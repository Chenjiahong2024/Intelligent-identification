//
//  SpeechService.swift
//  Intelligent identification
//
//  Created by Jiahong Chen on 10/24/25.
//

import AVFoundation

class SpeechService {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        
        // 设置语言代码
        switch language {
        case "zh":
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        case "es":
            utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        case "fr":
            utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        case "ja":
            utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        case "ko":
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        default:
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

