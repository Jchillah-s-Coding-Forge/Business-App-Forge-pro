import AppForgeDesignSystem
import AppForgeDomain
import AppKit
import SwiftUI

struct ProjectSetupView: View {
    @Bindable var viewModel: ProjectSetupViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Form {
                projectSection
                frameworkSection
                platformSection
                backendSection
                stateManagementSection
                architectureSection
                buildEnvironmentSection
                summarySection
            }
            .formStyle(.grouped)

            Divider()
            footer
        }
        .frame(width: 760, height: 820)
        .onAppear {
            viewModel.refreshToolchainPreferences()
        }
    }

}

private extension ProjectSetupView {
    private var projectSection: some View {
        Section("Projekt") {
            TextField(
                "App-Name",
                text: $viewModel.projectName
            )
            Text(
                "Der Name kann vor der Veröffentlichung später geändert werden."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            TextField(
                "Organisationskennung",
                text: $viewModel.organizationIdentifier,
                prompt: Text("de.meinefirma")
            )
            Text(
                "Wird als Basis für eindeutige Bundle- und Paketkennungen verwendet."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var frameworkSection: some View {
        Section("Framework") {
            Picker(
                "Framework",
                selection: $viewModel.framework
            ) {
                ForEach(
                    viewModel.availableFrameworks
                ) { framework in
                    Text(framework.rawValue)
                        .tag(framework)
                }
            }
            .pickerStyle(.segmented)

            Label(
                "SwiftUI und Jetpack Compose folgen, "
                    + "sobald ihre Renderer produktionsbereit sind.",
                systemImage: "clock"
            )
            .foregroundStyle(.secondary)
        }
    }

    private var platformSection: some View {
        Section("Zielplattformen") {
            ForEach(viewModel.availablePlatforms) { platform in
                Toggle(
                    platform.rawValue,
                    isOn: Binding(
                        get: {
                            viewModel.targetPlatforms
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
            }
        }
    }

    private var backendSection: some View {
        Section("Datenbank") {
            Picker(
                "Speicherung",
                selection: $viewModel.backend
            ) {
                ForEach(BackendProvider.allCases) { backend in
                    Text(backend.rawValue)
                        .tag(backend)
                }
            }

            Text(viewModel.backend.guidance)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var stateManagementSection: some View {
        if viewModel.framework == .flutter {
            Section("State Management") {
                Picker(
                    "Strategie",
                    selection:
                        $viewModel.flutterStateManagement
                ) {
                    ForEach(
                        FlutterStateManagement.allCases
                    ) { strategy in
                        Text(strategy.rawValue)
                            .tag(strategy)
                    }
                }

                Text(
                    viewModel.flutterStateManagement
                        .recommendation
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var architectureSection: some View {
        Section("Fester Qualitätsvertrag") {
            LabeledContent(
                "Presentation",
                value: viewModel.architecture
                    .presentationPattern
            )
            LabeledContent(
                "Struktur",
                value: viewModel.architecture
                    .projectStructure
            )
            LabeledContent(
                "Datenzugriff",
                value: viewModel.architecture
                    .dataAccess
            )
            LabeledContent(
                "Lokale Daten",
                value: viewModel.architecture
                    .localDataPolicy
            )

            Text(
                "Diese Regeln werden nicht einzeln abgewählt. "
                    + "Sie gelten auch für Riverpod und BLoC/Cubit."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var buildEnvironmentSection: some View {
        Section("Build-Umgebung") {
            LabeledContent(
                "Modus",
                value: environmentModeTitle
            )

            Text(viewModel.toolchainSummary)
                .font(.caption)
                .foregroundStyle(
                    viewModel.canGenerateProject
                        ? .secondary
                        : .orange
                )
                .textSelection(.enabled)

            if viewModel.isGeneratingProject {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Flutter-Projekt wird validiert und erzeugt …")
                }
            }

            if let projectPath =
                viewModel.generatedProjectPath
            {
                Label(
                    "Projekt erfolgreich erzeugt",
                    systemImage: "checkmark.seal.fill"
                )
                .foregroundStyle(.green)

                Text(projectPath)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)

                Button(
                    "In \(viewModel.preferredIDE.rawValue) öffnen"
                ) {
                    viewModel.openGeneratedProject()
                }
            }
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        if let summaryMessage = viewModel.summaryMessage {
            Section {
                Label(
                    summaryMessage,
                    systemImage: "info.circle.fill"
                )
                .foregroundStyle(.secondary)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.extraSmall
            ) {
                Text("Neues Business-Projekt")
                    .font(.title2.bold())
                Text(
                    "Fachliche Entscheidungen zuerst – "
                        + "Architektur automatisch."
                )
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(
                "Schließen",
                action: onClose
            )
            .keyboardShortcut(.cancelAction)
            .disabled(viewModel.isGeneratingProject)
        }
        .padding(AppForgeSpacing.large)
    }

    private var footer: some View {
        HStack {
            Text("Projektbasis · produktiver Flutter-Build")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(
                "Projektentwurf prüfen",
                action: viewModel.prepareProject
            )
            .buttonStyle(.bordered)
            .disabled(
                !viewModel.canPrepareProject
                    || viewModel.isGeneratingProject
            )

            Button {
                chooseGenerationTarget()
            } label: {
                Label(
                    "Flutter-App generieren …",
                    systemImage: "hammer.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.appForgeAccent)
            .disabled(!viewModel.canGenerateProject)
        }
        .padding(AppForgeSpacing.large)
    }

    private var environmentModeTitle: String {
        switch viewModel.developmentEnvironmentMode {
        case .appForgeManaged:
            "AppForge Managed"
        case .existingToolchain:
            "Existing Toolchain"
        case .nixReproducible:
            "Nix Reproducible"
        }
    }

    private func chooseGenerationTarget() {
        viewModel.refreshToolchainPreferences()
        guard viewModel.canGenerateProject else {
            viewModel.prepareProject()
            return
        }

        let panel = NSSavePanel()
        panel.title = "Ziel für das Flutter-Projekt"
        panel.prompt = "Generieren"
        panel.nameFieldStringValue =
            suggestedProjectDirectoryName
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }

        Task {
            await viewModel.generateProject(
                at: url
            )
        }
    }

    private var suggestedProjectDirectoryName: String {
        let trimmed = viewModel.projectName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        return trimmed.isEmpty
            ? "appforge-project"
            : trimmed
    }
}
