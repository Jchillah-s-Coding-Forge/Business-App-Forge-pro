import AppForgeDesignSystem
import SwiftUI

@main
struct AppForgeProApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: AppForgeSpacing.medium) {
                Text("AppForge Pro")
                    .font(.largeTitle.bold())
                Text("Business-Anwendungen ohne Programmierkenntnisse entwickeln.")
                    .foregroundStyle(.secondary)
            }
            .padding(AppForgeSpacing.extraLarge)
            .frame(minWidth: 900, minHeight: 600, alignment: .topLeading)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1180, height: 760)
    }
}
