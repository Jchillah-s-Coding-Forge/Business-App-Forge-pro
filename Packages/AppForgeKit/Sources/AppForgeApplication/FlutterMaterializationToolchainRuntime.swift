import AppForgeDomain
import Foundation

enum FlutterToolchainExecutable: String, Sendable {
    case flutter
    case dart
}

protocol FlutterCommandRequestBuilding: Sendable {
    func request(
        executable: FlutterToolchainExecutable,
        arguments: [String],
        workingDirectory: URL,
        timeoutSeconds: TimeInterval
    ) -> ToolchainCommandRequest
}

struct FlutterMaterializationToolchainRuntime: Sendable {
    let identity: FlutterToolchainIdentity
    let executionMode: FlutterToolchainExecutionMode
    let nixProvenance: FlutterNixEnvironmentProvenance?
    let commandBuilder: any FlutterCommandRequestBuilding
}

struct DirectFlutterCommandRequestBuilder: FlutterCommandRequestBuilding {
    private let inspection: FlutterToolchainInspection
    private let environment: [String: String]

    init(
        inspection: FlutterToolchainInspection
    ) {
        self.inspection = inspection
        environment = FlutterToolchainProcessEnvironment.make(
            sdkRootPath: inspection.sdkRootPath
        )
    }

    func request(
        executable: FlutterToolchainExecutable,
        arguments: [String],
        workingDirectory: URL,
        timeoutSeconds: TimeInterval
    ) -> ToolchainCommandRequest {
        let executablePath = switch executable {
        case .flutter:
            inspection.flutterExecutablePath
        case .dart:
            inspection.dartExecutablePath
        }

        return ToolchainCommandRequest(
            executablePath: executablePath,
            arguments: arguments,
            workingDirectoryPath: workingDirectory.path,
            environment: environment,
            timeoutSeconds: timeoutSeconds
        )
    }
}

struct NixFlutterCommandRequestBuilder: FlutterCommandRequestBuilding {
    private let inspection: NixFlutterToolchainInspection
    private let environment: [String: String]

    init(
        inspection: NixFlutterToolchainInspection
    ) {
        self.inspection = inspection
        environment = NixProcessEnvironment.make()
    }

    func request(
        executable: FlutterToolchainExecutable,
        arguments: [String],
        workingDirectory: URL,
        timeoutSeconds: TimeInterval
    ) -> ToolchainCommandRequest {
        ToolchainCommandRequest(
            executablePath: inspection.nixExecutablePath,
            arguments: nixDevelopArguments(
                environmentPath: inspection.environmentPath,
                executable: executable,
                arguments: arguments
            ),
            workingDirectoryPath: workingDirectory.path,
            environment: environment,
            timeoutSeconds: timeoutSeconds
        )
    }
}
