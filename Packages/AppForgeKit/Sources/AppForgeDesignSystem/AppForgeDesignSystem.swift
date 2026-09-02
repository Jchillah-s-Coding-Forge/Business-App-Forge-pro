import SwiftUI

public enum AppForgeSpacing {
    public static let extraSmall: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let extraLarge: CGFloat = 32
}

public enum AppForgeRadius {
    public static let card: CGFloat = 16
    public static let control: CGFloat = 10
}

public extension Color {
    static let appForgeAccent = Color(red: 0.18, green: 0.58, blue: 0.24)
    static let appForgeSurface = Color(nsColor: .controlBackgroundColor)
}

public struct AppForgeCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(AppForgeSpacing.large)
            .background(Color.appForgeSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppForgeRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppForgeRadius.card, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}
