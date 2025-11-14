//
//  ContentView.swift
//  Intelligent identification
//
//  Created by Jiahong Chen  on 10/24/25.
//

import SwiftUI

private struct HomeView: View {
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
    @State private var recognizedObject: String?
    @State private var cutoutImage: UIImage?
    @State private var isRecognizing = false
    @State private var showingResult = false
    @State private var feedback: RecognitionFeedback?
    @State private var bannerData: RecognitionBannerData?
    
    @AppStorage("nativeLanguage") private var nativeLanguage = "en"
    @AppStorage("learningLanguage") private var learningLanguage = "zh"
    @EnvironmentObject private var learningStore: LearningRecordStore
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroHeader
                        .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        LanguageInfoBox(
                            title: "母语",
                            subtitle: "Native",
                            language: getLanguageName(nativeLanguage),
                            icon: "person.fill"
                        )
                        
                        LanguageInfoBox(
                            title: "学习",
                            subtitle: "Learning",
                            language: getLanguageName(learningLanguage),
                            icon: "sparkles"
                        )
                    }
                    
                    LearningSummaryCard()
                        .transition(.opacity)
                    
                    Button(action: {
                        isShowingCamera = true
                    }) {
                        Label("开始识别 / Start Recognition", systemImage: "camera")
                            .font(.headline)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    TipCard()
                        .padding(.top, 8)
                }
                .appContainer(alignment: .leading)
                .padding(.bottom, 32)
            }
            .background(AppTheme.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light)
            .fullScreenCover(isPresented: $isShowingCamera) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    CameraView(capturedImage: $capturedImage, isShowingCamera: $isShowingCamera)
                        .ignoresSafeArea()
                }
                .onDisappear {
                    if let image = capturedImage {
                        recognizeObject(in: image)
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                if let image = capturedImage, let object = recognizedObject {
                    RecognitionResultView(image: image, objectName: object, cutoutImage: cutoutImage)
                }
            }
            .overlay {
                ZStack {
                    if isRecognizing {
                        RecognizingOverlay()
                            .transition(.opacity)
                    }
                    if let style = feedback {
                        RecognitionFeedbackOverlay(style: style)
                            .transition(.opacity)
                    }
                }
            }
            .overlay(alignment: .top) {
                if let data = bannerData {
                    TopRecognitionBanner(data: data)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                        .padding(.horizontal, 12)
                }
            }
        }
    }
    
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("拍照识别 · 即刻开口")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            
            Text("Capture everyday objects and learn how to pronounce them in your chosen language.")
                .font(.callout)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle(highlighted: true)
    }
    
    private func getLanguageName(_ code: String) -> String {
        let languages = TranslationService.shared.getSupportedLanguages()
        return languages.first { $0.code == code }?.name ?? code
    }
    
    private func recognizeObject(in image: UIImage) {
        isRecognizing = true
        cutoutImage = nil
        print("🚀 [开始识别] 图片尺寸: \(image.size)")
        
        // 为保证顶部弹窗先显示母语（例如英语）再显示学习语言（例如简体中文），
        // 这里将识别结果固定请求为“母语”语言。
        ObjectRecognitionService.shared.recognizeObject(in: image, targetLanguage: nativeLanguage) { result in
            DispatchQueue.main.async {
                if let objectName = result, !objectName.isEmpty {
                    print("✅ [识别完成] 结果: \(objectName)")
                    recognizedObject = objectName
                    HapticFeedback.notify(.success)
                    feedback = .success
                    presentTopBanner(for: image, objectName: objectName)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        feedback = nil
                    }
                    // 执行扣像流程
                    ImageSegmentationService.shared.cutoutPrimaryObject(from: image) { cutout in
                        DispatchQueue.main.async {
                            self.cutoutImage = cutout
                            self.isRecognizing = false
                            self.showingResult = true
                        }
                    }
                } else {
                    print("⚠️ [识别完成] 无法识别物体")
                    recognizedObject = "Unknown Object"
                    HapticFeedback.notify(.error)
                    feedback = .failure
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        feedback = nil
                    }
                    isRecognizing = false
                    showingResult = true
                }
            }
        }
    }
}

struct LanguageInfoBox: View {
    let title: String
    let subtitle: String
    let language: String
    var icon: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.smallCaps())
                    .foregroundStyle(AppTheme.secondaryText)
                Text(subtitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.tertiaryText)
                Text(language)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(0.18), radius: 8, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct TipCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .padding(10)
                    .background(AppTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("对准物体并保持稳定")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Steady your shot for clearer recognition")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            HStack(spacing: 12) {
                TipTag(systemImage: "speaker.wave.2.fill", text: "多语言朗读")
                TipTag(systemImage: "wand.and.rays", text: "AI识别")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle(highlighted: true)
    }
}

private struct TipTag: View {
    let systemImage: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppTheme.surfaceMuted)
        .clipShape(Capsule(style: .continuous))
    }
}

private struct LearningSummaryCard: View {
    @EnvironmentObject private var learningStore: LearningRecordStore
    
    private var hasRecords: Bool {
        !learningStore.records.isEmpty
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationLink {
            LearningHistoryView()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.closed")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                        Text("学习记录 / Learning Log")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.8))
                }
                
                if hasRecords {
                    HStack(spacing: 18) {
                        SummaryMetric(title: "累计次数", value: "\(learningStore.totalEntries)")
                        Divider()
                            .frame(height: 32)
                            .background(AppTheme.divider)
                        SummaryMetric(title: "独立词汇", value: "\(learningStore.uniqueItems)")
                    }
                    
                    if let latest = learningStore.records.first {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("最近学习 · \(dateFormatter.string(from: latest.createdAt))")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.secondaryText)
                            
                            Text(latest.learningTranslation)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            
                            Text(latest.nativeTranslation)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("开始你的第一条学习记录")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                        Text("识别物体后，这里会展示你的学习轨迹。")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(AppTheme.divider.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: AppTheme.shadowColor.opacity(0.18), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private struct SummaryMetric: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }
        }
    }
}

private struct RecognizingOverlay: View {
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.18 : 0)
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.accent)
                    .controlSize(.large)
                
                VStack(spacing: 4) {
                    Text("正在识别图片…")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("我们会尽快给出结果")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 28)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(AppTheme.divider.opacity(0.25), lineWidth: 0.5)
            )
            .shadow(color: AppTheme.shadowColor.opacity(0.25), radius: 12, x: 0, y: 6)
            .scaleEffect(isVisible ? 1 : 0.95)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.2)) {
                isVisible = true
            }
        }
    }
}

private enum RecognitionFeedback {
    case success
    case failure
}

private struct RecognitionFeedbackOverlay: View {
    let style: RecognitionFeedback
    @State private var isVisible = false
    
    private var tintColor: Color {
        switch style {
        case .success: return AppTheme.positive
        case .failure: return Color.red
        }
    }
    
    private var symbolName: String {
        style == .success ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    private var message: String {
        style == .success ? "识别成功" : "识别失败"
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: symbolName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                Capsule(style: .continuous)
                    .fill(tintColor.gradient)
            )
            .shadow(color: tintColor.opacity(0.25), radius: 8, x: 0, y: 4)
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 32)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isVisible = true
            }
        }
    }
}

private enum HapticFeedback {
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

private struct RecognitionBannerData {
    let nativeTitle: String
    let learningTitle: String
    var nativePurpose: String?
    var learningPurpose: String?
}

private struct TopRecognitionBanner: View {
    let data: RecognitionBannerData
    @State private var isVisible = false
    
    var body: some View {
        let hasNativePurpose = (data.nativePurpose?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        let hasLearningPurpose = (data.learningPurpose?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("识别结果")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
            
            Text(data.nativeTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
            
            Text(data.learningTitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
            
            if hasNativePurpose || hasLearningPurpose {
                Divider()
                    .background(AppTheme.divider)
                VStack(alignment: .leading, spacing: 4) {
                    if let native = data.nativePurpose, hasNativePurpose {
                        Text(native)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    if let learning = data.learningPurpose, hasLearningPurpose {
                        Text(learning)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.divider.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: AppTheme.shadowColor.opacity(0.18), radius: 8, x: 0, y: 4)
        .offset(y: isVisible ? 0 : -18)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isVisible = true
            }
        }
    }
}

extension HomeView {
    private func presentTopBanner(for image: UIImage, objectName: String) {
        let nativeCode = nativeLanguage
        let learningCode = learningLanguage
        let nativeTitle = TranslationService.shared.getTranslation(for: objectName, in: nativeCode)
        let learningTitle = TranslationService.shared.getTranslation(for: objectName, in: learningCode)
        bannerData = RecognitionBannerData(nativeTitle: nativeTitle, learningTitle: learningTitle, nativePurpose: nil, learningPurpose: nil)
        learningStore.addRecord(
            objectName: objectName,
            nativeTranslation: nativeTitle,
            learningTranslation: learningTitle,
            nativeLanguageCode: nativeCode,
            learningLanguageCode: learningCode
        )
        
        // 问用途（母语）
        ObjectRecognitionService.shared.askAboutImage("What is this used for? Answer in one short phrase.", image: image, targetLanguage: nativeCode) { answer in
            DispatchQueue.main.async {
                if var current = bannerData {
                    current.nativePurpose = cleanPurpose(answer)
                    bannerData = current
                }
            }
        }
        
        // 问用途（学习语言）
        ObjectRecognitionService.shared.askAboutImage("这个是什么用途？请用简短词组回答。", image: image, targetLanguage: learningCode) { answer in
            DispatchQueue.main.async {
                if var current = bannerData {
                    current.learningPurpose = cleanPurpose(answer)
                    bannerData = current
                }
            }
        }
        
        // 自动消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation { bannerData = nil }
        }
    }
    
    private func cleanPurpose(_ text: String?) -> String? {
        guard var t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        // 去除多余标点或句号
        if t.hasSuffix(".") { t.removeLast() }
        return t
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("识别", systemImage: "camera.viewfinder")
                }
                .tag(0)
            
            NavigationStack {
                LearningHistoryView()
            }
            .tabItem {
                Label("学习记录", systemImage: "book.closed")
            }
            .tag(1)

            NavigationStack {
                PermissionsStatusView()
            }
            .tabItem {
                Label("权限", systemImage: "checkmark.shield")
            }
            .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LearningRecordStore())
}
