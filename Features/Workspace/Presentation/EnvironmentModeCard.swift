import AppForgeDesignSystem
import AppForgeDomain
import SwiftUI

struct EnvironmentModeCard: View {
    @Bindable var viewModel: EnvironmentDoctorViewModel

    var body: some View {
        AppForgeCard {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.medium
            ) {
                Text("Umgebungsmodus")
                    .font(.headline)

                Picker(
                    "Entwicklungsumgebung",
                    selection: Binding(
                        get: {
                            viewModel.developmentEnvironmentMode
                        },
                        set: {
                            viewModel.setDevelopmentEnvironmentMode($0)
                        }
                    )
                ) {
                    ForEach(DevelopmentEnvironmentMode.allCases) { mode in
                        Text(title(for: mode))
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(
                    "Entwicklungsumgebung auswählen"
                )

                Text(
                    detail(
                        for: viewModel.developmentEnvironmentMode
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func title(
        for mode: DevelopmentEnvironmentMode
    ) -> String {
        switch mode {
        case .appForgeManaged:
            "AppForge Managed"
        case .existingToolchain:
            "Existing Toolchain"
        case .nixReproducible:
            "Nix Reproducible"
        }
    }

    private func detail(
        for mode: DevelopmentEnvironmentMode
    ) -> String {
        switch mode {
        case .appForgeManaged:
            "AppForge darf unterstützte SDKs vorbereitet installieren und validieren. "
                + "Systemsoftware wird weiterhin niemals still eingerichtet."
        case .existingToolchain:
            "AppForge verwendet nur kompatible Werkzeuge, die bereits auf diesem Mac vorhanden sind."
        case .nixReproducible:
            "Flutter, Git und bei Android JDK 17 werden über eine reproduzierbare Nix-Umgebung gepinnt. "
                + "Xcode und das Android SDK bleiben systemverwaltet."
        }
    }
}
