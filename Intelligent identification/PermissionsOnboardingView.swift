import SwiftUI
import AVFoundation
import Photos
import UIKit

struct PermissionsOnboardingView: View {
    enum Mode {
        case onboarding
        case review
    }
    
    @Binding var isCompleted: Bool
    var mode: Mode = .onboarding
    var onFinished: (() -> Void)? = nil
    
    @State private var cameraStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var photoStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var isRequesting = false
    @State private var activeRequest: PermissionTarget?
    @State private var heroRotation: Double = 0
    @State private var heroGlow = false
    
    private var allGranted: Bool {
        cameraStatus == .authorized && (photoStatus == .authorized || photoStatus == .limited)
    }
    
    // 限制卡片与头部区域的最大宽度，避免贴边或越过圆角（与全局主题保持一致）
    private let contentHorizontalPadding: CGFloat = AppTheme.horizontalPadding
    private var cardMaxWidth: CGFloat { AppTheme.contentMaxWidth }
    
    var body: some View {
        ZStack {
            AppTheme.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                        .frame(maxWidth: cardMaxWidth, alignment: .center)
                    
                    PermissionCard(
                        icon: "camera.viewfinder",
                        title: "相机权限",
                        description: "用于捕捉和识别物体图像",
                        statusText: cameraStatusDisplay,
                        status: cameraCardStatus,
                        actionTitle: cameraActionTitle,
                        isActionEnabled: cameraActionEnabled,
                        isLoading: isRequesting && activeRequest == .camera,
                        action: requestCameraAccess
                    )
                    .frame(maxWidth: cardMaxWidth, alignment: .center)
                    
                    PermissionCard(
                        icon: "photo.on.rectangle",
                        title: "相册访问",
                        description: "保存学习记录与导入已有图片",
                        statusText: photoStatusDisplay,
                        status: photoCardStatus,
                        actionTitle: photoActionTitle,
                        isActionEnabled: photoActionEnabled,
                        isLoading: isRequesting && activeRequest == .photo,
                        action: requestPhotoAccess
                    )
                    .frame(maxWidth: cardMaxWidth, alignment: .center)
                    
                    Button(action: handlePrimaryAction) {
                        HStack(spacing: 8) {
                            Spacer(minLength: 0)
                            Text(primaryButtonTitle)
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: primaryButtonIcon)
                                .font(.subheadline.weight(.semibold))
                                .symbolRenderingMode(.hierarchical)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                        .background(AppTheme.accent)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: AppTheme.accent.opacity(0.12), radius: 6, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 0.5)
                        )
                        .scaleEffect(isPrimaryButtonDisabled ? 0.98 : 1)
                        .opacity(isPrimaryButtonDisabled ? 0.55 : 1)
                    }
                    .disabled(isPrimaryButtonDisabled)
                    .frame(maxWidth: cardMaxWidth, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: cameraStatus) { _, _ in
            completeIfPossible()
        }
        .onChange(of: photoStatus) { _, _ in
            completeIfPossible()
        }
        .onAppear {
            refreshAuthorizationStatus()
        }
    }
    
    private var headerSection: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .background(.clear)
                .overlay(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            AppTheme.accent.opacity(0.55),
                            AppTheme.learningColor.opacity(0.45),
                            AppTheme.accent.opacity(0.32)
                        ]),
                        center: .center,
                        angle: .degrees(heroRotation)
                    )
                    .blendMode(.softLight)
                    .opacity(0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.2), lineWidth: 0.8)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("权限状态")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                
                Text("授予关键权限后，我们才能为你提供最流畅的拍照识别体验。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Capsule(style: .continuous)
                        .fill(AppTheme.accent.opacity(0.18))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 0.8)
                        )
                        .frame(width: 90, height: 22)
                        .overlay(
                            Label("即时生效", systemImage: "sparkles")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                                .labelStyle(.iconOnly)
                                .overlay(
                                    Text("即时生效")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(AppTheme.accent)
                                        .padding(.leading, 18)
                                )
                        )
                    
                    Capsule(style: .continuous)
                        .fill(AppTheme.learningColor.opacity(0.18))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AppTheme.learningColor.opacity(0.3), lineWidth: 0.8)
                        )
                        .frame(width: 90, height: 22)
                        .overlay(
                            Label("本地处理", systemImage: "lock.shield")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.learningColor)
                                .labelStyle(.iconOnly)
                                .overlay(
                                    Text("本地处理")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(AppTheme.learningColor)
                                        .padding(.leading, 18)
                                )
                        )
                }
            }
            .padding(.vertical, 16)
            .padding(.leading, 16)
            .padding(.trailing, 75)
            
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.22))
                        .frame(width: 60, height: 60)
                        .blur(radius: heroGlow ? 10 : 6)
                    Circle()
                        .fill(AppTheme.learningColor.opacity(0.18))
                        .frame(width: 48, height: 48)
                        .blur(radius: heroGlow ? 5 : 2)
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .shadow(color: AppTheme.accent.opacity(0.6), radius: 6, x: 0, y: 3)
                }
                .scaleEffect(heroGlow ? 1.04 : 0.96)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: heroGlow)
                .padding(.trailing, 16)
            }
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.shadowColor.opacity(0.35), radius: 10, x: 0, y: 6)
        .onAppear {
            if heroRotation == 0 {
                withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                    heroRotation = 360
                }
            }
            heroGlow = true
        }
    }
    
    private var primaryButtonTitle: String {
        mode == .onboarding ? "开始使用" : "完成检查"
    }
    
    private var primaryButtonIcon: String {
        mode == .onboarding ? "arrow.right.circle.fill" : "checkmark.circle.fill"
    }
    
    private var isPrimaryButtonDisabled: Bool {
        switch mode {
        case .onboarding:
            return !allGranted || isRequesting
        case .review:
            return isRequesting
        }
    }
    
    private func handlePrimaryAction() {
        switch mode {
        case .onboarding:
            isCompleted = true
        case .review:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onFinished?()
        }
    }
    
    private var cameraCardStatus: PermissionCard.CardStatus {
        switch cameraStatus {
        case .authorized:
            return .granted
        case .notDetermined:
            return .pending
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .pending
        }
    }
    
    private var photoCardStatus: PermissionCard.CardStatus {
        switch photoStatus {
        case .authorized:
            return .granted
        case .limited:
            return .limited
        case .notDetermined:
            return .pending
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .pending
        }
    }
    
    private func requestCameraAccess() {
        activeRequest = nil
        switch cameraStatus {
        case .authorized:
            break
        case .denied, .restricted:
            openSystemSettings()
        case .notDetermined:
            activeRequest = .camera
            isRequesting = true
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraStatus = granted ? .authorized : AVCaptureDevice.authorizationStatus(for: .video)
                    isRequesting = false
                    activeRequest = nil
                }
            }
        @unknown default:
            break
        }
    }
    
    private func requestPhotoAccess() {
        activeRequest = nil
        switch photoStatus {
        case .authorized, .limited:
            break
        case .denied, .restricted:
            openSystemSettings()
        case .notDetermined:
            activeRequest = .photo
            isRequesting = true
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    photoStatus = status
                    isRequesting = false
                    activeRequest = nil
                }
            }
        @unknown default:
            break
        }
    }
    
    private func completeIfPossible() {
        guard mode == .onboarding else { return }
        if allGranted {
            isCompleted = true
        }
    }
    
    private var cameraActionEnabled: Bool {
        switch cameraStatus {
        case .authorized:
            return false
        case .denied, .restricted, .notDetermined:
            return true
        @unknown default:
            return false
        }
    }
    
    private var photoActionEnabled: Bool {
        switch photoStatus {
        case .authorized, .limited:
            return false
        case .denied, .restricted, .notDetermined:
            return true
        @unknown default:
            return false
        }
    }
    
    private var cameraStatusDisplay: String {
        switch cameraStatus {
        case .authorized:
            return "已开启 · 可使用相机"
        case .notDetermined:
            return "未授权 · 需要相机权限"
        case .denied, .restricted:
            return "受限 · 请在系统设置中开启"
        @unknown default:
            return "未知状态"
        }
    }
    
    private var photoStatusDisplay: String {
        switch photoStatus {
        case .authorized:
            return "已开启 · 可访问相册"
        case .limited:
            return "部分开启 · 请确保包含学习照片"
        case .notDetermined:
            return "未授权 · 需要访问相册"
        case .denied, .restricted:
            return "受限 · 请在系统设置中开启"
        @unknown default:
            return "未知状态"
        }
    }
    
    private var cameraActionTitle: String {
        switch cameraStatus {
        case .authorized:
            return "已授权"
        case .denied, .restricted:
            return "前往设置"
        case .notDetermined:
            return "申请授权"
        @unknown default:
            return "检查状态"
        }
    }
    
    private var photoActionTitle: String {
        switch photoStatus {
        case .authorized, .limited:
            return "已授权"
        case .denied, .restricted:
            return "前往设置"
        case .notDetermined:
            return "申请授权"
        @unknown default:
            return "检查状态"
        }
    }
    
    private func refreshAuthorizationStatus() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}

fileprivate struct PermissionCard: View {
    enum CardStatus: Equatable {
        case granted
        case limited
        case pending
        case denied
        
        var accent: Color {
            switch self {
            case .granted:
                return AppTheme.positive
            case .limited:
                return AppTheme.warning
            case .pending:
                return AppTheme.accent
            case .denied:
                return Color.red.opacity(0.85)
            }
        }
        
        var gradientColors: [Color] {
            switch self {
            case .granted:
                return [AppTheme.positive.opacity(0.75), AppTheme.accent.opacity(0.35)]
            case .limited:
                return [AppTheme.warning.opacity(0.7), AppTheme.learningColor.opacity(0.35)]
            case .pending:
                return [AppTheme.accent.opacity(0.65), AppTheme.learningColor.opacity(0.4)]
            case .denied:
                return [Color.red.opacity(0.78), Color.orange.opacity(0.35)]
            }
        }
        
        var badgeText: String {
            switch self {
            case .granted: return "已授权"
            case .limited: return "部分授权"
            case .pending: return "待授权"
            case .denied: return "权限受限"
            }
        }
        
        var badgeSymbol: String {
            switch self {
            case .granted: return "checkmark.seal.fill"
            case .limited: return "exclamationmark.arrow.triangle.2.circlepath"
            case .pending: return "hourglass"
            case .denied: return "xmark.octagon.fill"
            }
        }
        
        var statusSymbol: String {
            switch self {
            case .granted: return "checkmark.circle.fill"
            case .limited: return "exclamationmark.triangle.fill"
            case .pending: return "clock.fill"
            case .denied: return "lock.slash.fill"
            }
        }
    }
    
    let icon: String
    let title: String
    let description: String
    let statusText: String
    let status: CardStatus
    let actionTitle: String
    let isActionEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        description: String,
        statusText: String,
        status: CardStatus,
        actionTitle: String,
        isActionEnabled: Bool,
        isLoading: Bool,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.statusText = statusText
        self.status = status
        self.actionTitle = actionTitle
        self.isActionEnabled = isActionEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    @State private var animateBackground = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(status.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(status.accent.opacity(0.35), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(status.accent)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(description)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 4)
                
                HStack(spacing: 3) {
                    Image(systemName: status.badgeSymbol)
                        .font(.system(size: 9, weight: .bold))
                    Text(status.badgeText)
                        .font(.system(size: 9, weight: .semibold))
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(status.accent.opacity(0.15))
                .foregroundStyle(status.accent)
                .clipShape(Capsule(style: .continuous))
            }
            
            Divider()
                .background(AppTheme.divider)
            
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: status.statusSymbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(status.accent)
                
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 2)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(status.accent)
                        .scaleEffect(0.7)
                } else {
                    Button(action: action) {
                        HStack(spacing: 3) {
                            Text(actionTitle)
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: isActionEnabled ? "arrow.up.right.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(AppTheme.surfaceMuted)
                        .foregroundStyle(status.accent)
                        .clipShape(Capsule(style: .continuous))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(status.accent.opacity(0.25), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    }
                    .disabled(!isActionEnabled)
                    .opacity(isActionEnabled ? 1 : 0.45)
                }
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: status.gradientColors,
                            startPoint: animateBackground ? .topLeading : .bottomTrailing,
                            endPoint: animateBackground ? .bottomTrailing : .topLeading
                        )
                    )
                    .opacity(0.25)
                    .blendMode(.softLight)
                    .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: animateBackground)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(status.accent.opacity(0.2), lineWidth: 0.7)
        )
        .shadow(color: status.accent.opacity(0.12), radius: 8, x: 0, y: 4)
        .onAppear { animateBackground = true }
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: status)
    }
}

private enum PermissionTarget {
    case camera
    case photo
}

