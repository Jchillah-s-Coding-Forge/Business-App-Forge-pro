import AppForgeDomain
import Foundation

public enum ProjectGenerationToolchainError: Error, Equatable, Sendable {
    case missingFlutterSDK(DevelopmentEnvironmentMode)
    case missingNixEnvironment
    case missingNixExecutable
    case invalidNixEnvironmentPath
    case invalidNixExecutablePath
}

extension ProjectGenerationToolchainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingFlutterSDK:
            "Kein explizites Flutter-SDK ist konfiguriert. Öffnen Sie den Environment Doctor."
        case .missingNixEnvironment:
            "Es ist noch kein verifiziertes Nix-Environment gespeichert. Öffnen Sie den Environment Doctor."
        case .missingNixExecutable:
            "Die Nix-CLI wurde noch nicht erfolgreich erkannt. Öffnen Sie den Environment Doctor."
        case .invalidNixEnvironmentPath:
            "Der gespeicherte Nix-Environment-Pfad ist nicht absolut."
        case .invalidNixExecutablePath:
            "Der gespeicherte Nix-Executable-Pfad ist nicht absolut."
        }
    }
}

public struct ResolveProjectGenerationToolchainUseCase: Sendable {
    public init() {}

    public func callAsFunction(
        preferences: ToolchainPreferences
    ) throws -> FlutterMaterializationToolchain {
        let mode = preferences.developmentEnvironmentMode
            ?? .appForgeManaged

        switch mode {
        case .appForgeManaged, .existingToolchain:
            return try directToolchain(
                mode: mode,
                flutterSDKPath: preferences.flutterSDKPath
            )
        case .nixReproducible:
            return try nixToolchain(
                environmentPath: preferences.nixEnvironmentPath,
                executablePath: preferences.nixExecutablePath
            )
        }
    }

    private func directToolchain(
        mode: DevelopmentEnvironmentMode,
        flutterSDKPath: String?
    ) throws -> FlutterMaterializationToolchain {
        let path = flutterSDKPath?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        guard !path.isEmpty else {
            throw ProjectGenerationToolchainError
                .missingFlutterSDK(mode)
        }

        return .directSDK(path: path)
    }

    private func nixToolchain(
        environmentPath: String?,
        executablePath: String?
    ) throws -> FlutterMaterializationToolchain {
        let environment = normalized(environmentPath)
        let executable = normalized(executablePath)

        guard !environment.isEmpty else {
            throw ProjectGenerationToolchainError
                .missingNixEnvironment
        }
        guard !executable.isEmpty else {
            throw ProjectGenerationToolchainError
                .missingNixExecutable
        }
        guard environment.hasPrefix("/") else {
            throw ProjectGenerationToolchainError
                .invalidNixEnvironmentPath
        }
        guard executable.hasPrefix("/") else {
            throw ProjectGenerationToolchainError
                .invalidNixExecutablePath
        }

        return .nixEnvironment(
            environmentPath: environment,
            nixExecutablePath: executable
        )
    }

    private func normalized(
        _ value: String?
    ) -> String {
        value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
    }
}
