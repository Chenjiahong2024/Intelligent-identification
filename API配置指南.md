# 🔧 API配置指南

## ⚠️ 重要提示

当前应用中的 Google Gemini API 密钥是示例密钥，**需要替换为您自己的真实API密钥**才能正常工作。

## 🔑 获取 Google Gemini API 密钥

### 步骤 1: 访问 Google AI Studio
1. 打开浏览器访问：https://aistudio.google.com/
2. 使用您的 Google 账号登录

### 步骤 2: 创建 API 密钥
1. 点击左侧菜单的 "Get API key"
2. 点击 "Create API key"
3. 选择或创建一个 Google Cloud 项目
4. 复制生成的 API 密钥（格式类似：`AIzaSyD...`）

## 📱 配置应用

### 步骤 1: 更新 API 密钥
1. 在 Xcode 中打开项目
2. 找到文件：`GeminiAPIService.swift`
3. 找到第 14 行：
   ```swift
   private let apiKey = "AIzaSyD_example_key_replace_with_real_key"
   ```
4. 将 `"AIzaSyD_example_key_replace_with_real_key"` 替换为您的真实API密钥

### 步骤 2: 配置网络权限
1. 在项目导航器中找到 `Info.plist`
2. 右键点击 → "Open As" → "Source Code"
3. 在 `<dict>` 标签内添加以下内容：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>generativelanguage.googleapis.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```

## 🚀 测试配置

### 调试步骤：
1. 构建并运行应用
2. 拍摄一张照片进行识别
3. 打开 Xcode 控制台查看详细日志
4. 查找以下关键信息：
   - `🔗 [GeminiAPI] 完整URL: ...` - 确认URL正确
   - `🌐 [GeminiAPI] 发送API请求到: ...` - 确认网络请求发出
   - `📡 [GeminiAPI] HTTP状态码: ...` - 查看响应状态
   - `✅ [识别成功] 结果: ...` - 确认识别成功

### 常见问题排查：

#### 1. 返回 "unknown" 或识别失败
- **原因**: API密钥无效或网络权限配置错误
- **解决**: 检查API密钥是否正确，确认Info.plist网络权限配置

#### 2. 网络请求失败
- **原因**: 网络连接问题或App Transport Security配置
- **解决**: 确认设备网络连接，检查Info.plist配置

#### 3. HTTP 401 错误
- **原因**: API密钥无效或已过期
- **解决**: 重新生成API密钥并更新

#### 4. HTTP 403 错误
- **原因**: API配额不足或项目权限问题
- **解决**: 检查Google Cloud项目的API配额和计费设置

## 💡 优化建议

1. **API密钥安全**: 不要将API密钥提交到代码仓库
2. **错误处理**: 观察控制台日志来诊断问题
3. **网络环境**: 确保设备能正常访问Google服务
4. **模型选择**: 当前使用 `gemini-1.5-flash` 模型，速度快、成本低

## 🔍 调试技巧

运行应用时，控制台会输出详细的调试信息：
- 🚀 开始识别
- 📝 图片编码信息
- 🔗 API请求URL
- 📡 HTTP响应状态
- ✅ 识别成功/失败

通过这些日志可以快速定位问题所在。

---

配置完成后，您的应用就能正常使用 Google Gemini AI 进行图片识别和对话了！

