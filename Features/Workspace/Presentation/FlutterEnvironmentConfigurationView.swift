import AppForgeDesignSystem
import AppForgeDomain
import AppKit
import SwiftUI

struct FlutterEnvironmentConfigurationView: View {
    @Bindable var viewModel: EnvironmentDoctorViewModel

    var body: some View {
        AppForgeCard {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.medium
            ) {
                Text("Flutter SDK")
                    .font(.headline)

                LabeledContent("Aktueller Pfad") {
                    Text(
                        viewModel.flutterSDKPath.isEmpty
                            ? "Automatisch aus PATH erkennen"
                            : viewModel.flutterSDKPath
                    )
                    .textSelection(.enabled)
                }

                controls
                Text(configurationDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                installationProgress
                installationWarnings
            }
        }
    }

    private var controls: some View {
        HStack {
            Button("Vorhandenes Flutter auswählen") {
                chooseFlutterSDK()
            }
            .disabled(viewModel.isInstallingFlutter)

            if viewModel.developmentEnvironmentMode == .appForgeManaged {
                Button("Flutter installieren …") {
                    chooseFlutterInstallLocation()
                }
                .disabled(viewModel.isInstallingFlutter)
            }

            if !viewModel.flutterSDKPath.isEmpty {
                Button("Auswahl löschen") {
                    viewModel.clearFlutterSDKPath()
                }
                .disabled(viewModel.isInstallingFlutter)
            }
        }
    }

    @ViewBuilder
    private var installationProgress: some View {
        if viewModel.isInstallingFlutter,
           let phase = viewModel.installationPhase
        {
            Divider()
            HStack(spacing: AppForgeSpacing.medium) {
                ProgressView()
                    .controlSize(.small)
                VStack(alignment: .leading, spacing: 2) {
                    Text(installationPhaseTitle(phase))
                        .font(.headline)
                    Text(viewModel.flutterInstallParentPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    private var installationWarnings: some View {
        if !viewModel.installationWarnings.isEmpty {
            Divider()
            ForEach(
                viewModel.installationWarnings,
                id: \.self
            ) { warning in
                Label(
                    warning,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
    }

    private var configurationDetail: String {
        if viewModel.developmentEnvironmentMode == .existingToolchain {
            return "Wählen Sie ein bereits installiertes Flutter-SDK mit bin/flutter. "
                + "AppForge installiert in diesem Modus keine SDKs."
        }

        return "Vorhandenes SDK: Wählen Sie den Flutter-Ordner mit bin/flutter. "
            + "Neue Installation: Wählen Sie den übergeordneten Zielordner; "
            + "AppForge erstellt darin flutter."
    }

    private func chooseFlutterSDK() {
        let panel = NSOpenPanel()
        panel.title = "Flutter SDK auswählen"
        panel.prompt = "SDK verwenden"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }
        viewModel.setFlutterSDKPath(url.path)
    }

    private func chooseFlutterInstallLocation() {
        let panel = NSOpenPanel()
        panel.title = "Installationsordner für Flutter wählen"
        panel.prompt = "Ordner wählen"
        panel.message = "AppForge erstellt in diesem Ordner ein neues Unterverzeichnis namens flutter."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }
        viewModel.requestFlutterInstallation(
            into: url.path
        )
    }

    private func installationPhaseTitle(
        _ phase: FlutterInstallationPhase
    ) -> String {
        switch phase {
        case .resolvingRelease:
            "Stabile Flutter-Version wird ermittelt …"
        case .downloading:
            "Flutter SDK wird heruntergeladen …"
        case .verifying:
            "SHA-256 wird geprüft …"
        case .extracting:
            "Flutter SDK wird vorbereitet …"
        case .validating:
            "Installation wird validiert …"
        case .completed:
            "Flutter SDK ist installiert"
        }
    }
}
