import AppForgeDesignSystem
import AppForgeDomain
import AppKit
import SwiftUI

struct EnvironmentDoctorView: View {
    @Bindable var viewModel: EnvironmentDoctorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppForgeSpacing.large) {
                header
                platformSelection
                flutterConfiguration
                ideConfiguration
                reportSection
            }
            .padding(AppForgeSpacing.extraLarge)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            if viewModel.report == nil {
                await viewModel.scan()
            }
        }
        .alert(
            "Flutter SDK installieren?",
            isPresented: $viewModel.isPresentingFlutterInstallConfirmation
        ) {
            Button("Abbrechen", role: .cancel) {}
            Button("Installieren") {
                Task { await viewModel.installFlutter() }
            }
        } message: {
            Text(
                "AppForge lädt das offizielle stabile Flutter-SDK, prüft dessen SHA-256 und installiert es "
                    + "unter \(viewModel.flutterInstallParentPath)/flutter. "
                    + "Ein vorhandener flutter-Ordner wird niemals überschrieben."
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppForgeSpacing.small) {
                Text("Entwicklungsumgebung")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(
                    "AppForge prüft nur Werkzeuge, die für Ihre gewählten Zielplattformen benötigt werden. "
                        + "Installationen erfolgen niemals still im Hintergrund."
                )
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await viewModel.scan() }
            } label: {
                Label(viewModel.isScanning ? "Prüfe …" : "Jetzt prüfen", systemImage: "stethoscope")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canScan || viewModel.isInstallingFlutter)
        }
    }

    private var platformSelection: some View {
        AppForgeCard {
            VStack(alignment: .leading, spacing: AppForgeSpacing.medium) {
                Text("Zielplattformen für die Prüfung")
                    .font(.headline)

                HStack {
                    ForEach(viewModel.availablePlatforms) { platform in
                        Toggle(
                            platform.rawValue,
                            isOn: Binding(
                                get: { viewModel.selectedPlatforms.contains(platform) },
                                set: { viewModel.setTarget(platform, enabled: $0) }
                            )
                        )
                        .toggleStyle(.checkbox)
                    }
                }

                Text("iOS benötigt Xcode. Android benötigt Android SDK und ein JDK.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var flutterConfiguration: some View {
        AppForgeCard {
            VStack(alignment: .leading, spacing: AppForgeSpacing.medium) {
                Text("Flutter SDK")
                    .font(.headline)

                LabeledContent("Aktueller Pfad") {
                    Text(viewModel.flutterSDKPath.isEmpty ? "Automatisch aus PATH erkennen" : viewModel.flutterSDKPath)
                        .textSelection(.enabled)
                }

                HStack {
                    Button("Vorhandenes Flutter auswählen") {
                        chooseFlutterSDK()
                    }
                    .disabled(viewModel.isInstallingFlutter)

                    Button("Flutter installieren …") {
                        chooseFlutterInstallLocation()
                    }
                    .disabled(viewModel.isInstallingFlutter)

                    if !viewModel.flutterSDKPath.isEmpty {
                        Button("Auswahl löschen") {
                            viewModel.clearFlutterSDKPath()
                        }
                        .disabled(viewModel.isInstallingFlutter)
                    }
                }

                Text(
                    "Vorhandenes SDK: Wählen Sie den Flutter-Ordner mit bin/flutter. Neue Installation: "
                        + "Wählen Sie den übergeordneten Zielordner; AppForge erstellt darin flutter."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if viewModel.isInstallingFlutter, let phase = viewModel.installationPhase {
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

                if !viewModel.installationWarnings.isEmpty {
                    Divider()
                    ForEach(viewModel.installationWarnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private var ideConfiguration: some View {
        AppForgeCard {
            VStack(alignment: .leading, spacing: AppForgeSpacing.medium) {
                Text("Bevorzugte IDE")
                    .font(.headline)

                Picker("Projekt nach Generierung öffnen mit", selection: $viewModel.preferredIDE) {
                    ForEach(PreferredIDE.allCases) { ide in
                        Text(ide.rawValue).tag(ide)
                    }
                }
                .frame(maxWidth: 360)

                Text(
                    "Die IDE ist nur ein Handoff. Das generierte Projekt bleibt unabhängig von VS Code, "
                        + "Android Studio oder Xcode."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var reportSection: some View {
        if let report = viewModel.report {
            AppForgeCard {
                VStack(alignment: .leading, spacing: AppForgeSpacing.medium) {
                    HStack {
                        Label(
                            report.isReady ? "Umgebung bereit" : "Einrichtung erforderlich",
                            systemImage: report.isReady ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(.headline)

                        Spacer()

                        Text(report.generatedAt, format: .dateTime.hour().minute().second())
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            saveToolchainReport()
                        } label: {
                            Label("Report sichern", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()

                    ForEach(report.results) { result in
                        toolRow(result)
                        if result.id != report.results.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }

        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        }
    }

    private func toolRow(_ result: ToolDetectionResult) -> some View {
        HStack(alignment: .top, spacing: AppForgeSpacing.medium) {
            Image(systemName: statusIcon(result.availability))
                .foregroundStyle(statusColor(result.availability))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.requirement.displayName)
                        .font(.headline)
                    if !result.requirement.isRequired {
                        Text("Optional")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(result.requirement.purpose)
                    .foregroundStyle(.secondary)

                if let path = result.path {
                    Text(path)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                Text(result.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppForgeSpacing.small) {
                if let version = result.version {
                    Text(version.description)
                        .font(.caption.monospaced())
                }

                if let recommendation = viewModel.setupRecommendation(for: result) {
                    Button(recommendation.title) {
                        viewModel.openSetup(for: result)
                    }
                    .buttonStyle(.bordered)
                    .help(recommendation.detail)
                }
            }
        }
    }

    private func chooseFlutterSDK() {
        let panel = NSOpenPanel()
        panel.title = "Flutter SDK auswählen"
        panel.prompt = "SDK verwenden"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
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

        guard panel.runModal() == .OK, let url = panel.url else { return }
        viewModel.requestFlutterInstallation(into: url.path)
    }

    private func saveToolchainReport() {
        let panel = NSSavePanel()
        panel.title = "Toolchain-Report speichern"
        panel.prompt = "Speichern"
        panel.nameFieldStringValue = "appforge-toolchain-report.json"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        viewModel.exportReport(to: url)
    }

    private func installationPhaseTitle(_ phase: FlutterInstallationPhase) -> String {
        switch phase {
        case .resolvingRelease: "Stabile Flutter-Version wird ermittelt …"
        case .downloading: "Flutter SDK wird heruntergeladen …"
        case .verifying: "SHA-256 wird geprüft …"
        case .extracting: "Flutter SDK wird vorbereitet …"
        case .validating: "Installation wird validiert …"
        case .completed: "Flutter SDK ist installiert"
        }
    }

    private func statusIcon(_ availability: ToolAvailability) -> String {
        switch availability {
        case .ready: "checkmark.circle.fill"
        case .missing: "xmark.circle.fill"
        case .incompatible: "exclamationmark.triangle.fill"
        }
    }

    private func statusColor(_ availability: ToolAvailability) -> Color {
        switch availability {
        case .ready: .green
        case .missing: .red
        case .incompatible: .orange
        }
    }
}
