//
//  RecognitionResultView.swift
//  Intelligent identification
//
//  Created by Jiahong Chen on 10/24/25.
//

import SwiftUI

struct RecognitionResultView: View {
    let image: UIImage
    let objectName: String
    let cutoutImage: UIImage?
    @AppStorage("nativeLanguage") private var nativeLanguage = "en"
    @AppStorage("learningLanguage") private var learningLanguage = "zh"
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlayingNative = false
    @State private var isPlayingLearning = false
    @State private var showingChat = false
    @State private var chatMessages: [ChatMessage] = []
    @State private var currentQuestion: String = ""
    @State private var isLoadingAnswer = false
    
    init(image: UIImage, objectName: String, cutoutImage: UIImage? = nil) {
        self.image = image
        self.objectName = objectName
        self.cutoutImage = cutoutImage
    }

    private var nativeTranslation: String {
        TranslationService.shared.getTranslation(for: objectName, in: nativeLanguage)
    }
    
    private var learningTranslation: String {
        TranslationService.shared.getTranslation(for: objectName, in: learningLanguage)
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    photoCard
                    languageCards
                    originalRecognitionCard
                    chatButton
                    learningTips
                }
                .appContainer()
                .padding(.vertical, 28)
            }
            .background(AppTheme.appBackground.ignoresSafeArea())
            .navigationTitle("识别结果 / Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成 / Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingChat) {
                ImageChatView(
                    image: image,
                    objectName: objectName,
                    targetLanguage: learningLanguage,
                    messages: $chatMessages
                )
            }
        }
    }
    
    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("拍摄结果 / Captured")
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            
            Image(uiImage: cutoutImage ?? image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(20)
        .glassCardStyle(highlighted: true)
    }
    
    private var languageCards: some View {
        VStack(spacing: 12) {
            LanguageCard(
                title: "学习语言",
                subtitle: getLanguageName(learningLanguage),
                text: learningTranslation,
                isPlaying: $isPlayingLearning,
                accentColor: AppTheme.learningColor
            ) {
                playPronunciation(learningTranslation, language: learningLanguage, isPlaying: $isPlayingLearning)
            }
            
            LanguageCard(
                title: "母语",
                subtitle: getLanguageName(nativeLanguage),
                text: nativeTranslation,
                isPlaying: $isPlayingNative,
                accentColor: AppTheme.nativeColor
            ) {
                playPronunciation(nativeTranslation, language: nativeLanguage, isPlaying: $isPlayingNative)
            }
        }
    }
    
    private var originalRecognitionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("原始识别 / Original")
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            
            Text(objectName.isEmpty ? "Unknown" : objectName)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
    
    private var chatButton: some View {
        Button(action: {
            showingChat = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("继续提问 / Ask Questions")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("基于这张图片进行深入对话")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(20)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
    
    private var learningTips: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("点击播放按钮，模仿目标语言的语调和节奏")
                    .foregroundStyle(AppTheme.primaryText)
                    .font(.headline)
                Text("Tap play to repeat pronunciation and improve retention")
                    .foregroundStyle(AppTheme.secondaryText)
                    .font(.footnote)
            } icon: {
                Image(systemName: "ear.badge.waveform")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
            }
            .labelStyle(.leadingIcon)
            
            HStack(spacing: 14) {
                tipBadge(icon: "repeat.circle.fill", text: "重复三次 Repeat")
                tipBadge(icon: "text.book.closed.fill", text: "记录笔记 Notes")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle()
    }
    
    private func tipBadge(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(AppTheme.surfaceMuted)
        .clipShape(Capsule(style: .continuous))
    }
    
    private func getLanguageName(_ code: String) -> String {
        let languages = TranslationService.shared.getSupportedLanguages()
        return languages.first { $0.code == code }?.name ?? code
    }
    
    private func playPronunciation(_ text: String, language: String, isPlaying: Binding<Bool>) {
        isPlaying.wrappedValue = true
        SpeechService.shared.speak(text: text, language: language)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPlaying.wrappedValue = false
        }
    }
    
}

struct LanguageCard: View {
    let title: String
    let subtitle: String
    let text: String
    @Binding var isPlaying: Bool
    let accentColor: Color
    let onPlayTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "globe")
                            .font(.headline)
                            .foregroundStyle(accentColor)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.smallCaps())
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            
            HStack(alignment: .center, spacing: 16) {
                Text(text)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                Spacer()
                
                Button(action: onPlayTapped) {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(accentColor.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(isPlaying ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPlaying)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle(highlighted: true)
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date = Date()
}

struct ImageChatView: View {
    let image: UIImage
    let objectName: String
    let targetLanguage: String
    @Binding var messages: [ChatMessage]
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentQuestion: String = ""
    @State private var isLoadingAnswer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 聊天消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoadingAnswer {
                                ChatLoadingView()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .onChange(of: messages.count) { oldValue, newValue in
                        if let lastMessage = messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 输入框
                HStack(spacing: 12) {
                    TextField("输入你的问题...", text: $currentQuestion, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(AppTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .lineLimit(1...4)
                    
                    Button(action: sendQuestion) {
                        Image(systemName: "paperplane.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(currentQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.accent.opacity(0.5) : AppTheme.accent)
                            .clipShape(Circle())
                    }
                    .disabled(currentQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoadingAnswer)
                }
                .padding(16)
                .background(AppTheme.surface)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("图片问答")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if messages.isEmpty {
                    messages.append(ChatMessage(
                        content: "我看到了：\(objectName)\n\n你可以问我关于这张图片的任何问题！",
                        isUser: false
                    ))
                }
            }
        }
    }
    
    private func sendQuestion() {
        let question = currentQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isLoadingAnswer else { return }
        
        // 添加用户消息
        messages.append(ChatMessage(content: question, isUser: true))
        currentQuestion = ""
        isLoadingAnswer = true
        
        // 调用API获取答案
        ObjectRecognitionService.shared.askAboutImage(question, image: image, targetLanguage: targetLanguage) { answer in
            DispatchQueue.main.async {
                isLoadingAnswer = false
                if let answer = answer {
                    messages.append(ChatMessage(content: answer, isUser: false))
                } else {
                    messages.append(ChatMessage(content: "抱歉，我无法回答这个问题。请尝试换一种说法。", isUser: false))
                }
            }
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .frame(maxWidth: .infinity * 0.75, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .frame(maxWidth: .infinity * 0.75, alignment: .leading)
                Spacer()
            }
        }
    }
}

struct ChatLoadingView: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AppTheme.secondaryText)
                            .frame(width: 6, height: 6)
                            .scaleEffect(animating ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animating
                            )
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity * 0.75, alignment: .leading)
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    RecognitionResultView(
        image: UIImage(systemName: "photo")!,
        objectName: "apple"
    )
}

