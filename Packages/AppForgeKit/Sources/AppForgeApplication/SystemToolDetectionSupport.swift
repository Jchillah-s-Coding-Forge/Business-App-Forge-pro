import AppForgeDomain
import Foundation

enum SystemToolDetectionSupport {
    static func executablePath(for command: String) -> String? {
        let environment = ProcessInfo.processInfo.environment
        let pathValue = environment["PATH"] ?? "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"

        for folder in pathValue.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(folder)).appendingPathComponent(command).path
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        return nil
    }

    static func run(executablePath: String, arguments: [String]) -> ToolCommandExecution {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = (String(data: data, encoding: .utf8) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return ToolCommandExecution(exitCode: process.terminationStatus, output: output)
        } catch {
            return ToolCommandExecution(exitCode: -1, output: error.localizedDescription)
        }
    }

    static func incompatibleDetail(
        requirement: ToolRequirement,
        version: SemanticVersion?
    ) -> String {
        guard let minimum = requirement.versionConstraint.minimum else {
            return "Die erkannte Version ist nicht kompatibel."
        }

        let actual = version?.description ?? "unbekannt"
        return "Version \(actual) erkannt. AppForge benötigt mindestens \(minimum)."
    }

    static func missingResult(requirement: ToolRequirement) -> ToolDetectionResult {
        ToolDetectionResult(
            requirement: requirement,
            availability: .missing,
            version: nil,
            path: nil,
            detail: missingDetail(for: requirement.id)
        )
    }

    private static func missingDetail(for identifier: ToolIdentifier) -> String {
        switch identifier {
        case .flutter:
            "Kein gültiges Flutter SDK gefunden. Wählen Sie ein vorhandenes SDK oder einen Installationsort."
        case .xcode:
            "Xcode oder die zugehörigen Command Line Tools wurden nicht vollständig eingerichtet."
        case .androidSDK:
            "Kein vollständiges Android SDK gefunden. Android Studio kann die benötigten Komponenten verwalten."
        case .java:
            "Kein ausführbares JDK gefunden. Das mit Android Studio gelieferte JDK kann verwendet werden."
        case .git:
            "Git wurde nicht gefunden."
        case .vsCode:
            "VS Code ist optional und wurde nicht gefunden."
        case .androidStudio:
            "Android Studio ist optional und wurde nicht gefunden."
        case .xcodeGen:
            "XcodeGen ist optional und wurde nicht gefunden."
        case .supabaseCLI:
            "Supabase CLI ist optional und wurde nicht gefunden."
        case .docker:
            "Keine Docker-kompatible CLI wurde gefunden. Sie wird nur für lokale Backend-Stacks benötigt."
        }
    }
}

struct ToolCandidate {
    let path: String
    let executablePath: String
    let versionArguments: [String]?
}

struct ToolCommandExecution {
    let exitCode: Int32
    let output: String
}
