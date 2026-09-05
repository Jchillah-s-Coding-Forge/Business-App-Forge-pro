import AppForgeDesignSystem
import AppForgeDomain
import AppKit
import SwiftUI

struct EnvironmentToolchainReportView: View {
    @Bindable var viewModel: EnvironmentDoctorViewModel

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: AppForgeSpacing.medium
        ) {
            if let report = viewModel.report {
                reportCard(report)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    private func reportCard(
        _ report: ToolchainReport
    ) -> some View {
        AppForgeCard {
            VStack(
                alignment: .leading,
                spacing: AppForgeSpacing.medium
            ) {
                reportHeader(report)

                if viewModel.developmentEnvironmentMode == .nixReproducible {
                    Text(
                        "Dieser Report beschreibt weiterhin die lokal installierte Toolchain. "
                            + "Der reproduzierbare Nix-Status und das provisionierte Environment "
                            + "werden separat oben angezeigt."
                    )
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

    private func reportHeader(
        _ report: ToolchainReport
    ) -> some View {
        HStack {
            Label(
                headerTitle(report),
                systemImage: report.isReady
                    ? "checkmark.seal.fill"
                    : "exclamationmark.triangle.fill"
            )
            .font(.headline)

            Spacer()

            Text(
                report.generatedAt,
                format: .dateTime.hour().minute().second()
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                saveToolchainReport()
            } label: {
                Label(
                    "Report sichern",
                    systemImage: "square.and.arrow.down"
                )
            }
            .buttonStyle(.bordered)
        }
    }

    private func toolRow(
        _ result: ToolDetectionResult
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: AppForgeSpacing.medium
        ) {
            Image(
                systemName: statusIcon(
                    result.availability
                )
            )
            .foregroundStyle(
                statusColor(result.availability)
            )
            .frame(width: 22)

            toolDetail(result)

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: AppForgeSpacing.small
            ) {
                if let version = result.version {
                    Text(version.description)
                        .font(.caption.monospaced())
                }

                if let recommendation = viewModel.setupRecommendation(
                    for: result
                ) {
                    Button(recommendation.title) {
                        viewModel.openSetup(for: result)
                    }
                    .buttonStyle(.bordered)
                    .help(recommendation.detail)
                }
            }
        }
    }

    private func toolDetail(
        _ result: ToolDetectionResult
    ) -> some View {
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
    }

    private func headerTitle(
        _ report: ToolchainReport
    ) -> String {
        if viewModel.developmentEnvironmentMode == .nixReproducible {
            return report.isReady
                ? "Lokale Toolchain bereit"
                : "Lokale Toolchain unvollständig"
        }

        return report.isReady
            ? "Umgebung bereit"
            : "Einrichtung erforderlich"
    }

    private func saveToolchainReport() {
        let panel = NSSavePanel()
        panel.title = "Toolchain-Report speichern"
        panel.prompt = "Speichern"
        panel.nameFieldStringValue =
            "appforge-toolchain-report.json"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }
        viewModel.exportReport(to: url)
    }

    private func statusIcon(
        _ availability: ToolAvailability
    ) -> String {
        switch availability {
        case .ready:
            "checkmark.circle.fill"
        case .missing:
            "xmark.circle.fill"
        case .incompatible:
            "exclamationmark.triangle.fill"
        }
    }

    private func statusColor(
        _ availability: ToolAvailability
    ) -> Color {
        switch availability {
        case .ready:
            .green
        case .missing:
            .red
        case .incompatible:
            .orange
        }
    }
}
