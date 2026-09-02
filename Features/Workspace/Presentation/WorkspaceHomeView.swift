import AppForgeDesignSystem
import AppForgeDomain
import AppKit
import SwiftUI

struct WorkspaceHomeView: View {
    @Bindable var viewModel: WorkspaceHomeViewModel
    @State private var selectedSection: WorkspaceSection? = .projects

    var body: some View {
        NavigationSplitView {
            List(WorkspaceSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("AppForge Pro")
            .frame(minWidth: 210)
        } detail: {
            if selectedSection == .environment {
                EnvironmentDoctorView(viewModel: viewModel.environmentDoctorViewModel)
            } else {
                dashboard
            }
        }
        .sheet(isPresented: $viewModel.isPresentingProjectSetup) {
            if let projectSetupViewModel = viewModel.projectSetupViewModel {
                ProjectSetupView(
                    viewModel: projectSetupViewModel,
                    onClose: viewModel.dismissProjectSetup
                )
            }
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppForgeSpacing.large) {
                hero
                valueOverview
                architectureNote
            }
            .padding(AppForgeSpacing.extraLarge)
            .frame(maxWidth: 1080, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var hero: some View {
        AppForgeCard {
            HStack(alignment: .center, spacing: AppForgeSpacing.extraLarge) {
                VStack(alignment: .leading, spacing: AppForgeSpacing.medium) {
                    Text("Von Ihrer Geschäftsidee zur eigenen App")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text(
                        "Wählen Sie Prozesse, Rollen, Daten, Plattformen und Design. "
                            + "AppForge Pro übersetzt diese Entscheidungen in getesteten Source Code."
                    )
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    Button(action: viewModel.startProjectSetup) {
                        Label("Neues Business-Projekt", systemImage: "wand.and.stars")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appForgeAccent)
                    .controlSize(.large)
                    .accessibilityHint("Öffnet die geführte Projektkonfiguration")
                }

                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 104))
                    .foregroundStyle(Color.appForgeAccent.gradient)
                    .accessibilityHidden(true)
            }
        }
    }

    private var valueOverview: some View {
        HStack(alignment: .top, spacing: AppForgeSpacing.medium) {
            valueCard(
                icon: "person.3.sequence.fill",
                title: "Rollen vorab testen",
                detail: "Demo-Zugänge zeigen, was Owner, Manager und Mitarbeiter wirklich dürfen."
            )
            valueCard(
                icon: "externaldrive.badge.icloud",
                title: "Offline produktiv",
                detail: "Lokale SSOT und Sync-Outbox halten die App auch ohne Internet arbeitsfähig."
            )
            valueCard(
                icon: "shippingbox.and.arrow.backward.fill",
                title: "Source Code besitzen",
                detail: "Keine proprietäre Runtime: Das erzeugte Projekt bleibt vollständig editierbar."
            )
        }
    }

    private var architectureNote: some View {
        AppForgeCard {
            Label {
                VStack(alignment: .leading, spacing: AppForgeSpacing.small) {
                    Text("Professionelle Architektur ist bereits eingebaut")
                        .font(.headline)
                    Text(
                        "MVVM, Feature-First, Repository Pattern, Use Cases, Clean Code, KISS, DRY, "
                            + "SOLID und Single Source of Truth sind Standards – keine verwirrenden Optionen."
                    )
                    .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color.appForgeAccent)
            }
        }
    }

    private func valueCard(icon: String, title: String, detail: String) -> some View {
        AppForgeCard {
            VStack(alignment: .leading, spacing: AppForgeSpacing.small) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(Color.appForgeAccent)
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EnvironmentDoctorView: View {
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
            .disabled(!viewModel.canScan)
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

                    if !viewModel.flutterSDKPath.isEmpty {
                        Button("Auswahl löschen") {
                            viewModel.clearFlutterSDKPath()
                            Task { await viewModel.scan() }
                        }
                    }
                }

                Text(
                    "Der ausgewählte Ordner muss ein Flutter SDK enthalten. AppForge erwartet darin bin/flutter."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
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

            if let version = result.version {
                Text(version.description)
                    .font(.caption.monospaced())
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
        Task { await viewModel.scan() }
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

private enum WorkspaceSection: String, CaseIterable, Identifiable {
    case projects
    case templates
    case packages
    case environment
    case quality
    case releases

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .projects: "Projekte"
        case .templates: "Business-Vorlagen"
        case .packages: "Packages"
        case .environment: "Entwicklungsumgebung"
        case .quality: "Qualität"
        case .releases: "Releases"
        }
    }

    var icon: String {
        switch self {
        case .projects: "square.grid.2x2"
        case .templates: "rectangle.3.group"
        case .packages: "shippingbox"
        case .environment: "wrench.and.screwdriver"
        case .quality: "checkmark.seal"
        case .releases: "arrow.up.forward.app"
        }
    }
}
