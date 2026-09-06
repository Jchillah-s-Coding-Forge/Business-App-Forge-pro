import AppForgeDomain
import AppKit
import SwiftUI

struct ProjectGenerationSection: View {
    @Bindable var viewModel: ProjectSetupViewModel

    var body: some View {
        Section("Produktionsgenerierung") {
            LabeledContent(
                "Environment-Modus",
                value: environmentTitle
            )
            LabeledContent(
                "Materialisierung",
                value: viewModel.toolchainSummary
            )
            LabeledContent(
                "Bevorzugte IDE",
                value: viewModel.preferredIDE.rawValue
            )

            readinessStatus

            Button {
                chooseGenerationTarget()
            } label: {
                Label(
                    viewModel.isGenerating
                        ? "Flutter-App wird generiert …"
                        : "Flutter-App generieren …",
                    systemImage: "hammer.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canGenerateProject)
            .accessibilityLabel(
                "Produktionsreife Flutter App generieren"
            )

            generationProgress
            generatedProjectStatus

            if let error = viewModel.generationErrorMessage {
                Label(
                    error,
                    systemImage: "xmark.octagon.fill"
                )
                .foregroundStyle(.red)
                .textSelection(.enabled)
            }
        }
    }

    private var readinessStatus: some View {
        Label(
            viewModel.toolchainReadinessMessage,
            systemImage: viewModel.canGenerateProject
                ? "checkmark.seal.fill"
                : "exclamationmark.triangle.fill"
        )
        .foregroundStyle(
            viewModel.canGenerateProject
                ? .green
                : .orange
        )
        .accessibilityLabel(
            "Toolchain Readiness: "
                + viewModel.toolchainReadinessMessage
        )
    }

    @ViewBuilder
    private var generationProgress: some View {
        if viewModel.isGenerating {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text(
                    "Package-Auflösung, Rendering, Flutter create, "
                        + "pub get, analyze und test laufen."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var generatedProjectStatus: some View {
        if let path = viewModel.generatedProjectPath,
           let receipt = viewModel.generatedToolchainReceipt
        {
            Divider()

            Label(
                "Projekt vollständig erzeugt und validiert",
                systemImage: "checkmark.seal.fill"
            )
            .foregroundStyle(.green)

            LabeledContent("Projektpfad") {
                Text(path)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }

            LabeledContent("Flutter") {
                Text(receipt.flutter.flutterVersion)
                    .font(.caption.monospaced())
            }

            LabeledContent("Execution Mode") {
                Text(
                    receipt.executionMode?.rawValue
                        ?? "legacy"
                )
                .font(.caption.monospaced())
            }

            nixProvenance(receipt)

            Button {
                viewModel.openGeneratedProject()
            } label: {
                Label(
                    "In \(viewModel.preferredIDE.rawValue) öffnen",
                    systemImage: "arrow.up.forward.app"
                )
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func nixProvenance(
        _ receipt: FlutterToolchainReceipt
    ) -> some View {
        if let nix = receipt.nixEnvironment {
            LabeledContent("nixpkgs Revision") {
                Text(nix.nixpkgsLockedRevision)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
            LabeledContent("flake.lock SHA-256") {
                Text(nix.flakeLockSHA256)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
        }
    }

    private var environmentTitle: String {
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
        let panel = NSSavePanel()
        panel.title = "Ziel für die Flutter-App"
        panel.prompt = "App generieren"
        panel.nameFieldStringValue =
            suggestedProjectDirectoryName
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }

        Task {
            await viewModel.generateProject(to: url)
        }
    }

    private var suggestedProjectDirectoryName: String {
        let normalized = viewModel.projectName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: " ",
                with: "-"
            )
            .lowercased()

        return normalized.isEmpty
            ? "appforge-project"
            : normalized
    }
}
