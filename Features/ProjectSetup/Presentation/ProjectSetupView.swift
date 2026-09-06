import AppForgeDesignSystem
import AppForgeDomain
import SwiftUI

struct ProjectSetupView: View {
    @Bindable var viewModel: ProjectSetupViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Form {
                Section("Projekt") {
                    TextField("App-Name", text: $viewModel.projectName)
                    Text("Der Name kann vor der Veröffentlichung später geändert werden.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField(
                        "Organisationskennung",
                        text: $viewModel.organizationIdentifier,
                        prompt: Text("de.meinefirma")
                    )
                    Text("Wird als Basis für eindeutige Bundle- und Paketkennungen verwendet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Framework") {
                    Picker("Framework", selection: $viewModel.framework) {
                        ForEach(viewModel.availableFrameworks) { framework in
                            Text(framework.rawValue).tag(framework)
                        }
                    }
                    .pickerStyle(.segmented)

                    Label(
                        "SwiftUI und Jetpack Compose folgen, sobald ihre Renderer produktionsbereit sind.",
                        systemImage: "clock"
                    )
                    .foregroundStyle(.secondary)
                }

                Section("Zielplattformen") {
                    ForEach(viewModel.availablePlatforms) { platform in
                        Toggle(
                            platform.rawValue,
                            isOn: Binding(
                                get: { viewModel.targetPlatforms.contains(platform) },
                                set: { viewModel.setTarget(platform, enabled: $0) }
                            )
                        )
                    }
                }

                Section("Datenbank") {
                    Picker("Speicherung", selection: $viewModel.backend) {
                        ForEach(BackendProvider.allCases) { backend in
                            Text(backend.rawValue).tag(backend)
                        }
                    }

                    Text(viewModel.backend.guidance)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if viewModel.framework == .flutter {
                    Section("State Management") {
                        Picker("Strategie", selection: $viewModel.flutterStateManagement) {
                            ForEach(FlutterStateManagement.allCases) { strategy in
                                Text(strategy.rawValue).tag(strategy)
                            }
                        }

                        Text(viewModel.flutterStateManagement.recommendation)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                ProjectGenerationSection(
                    viewModel: viewModel
                )

                Section("Fester Qualitätsvertrag") {
                    LabeledContent("Presentation", value: viewModel.architecture.presentationPattern)
                    LabeledContent("Struktur", value: viewModel.architecture.projectStructure)
                    LabeledContent("Datenzugriff", value: viewModel.architecture.dataAccess)
                    LabeledContent("Lokale Daten", value: viewModel.architecture.localDataPolicy)

                    Text("Diese Regeln werden nicht einzeln abgewählt. Sie gelten auch für Riverpod und BLoC/Cubit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let summaryMessage = viewModel.summaryMessage {
                    Section {
                        Label(summaryMessage, systemImage: "info.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            footer
        }
        .frame(width: 760, height: 760)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppForgeSpacing.extraSmall) {
                Text("Neues Business-Projekt")
                    .font(.title2.bold())
                Text("Fachliche Entscheidungen zuerst – Architektur automatisch.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Schließen", action: onClose)
                .keyboardShortcut(.cancelAction)
                .disabled(viewModel.isGenerating)
        }
        .padding(AppForgeSpacing.large)
    }

    private var footer: some View {
        HStack {
            Text("Projektbasis · Produktionsgenerierung")
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
                    || viewModel.isGenerating
            )
        }
        .padding(AppForgeSpacing.large)
    }
}
