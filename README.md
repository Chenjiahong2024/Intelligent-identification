# 语言学习助手 / Language Learning Assistant

一个通过AI物体识别来帮助用户学习外语的iOS应用。

An iOS app that helps users learn foreign languages through AI object recognition.

## 功能特点 / Features

- 📷 **实时相机拍摄** / Real-time Camera Capture
- 🤖 **AI物体识别** / AI Object Recognition (使用Apple Vision框架)
- 🌍 **多语言支持** / Multi-language Support (英语、中文、西班牙语、法语、日语、韩语)
- 🔊 **语音朗读** / Text-to-Speech (帮助学习正确发音)
- ⚙️ **自定义设置** / Customizable Settings (选择母语和学习语言)

## 使用方法 / How to Use

1. **设置语言** / Set Languages
   - 点击右上角的设置按钮
   - 选择您的母语和想要学习的语言
   - Tap the settings button in the top right
   - Choose your native language and the language you want to learn

2. **拍摄物体** / Take a Photo
   - 点击"开始识别"按钮
   - 对准您想要识别的物体
   - 点击拍照按钮
   - Tap "Start Recognition" button
   - Point at the object you want to identify
   - Tap the capture button

3. **学习单词** / Learn the Word
   - 查看物体的多语言名称
   - 点击播放按钮听发音
   - 重复练习以加强记忆
   - View the object name in multiple languages
   - Tap the play button to hear pronunciation
   - Repeat to reinforce learning

## 技术栈 / Tech Stack

- **SwiftUI** - 现代化的UI框架
- **Vision Framework** - Apple的图像识别框架
- **AVFoundation** - 相机和语音功能
- **Core ML** - 机器学习模型支持

## AI模型策略 / AI Model Strategy

应用会自动检测系统是否启用了 **Apple Intelligence**：
- ✅ 如果设备安装并启用了 Apple Intelligence（iOS 18+），会优先调用系统内置的高精度模型
- ✅ 如果系统模型不可用，则自动切换到应用内置的 **FastVLM.mlmodelc**（需要将模型文件加入工程）
- ✅ 如果两者都不可用，最终回退到 Vision 框架默认的图像分类器

可选配置：
- 将 `FastVLM.mlmodelc`（或 `FastVLM.mlmodel`）拖入 Xcode 工程并勾选主 target
- 使用环境变量 `APPLE_INTELLIGENCE_MODEL_PATH` 指向自定义 Apple Intelligence 模型
- 设置 `FORCE_APPLE_INTELLIGENCE=1` 可在调试时强制尝试系统模型加载

The app automatically chooses the best available object-recognition model:
- ✅ Uses **Apple Intelligence** when available on iOS 18+
- ✅ Falls back to the bundled **FastVLM.mlmodelc** when the system model is missing
- ✅ Finally, defaults to the built-in Vision classifier if no Core ML model can be loaded

Optional configuration hints:
- Add `FastVLM.mlmodelc` (or `FastVLM.mlmodel`) to the target in Xcode
- Provide a custom Apple Intelligence path via `APPLE_INTELLIGENCE_MODEL_PATH`
- Set `FORCE_APPLE_INTELLIGENCE=1` during debugging to force the system model path

## 系统要求 / Requirements

- iOS 15.0+
- iPhone/iPad with camera
- Xcode 13.0+

## 安装步骤 / Installation

1. 打开 `Intelligent identification.xcodeproj`
2. 选择您的开发团队（Signing & Capabilities）
3. 连接您的iPhone或使用模拟器
4. 点击运行按钮

1. Open `Intelligent identification.xcodeproj`
2. Select your development team (Signing & Capabilities)
3. Connect your iPhone or use simulator
4. Press the Run button

## 支持的物体 / Supported Objects

应用目前包含35+常见物品的翻译，包括：
- 水果（苹果、香蕉、橙子等）
- 日常用品（杯子、瓶子、书等）
- 电子产品（手机、电脑、键盘等）
- 动物（狗、猫等）
- 交通工具（汽车、自行车等）

The app currently includes translations for 35+ common items including:
- Fruits (apple, banana, orange, etc.)
- Daily items (cup, bottle, book, etc.)
- Electronics (phone, computer, keyboard, etc.)
- Animals (dog, cat, etc.)
- Vehicles (car, bicycle, etc.)

## 注意事项 / Notes

- 首次使用时需要授予相机权限
- 识别准确度取决于照片质量和光线条件
- 某些物体可能需要多次尝试才能准确识别
- 需要添加更多翻译时，可以编辑 `TranslationService.swift`

- Camera permission is required on first use
- Recognition accuracy depends on photo quality and lighting
- Some objects may require multiple attempts for accurate recognition
- To add more translations, edit `TranslationService.swift`

## 未来计划 / Future Plans

- [ ] 添加更多物品翻译
- [ ] 支持自定义词汇表
- [ ] 添加学习历史记录
- [ ] 支持短语和句子
- [ ] 离线模式支持
- [ ] 添加单词卡片复习功能

- [ ] Add more object translations
- [ ] Support custom vocabulary
- [ ] Add learning history
- [ ] Support phrases and sentences
- [ ] Offline mode support
- [ ] Add flashcard review feature

## 许可证 / License

MIT License

## 作者 / Author

Created by Jiahong Chen

