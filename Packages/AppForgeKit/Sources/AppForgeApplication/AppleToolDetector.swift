import AppForgeDomain
import Foundation

struct AppleToolDetector {
    func detect(requirement: ToolRequirement) -> ToolDetectionResult {
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/xcode-select") else {
            return SystemToolDetectionSupport.missingResult(requirement: requirement)
        }

        let selection = SystemToolDetectionSupport.run(
            executablePath: "/usr/bin/xcode-select",
            arguments: ["-p"]
        )
        guard selection.exitCode == 0, !selection.output.isEmpty else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: nil,
                detail: "Xcode Command Line Tools sind nicht vollständig eingerichtet."
            )
        }

        guard selection.output.contains(".app/Contents/Developer") else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: selection.output,
                detail: "Command Line Tools sind aktiv, aber kein vollständiges Xcode ist ausgewählt."
            )
        }

        guard let xcodebuild = SystemToolDetectionSupport.executablePath(for: "xcodebuild") else {
            return SystemToolDetectionSupport.missingResult(requirement: requirement)
        }

        return validateXcode(
            requirement: requirement,
            developerPath: selection.output,
            xcodebuild: xcodebuild
        )
    }

    private func validateXcode(
        requirement: ToolRequirement,
        developerPath: String,
        xcodebuild: String
    ) -> ToolDetectionResult {
        let execution = SystemToolDetectionSupport.run(
            executablePath: xcodebuild,
            arguments: ["-version"]
        )
        guard execution.exitCode == 0 else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: developerPath,
                detail: execution.output.isEmpty ? "Xcode konnte nicht validiert werden." : execution.output
            )
        }

        let version = SemanticVersion(parsing: execution.output)
        let availability: ToolAvailability = requirement.versionConstraint.accepts(version) ? .ready : .incompatible
        let detail = availability == .ready
            ? "Bereit – Xcode und Command Line Tools sind aktiv."
            : SystemToolDetectionSupport.incompatibleDetail(requirement: requirement, version: version)

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: version,
            path: developerPath,
            detail: detail
        )
    }
}
