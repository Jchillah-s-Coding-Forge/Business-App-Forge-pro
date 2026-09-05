import AppForgeCore
import AppForgeDomain
import Foundation

public protocol ToolchainReportExporting {
    func export(_ report: ToolchainReport, to url: URL) throws
}

public struct JSONToolchainReportExporter: ToolchainReportExporting {
    public init() {}

    public func export(_ report: ToolchainReport, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(report)
            try data.write(to: url, options: .atomic)
        } catch {
            throw AppForgeError.fileSystem(
                message: "Der Toolchain-Report konnte nicht gespeichert werden: \(error.localizedDescription)"
            )
        }
    }
}

public struct ToolchainReadinessGate: Sendable {
    public init() {}

    public func validate(_ report: ToolchainReport) throws {
        guard !report.requiredFailures.isEmpty else { return }

        let failures = report.requiredFailures
            .map { result in
                "\(result.requirement.displayName): \(result.detail)"
            }
            .joined(separator: " | ")

        throw AppForgeError.configuration(
            message: "Die Generierung ist blockiert, bis alle benötigten Werkzeuge bereit sind. \(failures)"
        )
    }
}

public struct ToolSetupRecommendation: Equatable, Sendable {
    public let title: String
    public let detail: String
    public let urlString: String

    public init(title: String, detail: String, urlString: String) {
        self.title = title
        self.detail = detail
        self.urlString = urlString
    }
}

public struct ToolSetupAdvisor: Sendable {
    public init() {}

    public func recommendation(for identifier: ToolIdentifier) -> ToolSetupRecommendation? {
        switch identifier {
        case .flutter:
            ToolSetupRecommendation(
                title: "Mit VS Code einrichten",
                detail: "Öffnet die offizielle Flutter-Anleitung für den VS-Code-Setupflow.",
                urlString: "https://docs.flutter.dev/install/with-vs-code"
            )
        case .xcode:
            ToolSetupRecommendation(
                title: "Xcode öffnen",
                detail: "Öffnet Apples offiziellen App-Store-Eintrag. AppForge installiert Xcode nicht still.",
                urlString: "https://apps.apple.com/app/xcode/id497799835"
            )
        case .androidSDK, .java, .androidStudio:
            ToolSetupRecommendation(
                title: "Android Studio einrichten",
                detail: "Öffnet die offizielle Android-Studio-Seite für SDK, Build Tools und JDK.",
                urlString: "https://developer.android.com/studio"
            )
        case .vsCode:
            ToolSetupRecommendation(
                title: "VS Code einrichten",
                detail: "Öffnet die offizielle VS-Code-Installationsanleitung für macOS.",
                urlString: "https://code.visualstudio.com/docs/setup/mac"
            )
        case .xcodeGen, .supabaseCLI, .docker, .nix:
            optionalRecommendation(for: identifier)
        case .git:
            nil
        }
    }

    private func optionalRecommendation(
        for identifier: ToolIdentifier
    ) -> ToolSetupRecommendation? {
        switch identifier {
        case .xcodeGen:
            ToolSetupRecommendation(
                title: "XcodeGen-Anleitung",
                detail: "Öffnet das offizielle XcodeGen-Repository mit den unterstützten Installationswegen.",
                urlString: "https://github.com/yonaskolb/XcodeGen"
            )
        case .supabaseCLI:
            ToolSetupRecommendation(
                title: "Supabase CLI einrichten",
                detail: "Öffnet die offizielle Supabase-Anleitung für lokale Entwicklung und CLI-Setup.",
                urlString: "https://supabase.com/docs/guides/local-development/cli/getting-started"
            )
        case .docker:
            ToolSetupRecommendation(
                title: "Docker einrichten",
                detail: "Öffnet die offizielle Docker-Desktop-Anleitung für macOS.",
                urlString: "https://docs.docker.com/desktop/setup/install/mac-install/"
            )
        case .nix:
            ToolSetupRecommendation(
                title: "Nix einrichten",
                detail: "Öffnet die offizielle Nix-Installationsanleitung. AppForge installiert Nix nicht still.",
                urlString: "https://nixos.org/download/"
            )
        default:
            nil
        }
    }
}

public protocol ExternalURLLaunching {
    func open(urlString: String) throws
}

public struct SystemExternalURLLauncher: ExternalURLLaunching {
    public init() {}

    public func open(urlString: String) throws {
        guard let url = URL(string: urlString), url.scheme == "https" else {
            throw AppForgeError.configuration(message: "Die Setup-Adresse ist ungültig.")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url.absoluteString]

        do {
            try process.run()
        } catch {
            throw AppForgeError.configuration(
                message: "Die Setup-Seite konnte nicht geöffnet werden: \(error.localizedDescription)"
            )
        }
    }
}
