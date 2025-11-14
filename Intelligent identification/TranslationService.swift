//
//  TranslationService.swift
//  Intelligent identification
//
//  Created by Jiahong Chen on 10/24/25.
//

import Foundation

class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    // 常见物品的翻译字典
    private let translations: [String: [String: String]] = [
        "apple": ["en": "Apple", "zh": "苹果", "es": "Manzana", "fr": "Pomme", "ja": "りんご", "ko": "사과"],
        "banana": ["en": "Banana", "zh": "香蕉", "es": "Plátano", "fr": "Banane", "ja": "バナナ", "ko": "바나나"],
        "orange": ["en": "Orange", "zh": "橙子", "es": "Naranja", "fr": "Orange", "ja": "オレンジ", "ko": "오렌지"],
        "book": ["en": "Book", "zh": "书", "es": "Libro", "fr": "Livre", "ja": "本", "ko": "책"],
        "pen": ["en": "Pen", "zh": "笔", "es": "Bolígrafo", "fr": "Stylo", "ja": "ペン", "ko": "펜"],
        "phone": ["en": "Phone", "zh": "手机", "es": "Teléfono", "fr": "Téléphone", "ja": "電話", "ko": "전화"],
        "computer": ["en": "Computer", "zh": "电脑", "es": "Computadora", "fr": "Ordinateur", "ja": "コンピューター", "ko": "컴퓨터"],
        "laptop": ["en": "Laptop", "zh": "笔记本电脑", "es": "Portátil", "fr": "Ordinateur portable", "ja": "ノートパソコン", "ko": "노트북"],
        "cup": ["en": "Cup", "zh": "杯子", "es": "Taza", "fr": "Tasse", "ja": "カップ", "ko": "컵"],
        "bottle": ["en": "Bottle", "zh": "瓶子", "es": "Botella", "fr": "Bouteille", "ja": "ボトル", "ko": "병"],
        "chair": ["en": "Chair", "zh": "椅子", "es": "Silla", "fr": "Chaise", "ja": "椅子", "ko": "의자"],
        "table": ["en": "Table", "zh": "桌子", "es": "Mesa", "fr": "Table", "ja": "テーブル", "ko": "테이블"],
        "dog": ["en": "Dog", "zh": "狗", "es": "Perro", "fr": "Chien", "ja": "犬", "ko": "개"],
        "cat": ["en": "Cat", "zh": "猫", "es": "Gato", "fr": "Chat", "ja": "猫", "ko": "고양이"],
        "car": ["en": "Car", "zh": "汽车", "es": "Coche", "fr": "Voiture", "ja": "車", "ko": "자동차"],
        "bicycle": ["en": "Bicycle", "zh": "自行车", "es": "Bicicleta", "fr": "Vélo", "ja": "自転車", "ko": "자전거"],
        "tree": ["en": "Tree", "zh": "树", "es": "Árbol", "fr": "Arbre", "ja": "木", "ko": "나무"],
        "flower": ["en": "Flower", "zh": "花", "es": "Flor", "fr": "Fleur", "ja": "花", "ko": "꽃"],
        "water": ["en": "Water", "zh": "水", "es": "Agua", "fr": "Eau", "ja": "水", "ko": "물"],
        "coffee": ["en": "Coffee", "zh": "咖啡", "es": "Café", "fr": "Café", "ja": "コーヒー", "ko": "커피"],
        "tea": ["en": "Tea", "zh": "茶", "es": "Té", "fr": "Thé", "ja": "お茶", "ko": "차"],
        "glass": ["en": "Glass", "zh": "玻璃杯", "es": "Vaso", "fr": "Verre", "ja": "グラス", "ko": "유리잔"],
        "watch": ["en": "Watch", "zh": "手表", "es": "Reloj", "fr": "Montre", "ja": "腕時計", "ko": "시계"],
        "bag": ["en": "Bag", "zh": "包", "es": "Bolsa", "fr": "Sac", "ja": "バッグ", "ko": "가방"],
        "shoe": ["en": "Shoe", "zh": "鞋", "es": "Zapato", "fr": "Chaussure", "ja": "靴", "ko": "신발"],
        "hat": ["en": "Hat", "zh": "帽子", "es": "Sombrero", "fr": "Chapeau", "ja": "帽子", "ko": "모자"],
        "keyboard": ["en": "Keyboard", "zh": "键盘", "es": "Teclado", "fr": "Clavier", "ja": "キーボード", "ko": "키보드"],
        "mouse": ["en": "Mouse", "zh": "鼠标", "es": "Ratón", "fr": "Souris", "ja": "マウス", "ko": "마우스"],
        "door": ["en": "Door", "zh": "门", "es": "Puerta", "fr": "Porte", "ja": "ドア", "ko": "문"],
        "window": ["en": "Window", "zh": "窗户", "es": "Ventana", "fr": "Fenêtre", "ja": "窓", "ko": "창문"],
        "lamp": ["en": "Lamp", "zh": "灯", "es": "Lámpara", "fr": "Lampe", "ja": "ランプ", "ko": "램프"],
        "clock": ["en": "Clock", "zh": "时钟", "es": "Reloj", "fr": "Horloge", "ja": "時計", "ko": "시계"],
        "notebook": ["en": "Notebook", "zh": "笔记本", "es": "Cuaderno", "fr": "Cahier", "ja": "ノート", "ko": "공책"],
        "umbrella": ["en": "Umbrella", "zh": "雨伞", "es": "Paraguas", "fr": "Parapluie", "ja": "傘", "ko": "우산"],
        "sunglasses": ["en": "Sunglasses", "zh": "太阳镜", "es": "Gafas de sol", "fr": "Lunettes de soleil", "ja": "サングラス", "ko": "선글라스"],
        "camera": ["en": "Camera", "zh": "相机", "es": "Cámara", "fr": "Appareil photo", "ja": "カメラ", "ko": "카메라"]
    ]
    
    func getTranslation(for object: String, in language: String) -> String {
        let normalizedObject = object.lowercased()
        
        // 首先尝试精确匹配
        if let objectTranslations = translations[normalizedObject],
           let translation = objectTranslations[language] {
            return translation
        }
        
        // 尝试部分匹配（如果识别结果包含已知物品名称）
        for (key, objectTranslations) in translations {
            if normalizedObject.contains(key) || key.contains(normalizedObject) {
                if let translation = objectTranslations[language] {
                    return translation
                }
            }
        }
        
        // 如果没有找到翻译，返回原始文本（首字母大写）
        return object.capitalized
    }
    
    func getSupportedLanguages() -> [(code: String, name: String)] {
        return [
            ("en", "English"),
            ("zh", "中文"),
            ("es", "Español"),
            ("fr", "Français"),
            ("ja", "日本語"),
            ("ko", "한국어")
        ]
    }
}

