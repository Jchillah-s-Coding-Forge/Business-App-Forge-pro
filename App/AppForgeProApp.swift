import SwiftUI

@main
struct AppForgeProApp: App {
    @State private var viewModel = WorkspaceHomeViewModel()

    var body: some Scene {
        WindowGroup {
            WorkspaceHomeView(viewModel: viewModel)
                .frame(minWidth: 1080, minHeight: 720)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 820)
    }
}
