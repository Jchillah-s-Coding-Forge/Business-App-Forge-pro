import AppForgeDesignSystem
import AppForgeDomain
import SwiftUI

struct EnvironmentDoctorView: View {
    @Bindable var viewModel: EnvironmentDoctorViewModel

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.large
            ) {
                header
                EnvironmentModeCard(viewModel: viewModel)
                platformSelection

                if viewModel.developmentEnvironmentMode == .nixReproducible {
                    NixEnvironmentConfigurationView(
                        viewModel: viewModel
                    )
                } else {
                    FlutterEnvironmentConfigurationView(
                        viewModel: viewModel
                    )
                }

                ideConfiguration
                EnvironmentToolchainReportView(
                    viewModel: viewModel
                )
            }
            .padding(AppForgeSpacing.extraLarge)
            .frame(
                maxWidth: 980,
                alignment: .leading
            )
        }
        .background(
            Color(nsColor: .windowBackgroundColor)
        )
        .task {
            if viewModel.report == nil {
                await viewModel.scan()
            }
        }
        .alert(
            "Flutter SDK installieren?",
            isPresented:
                $viewModel.isPresentingFlutterInstallConfirmation
        ) {
            Button("Abbrechen", role: .cancel) {}
            Button("Installieren") {
                Task {
                    await viewModel.installFlutter()
                }
            }
        } message: {
            Text(
                "AppForge lädt das offizielle stabile Flutter-SDK, "
                    + "prüft dessen SHA-256 und installiert es unter "
                    + "\(viewModel.flutterInstallParentPath)/flutter. "
                    + "Ein vorhandener flutter-Ordner wird niemals überschrieben."
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.small
            ) {
                Text("Entwicklungsumgebung")
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                Text(
                    "AppForge prüft nur Werkzeuge, die für Ihre gewählten "
                        + "Zielplattformen benötigt werden. Installationen "
                        + "erfolgen niemals still im Hintergrund."
                )
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task {
                    await viewModel.scan()
                }
            } label: {
                Label(
                    viewModel.isScanning
                        ? "Prüfe …"
                        : "Jetzt prüfen",
                    systemImage: "stethoscope"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(scanIsDisabled)
        }
    }

    private var platformSelection: some View {
        AppForgeCard {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.medium
            ) {
                Text("Zielplattformen für die Prüfung")
                    .font(.headline)

                HStack {
                    ForEach(
                        viewModel.availablePlatforms
                    ) { platform in
                        Toggle(
                            platform.rawValue,
                            isOn: Binding(
                                get: {
                                    viewModel.selectedPlatforms
                                        .contains(platform)
                                },
                                set: {
                                    viewModel.setTarget(
                                        platform,
                                        enabled: $0
                                    )
                                }
                            )
                        )
                        .toggleStyle(.checkbox)
                    }
                }

                Text(
                    "iOS benötigt Xcode. Android benötigt Android SDK und ein JDK."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var ideConfiguration: some View {
        AppForgeCard {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.medium
            ) {
                Text("Bevorzugte IDE")
                    .font(.headline)

                Picker(
                    "Projekt nach Generierung öffnen mit",
                    selection: $viewModel.preferredIDE
                ) {
                    ForEach(PreferredIDE.allCases) { ide in
                        Text(ide.rawValue)
                            .tag(ide)
                    }
                }
                .frame(maxWidth: 360)

                Text(
                    "Die IDE ist nur ein Handoff. Das generierte Projekt bleibt "
                        + "unabhängig von VS Code, Android Studio oder Xcode."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var scanIsDisabled: Bool {
        !viewModel.canScan
            || viewModel.isInstallingFlutter
            || viewModel.isPreparingNixBootstrap
            || viewModel.isProvisioningNixEnvironment
    }
}
