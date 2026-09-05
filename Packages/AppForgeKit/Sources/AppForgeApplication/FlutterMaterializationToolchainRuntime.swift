import AppForgeDomain
import Foundation

protocol FlutterCommandRequestBuilding: Sendable {
    func request(
        flutterArguments: [String],
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
        flutterArguments: [String],
        workingDirectory: URL,
        timeoutSeconds: TimeInterval
    ) -> ToolchainCommandRequest {
        ToolchainCommandRequest(
            executablePath: inspection.flutterExecutablePath,
            arguments: flutterArguments,
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
        flutterArguments: [String],
        workingDirectory: URL,
        timeoutSeconds: TimeInterval
    ) -> ToolchainCommandRequest {
        ToolchainCommandRequest(
            executablePath: inspection.nixExecutablePath,
            arguments: nixDevelopArguments(
                environmentPath: inspection.environmentPath,
                flutterArguments: flutterArguments
            ),
            workingDirectoryPath: workingDirectory.path,
            environment: environment,
            timeoutSeconds: timeoutSeconds
        )
    }
}
