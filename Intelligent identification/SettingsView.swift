//
//  SettingsView.swift
//  Intelligent identification
//
//  Created by Jiahong Chen on 10/24/25.
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @AppStorage("nativeLanguage") private var nativeLanguage = "en"
    @AppStorage("learningLanguage") private var learningLanguage = "zh"
    @AppStorage("api_base_url") private var apiBaseURL: String = ""
    @AppStorage("api_key") private var apiKey: String = ""
    @AppStorage("model_name") private var modelName: String = ""
    @AppStorage("icloudSyncEnabled") private var isCloudSyncEnabled: Bool = false
    @EnvironmentObject private var learningStore: LearningRecordStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cloudSync = CloudSyncManager.shared
    @Environment(\.openURL) private var openURL
    
    let languages = TranslationService.shared.getSupportedLanguages()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    
                    LanguageSelectionCard(
                        title: "母语 / Native Language",
                        subtitle: "Choose the language you already speak",
                        icon: "person.crop.circle",
                        languages: languages,
                        selection: $nativeLanguage
                    )
                    
                    LanguageSelectionCard(
                        title: "学习语言 / Learning Language",
                        subtitle: "Select the language you want to practise",
                        icon: "graduationcap",
                        languages: languages,
                        selection: $learningLanguage
                    )
                    
                    CloudSyncCard(
                        isEnabled: $isCloudSyncEnabled,
                        status: cloudSync.status,
                        onToggle: { enabled in
                            learningStore.setCloudSyncEnabled(enabled)
                        },
                        onSyncNow: {
                            learningStore.syncWithCloud()
                        },
                        onRefresh: {
                            cloudSync.refreshStatus()
                        }
                    )
                    
                    APISettingsCard(apiBaseURL: $apiBaseURL, apiKey: $apiKey, modelName: $modelName)
                    
                    SupportCard(
                        onEmail: {
                            if let url = URL(string: "mailto:jiahongchen2025@outlook.com?subject=AI%E6%99%BA%E8%83%BD%E8%AF%86%E5%88%AB%E6%94%AF%E6%8C%81&body=%E8%AF%B7%E7%AE%80%E8%BF%B0%E9%97%AE%E9%A2%98%E5%9C%BA%E6%99%AF%E3%80%81%E6%9C%BA%E5%9E%8B%E4%B8%8E%E7%B3%BB%E7%BB%9F%E7%89%88%E6%9C%AC") {
                                openURL(url)
                            }
                        },
                        onOpenSite: {
                            if let url = URL(string: "https://chenjiahong2024.github.io/Intelligent-identification/contact.html") {
                                openURL(url)
                            }
                        }
                    )
                    
                    AccountManagementCard()
                    
                    AboutCard()
                    InstructionCard()
                    
                    footer
                }
                .appContainer()
                .padding(.vertical, 28)
            }
            .background(AppTheme.appBackground.ignoresSafeArea())
            .navigationTitle("设置 / Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成 / Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !isPreviewEnvironment {
                    cloudSync.configure(isEnabled: isCloudSyncEnabled)
                }
            }
        }
    }
    
    private var isPreviewEnvironment: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || env["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.accentSoft)
                        .frame(width: 52, height: 52)
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("个性化你的学习体验")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Personalize how the app speaks and displays vocabulary.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            Text("You can switch languages at any time. Changes apply instantly across the app.")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle(highlighted: true)
    }
    
    private var footer: some View {
        VStack(spacing: 6) {
            Text("语言学习助手 · Language Learning Assistant")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}

private struct SupportCard: View {
    var onEmail: () -> Void
    var onOpenSite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("帮助与支持")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("若遇到问题，欢迎通过邮件或支持网站与我们联系。")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            } icon: {
                Image(systemName: "lifepreserver")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
            }
            .labelStyle(.leadingIcon)
            
            HStack(spacing: 12) {
                Button(action: onEmail) {
                    Label("联系支持（邮件）", systemImage: "envelope")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.buttonGradient)
                        )
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
                
                Button(action: onOpenSite) {
                    Label("打开支持网站", systemImage: "safari")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(AppTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
}

private struct CloudSyncCard: View {
    @Binding var isEnabled: Bool
    let status: CloudSyncStatus
    let onToggle: (Bool) -> Void
    let onSyncNow: () -> Void
    let onRefresh: () -> Void
    
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "icloud")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud 云同步")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("在多设备间自动同步学习记录，随时保持一致。")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            Toggle(isOn: $isEnabled.animation()) {
                Text("启用 iCloud 同步")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.accent))
            .onChange(of: isEnabled) { oldValue, newValue in
                onToggle(newValue)
            }
            
            Divider()
                .background(AppTheme.divider)
            
            VStack(spacing: 12) {
                StatusRow(
                    icon: "wifi",
                    title: "网络状态",
                    value: status.networkReachable ? "正常" : "不可用",
                    valueColor: status.networkReachable ? AppTheme.positive : Color.red
                )
                
                StatusRow(
                    icon: "person.crop.circle.badge.exclam",
                    title: "iCloud",
                    value: status.accountState.description,
                    valueColor: status.accountState.isAvailable ? AppTheme.accent : Color.red
                )
                
                StatusRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "同步状态",
                    value: status.syncState.description,
                    valueColor: color(for: status.syncState)
                )
                
                StatusRow(
                    icon: "clock.arrow.circlepath",
                    title: "最近同步",
                    value: formattedLastSync(),
                    valueColor: AppTheme.secondaryText
                )
            }
            
            if !status.warningMessages.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(status.warningMessages, id: \.self) { warning in
                        Label {
                            Text(warning)
                                .font(.footnote)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .foregroundStyle(Color.red)
                    }
                }
                .padding(.top, 4)
            }
            
            HStack {
                Button(action: {
                    onRefresh()
                }) {
                    Label("重新检查", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button(action: {
                    onSyncNow()
                }) {
                    Label("立即同步", systemImage: "icloud.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(status.canSync ? AnyShapeStyle(AppTheme.buttonGradient) : AnyShapeStyle(AppTheme.divider.opacity(0.3)))
                        )
                        .foregroundStyle(Color.white)
                }
                .disabled(!status.canSync)
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
    
    private func formattedLastSync() -> String {
        guard let date = status.lastSyncDate else {
            return "尚未同步"
        }
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func color(for state: CloudSyncStatus.SyncState) -> Color {
        switch state {
        case .failure:
            return Color.red
        case .success:
            return AppTheme.positive
        case .syncing:
            return AppTheme.accent
        case .idle:
            return AppTheme.secondaryText
        }
    }
}

private struct AccountManagementCard: View {
    @EnvironmentObject private var accountStore: UserAccountStore
    @AppStorage("hasCompletedLogin") private var hasCompletedLogin = false
    @State private var showingLogoutConfirm = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var hasAccount: Bool {
        accountStore.currentAccount != nil
    }
    
    private var currentName: String {
        accountStore.currentAccount?.displayName.isEmpty == false ? (accountStore.currentAccount?.displayName ?? "") : "未设置昵称"
    }
    
    private var currentIdentifier: String {
        accountStore.currentAccount?.loginIdentifier ?? "尚未登录"
    }
    
    private var appleLinked: Bool {
        accountStore.currentAccount?.isAppleLinked ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("账号")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("管理登录方式、Apple ID 绑定以及退出登录。")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            } icon: {
                Image(systemName: "person.crop.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
            }
            .labelStyle(.leadingIcon)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(currentName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(currentIdentifier)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(AppTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: appleLinked ? "checkmark.seal.fill" : "applelogo")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(appleLinked ? AppTheme.positive : AppTheme.secondaryText)
                    Text(appleLinked ? "已绑定 Apple ID" : "未绑定 Apple ID")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                if !appleLinked {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                            accountStore.signInWithApple(credential: credential, linkToExistingAccount: true) { _ in }
                        case .failure:
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            
            Divider()
                .background(AppTheme.divider)
            
            Button(role: .destructive) {
                showingLogoutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text("退出登录 / 更换账号")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.04))
                .foregroundStyle(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!hasAccount)
            .opacity(hasAccount ? 1 : 0.45)
            .confirmationDialog("确定要退出当前账号吗？", isPresented: $showingLogoutConfirm, titleVisibility: .visible) {
                Button("退出登录", role: .destructive) {
                    accountStore.signOut()
                    hasCompletedLogin = false
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("退出后需要重新登录，学习记录仍会保留在本地及已同步的 iCloud 中。")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
}

private struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
    }
}

private struct APISettingsCard: View {
    @Binding var apiBaseURL: String
    @Binding var apiKey: String
    @Binding var modelName: String
    
    private let defaultBase = "https://hiapi.online/v1"
    private let defaultModel = "gemini-2.5-pro-preview-06-05"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("模型接口设置 / Model API")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("支持官方或中转站。中转站通常使用 Bearer sk-*** 授权方式。")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            } icon: {
                Image(systemName: "network")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
            }
            .labelStyle(.leadingIcon)
            
            VStack(spacing: 10) {
                LabeledField(title: "Base URL", placeholder: defaultBase, text: $apiBaseURL)
                LabeledField(title: "API Key", placeholder: "sk-...", text: $apiKey, isSecure: true)
                LabeledField(title: "Model", placeholder: defaultModel, text: $modelName)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
}

private struct LabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
            
            HStack {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(AppTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct LanguageSelectionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let languages: [(code: String, name: String)]
    @Binding var selection: String
    
    private func name(for code: String) -> String {
        languages.first { $0.code == code }?.name ?? code
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineSpacing(2)
                }
            }
            
            Menu {
                ForEach(languages, id: \.code) { language in
                    Button {
                        selection = language.code
                    } label: {
                        HStack {
                            Text(language.name)
                            if selection == language.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(name(for: selection))
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(AppTheme.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
}

private struct AboutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("语言学习助手 · Language Learning Assistant")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("通过拍摄物品来学习不同语言的词汇和发音")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("Learn vocabulary and pronunciation in different languages by taking photos of objects.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            } icon: {
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }
            .labelStyle(.leadingIcon)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
}

private struct InstructionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label {
                Text("使用说明 / Instructions")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("Follow these quick steps to get the best learning experience")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
            } icon: {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
            }
            .labelStyle(.leadingIcon)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: "1", title: "点击相机按钮拍摄物品", subtitle: "Tap the capture button")
                InstructionRow(number: "2", title: "AI将识别物品并显示翻译", subtitle: "AI will recognise and translate")
                InstructionRow(number: "3", title: "点击播放按钮听发音", subtitle: "Tap play to hear pronunciation")
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
}

private struct InstructionRow: View {
    let number: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft)
                    .frame(width: 30, height: 30)
                Text(number)
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LearningRecordStore())
        .environmentObject(UserAccountStore.shared)
}
