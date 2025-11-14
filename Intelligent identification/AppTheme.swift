import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(hex: 0xF5F7FB)
    static let surface = Color.white
    static let surfaceMuted = Color(hex: 0xECF1F6)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    static let divider = Color.black.opacity(0.08)
    static let accent = Color(hex: 0x3A7FE8)
    static let accentSoft = Color(hex: 0xE2ECFB)
    static let positive = Color(hex: 0x32C28B)
    static let warning = Color(hex: 0xF2A33C)
    static let learningColor = Color(hex: 0x2F6FE3)
    static let nativeColor = Color(hex: 0x4C51BF)
    static let cardCornerRadius: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
    static let contentMaxWidth: CGFloat = 360
    
    static let accentUIColor = UIColor(red: 0.17, green: 0.49, blue: 0.96, alpha: 1.0)
    static let controlBackgroundUIColor = UIColor.systemGray5
    
    static func cardBackground(elevated: Bool = false) -> Color {
        elevated ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }
    
    static let shadowColor = Color.black.opacity(0.08)
    
    // 添加强制浅色主题支持
    static let forcedLightBackground = Color(UIColor { traitCollection in
        return UIColor.systemGroupedBackground
    })
    
    static let forcedLightSurface = Color(UIColor { traitCollection in
        return UIColor.systemBackground
    })
    
    // MARK: - Gradients
    static var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: 0xF8FAFD),
                Color(hex: 0xF1F4F9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var appBackground: some View {
        ZStack {
            Image("背景图")
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.06))
            LinearGradient(
                colors: [
                    Color.white.opacity(0.50),
                    Color.white.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent,
                Color(hex: 0x3A9CF2)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    struct GlassCardModifier: ViewModifier {
        var highlighted: Bool

        private var cornerRadius: CGFloat { highlighted ? AppTheme.cardCornerRadius + 2 : AppTheme.cardCornerRadius }

        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(highlighted ? AppTheme.surface : AppTheme.surfaceMuted)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AppTheme.divider.opacity(highlighted ? 0.35 : 0.2), lineWidth: highlighted ? 1 : 0.5)
                )
                .shadow(color: AppTheme.shadowColor.opacity(highlighted ? 0.3 : 0.18), radius: highlighted ? 12 : 8, x: 0, y: highlighted ? 6 : 3)
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct LeadingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 16) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == LeadingIconLabelStyle {
    static var leadingIcon: LeadingIconLabelStyle { LeadingIconLabelStyle() }
}

extension View {
    func glassCardStyle(highlighted: Bool = false) -> some View {
        modifier(AppTheme.GlassCardModifier(highlighted: highlighted))
    }
    
    // 统一的内容容器：限制最大宽度并提供标准左右边距
    func appContainer(alignment: Alignment = .center) -> some View {
        self
            .frame(maxWidth: AppTheme.contentMaxWidth, alignment: alignment)
            .padding(.horizontal, AppTheme.horizontalPadding)
    }
}
