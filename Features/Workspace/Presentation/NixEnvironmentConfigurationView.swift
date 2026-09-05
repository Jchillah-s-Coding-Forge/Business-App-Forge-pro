import AppForgeDesignSystem
import AppForgeDomain
import AppKit
import SwiftUI

struct NixEnvironmentConfigurationView: View {
    @Bindable var viewModel: EnvironmentDoctorViewModel

    var body: some View {
        AppForgeCard {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.medium
            ) {
                header
                Divider()

                if viewModel.isNixReady {
                    readyContent
                } else {
                    bootstrapContent
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Nix reproduzierbare Entwicklungsumgebung"
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nix Reproducible")
                    .font(.headline)
                Text(
                    "AppForge verwendet eine gepinnte Entwicklungsumgebung, "
                        + "ohne globale Nix-Konfigurationen zu verändern."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Label(
                viewModel.isNixReady
                    ? "Nix bereit"
                    : "Nix fehlt",
                systemImage: viewModel.isNixReady
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill"
            )
            .foregroundStyle(
                viewModel.isNixReady ? .green : .orange
            )
            .accessibilityLabel(
                viewModel.isNixReady
                    ? "Nix ist installiert und bereit"
                    : "Nix ist nicht installiert"
            )
        }
    }

    private var readyContent: some View {
        VStack(
            alignment: .leading,
            spacing: AppForgeSpacing.medium
        ) {
            if let result = viewModel.nixResult {
                if let version = result.version {
                    LabeledContent("Nix-Version") {
                        Text(version.description)
                            .font(.caption.monospaced())
                    }
                }

                if let path = result.path {
                    LabeledContent("Nix-Pfad") {
                        Text(path)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }

            Text(
                "Die Nix-CLI ist bereit. AppForge kann jetzt für die gewählten "
                    + "Zielplattformen ein reproduzierbares flake.nix/flake.lock-Environment erzeugen."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                chooseNixEnvironmentTarget()
            } label: {
                Label(
                    viewModel.isProvisioningNixEnvironment
                        ? "Environment wird erzeugt …"
                        : "Nix-Environment erzeugen …",
                    systemImage: "shippingbox.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canProvisionNixEnvironment)
            .accessibilityLabel(
                "Reproduzierbares Nix-Environment erzeugen"
            )

            if viewModel.isProvisioningNixEnvironment {
                HStack(spacing: AppForgeSpacing.small) {
                    ProgressView()
                        .controlSize(.small)
                    Text(viewModel.nixProvisionTargetPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            if let result = viewModel.nixProvisioningResult {
                Divider()
                Label(
                    "Nix-Environment erfolgreich validiert",
                    systemImage: "checkmark.seal.fill"
                )
                .foregroundStyle(.green)

                LabeledContent("Environment") {
                    Text(result.environmentPath)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                LabeledContent("nixpkgs Revision") {
                    Text(result.receipt.nixpkgsLockedRevision)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                LabeledContent("flake.lock SHA-256") {
                    Text(result.receipt.flakeLockSHA256)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var bootstrapContent: some View {
        VStack(
            alignment: .leading,
            spacing: AppForgeSpacing.medium
        ) {
            Label(
                "Die Installation verändert systemweite Nix-Verzeichnisse "
                    + "und benötigt eine sichtbare sudo-Freigabe in Terminal.",
                systemImage: "lock.shield.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
            .accessibilityLabel(
                "Warnung: Die Nix Installation benötigt privilegierte Systemänderungen."
            )

            LabeledContent("Gepinnte Version") {
                Text(viewModel.nixBootstrapReleaseVersion)
                    .font(.caption.monospaced())
            }

            if viewModel.isPreparingNixBootstrap {
                HStack(spacing: AppForgeSpacing.small) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Offizieller Installer wird geprüft …")
                }
            } else if let prepared = viewModel.preparedNixBootstrap {
                preparedBootstrapContent(prepared)
            } else {
                Button {
                    Task {
                        await viewModel.prepareNixBootstrap()
                    }
                } label: {
                    Label(
                        "Installer vorbereiten",
                        systemImage: "arrow.down.doc.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canPrepareNixBootstrap)
            }
        }
    }

    private func preparedBootstrapContent(
        _ prepared: NixBootstrapPreparedInstaller
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: AppForgeSpacing.medium
        ) {
            preparedInstallerMetadata(prepared)
            bootstrapApprovalControls

            if viewModel.hasLaunchedNixBootstrap {
                postLaunchStatus
            }
        }
    }

    private func preparedInstallerMetadata(
        _ prepared: NixBootstrapPreparedInstaller
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: AppForgeSpacing.small
        ) {
            Label(
                "Installer verifiziert",
                systemImage: "checkmark.shield.fill"
            )
            .foregroundStyle(.green)

            LabeledContent("Version") {
                Text(prepared.version)
                    .font(.caption.monospaced())
            }

            LabeledContent("Installer SHA-256") {
                Text(prepared.installerSHA256)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .accessibilityLabel(
                        "Verifizierter Installer SHA-256"
                    )
            }
        }
    }

    private var bootstrapApprovalControls: some View {
        VStack(
            alignment: .leading,
            spacing: AppForgeSpacing.medium
        ) {
            Toggle(
                "Ich bestätige die Installation dieses exakt geprüften Installers.",
                isOn: $viewModel.isNixBootstrapConfirmed
            )
            .accessibilityLabel(
                "Installation des verifizierten Nix Installers bestätigen"
            )

            HStack {
                Button {
                    viewModel.launchNixBootstrap()
                } label: {
                    Label(
                        "In Terminal installieren",
                        systemImage: "terminal.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canLaunchNixBootstrap)

                Button("Vorbereitung verwerfen") {
                    viewModel.cancelNixBootstrapPreparation()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var postLaunchStatus: some View {
        VStack(
            alignment: .leading,
            spacing: AppForgeSpacing.medium
        ) {
            Divider()

            Label(
                "Terminal wurde geöffnet. Schließen Sie dort die Nix-Installation ab.",
                systemImage: "terminal"
            )
            .font(.caption)

            Button {
                Task {
                    await viewModel.scan()
                }
            } label: {
                Label(
                    "Erneut prüfen",
                    systemImage: "arrow.clockwise"
                )
            }
            .buttonStyle(.bordered)
        }
    }

    private func chooseNixEnvironmentTarget() {
        let panel = NSSavePanel()
        panel.title = "Ziel für das Nix-Environment"
        panel.prompt = "Environment erzeugen"
        panel.nameFieldStringValue = "appforge-nix-environment"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }

        Task {
            await viewModel.provisionNixEnvironment(
                to: url
            )
        }
    }
}
