import AppForgeCore
import AppForgeDomain
import Foundation

struct NixBootstrapWorkspace {
    static let prefix = ".appforge-nix-bootstrap-"
    static let installerName = "install.sh"
    static let commandName = "install.command"

    let rootURL: URL
    let installerURL: URL
    let commandURL: URL

    static func create(
        parentURL: URL,
        fileManager: FileManager = .default
    ) throws -> NixBootstrapWorkspace {
        let parent = parentURL.standardizedFileURL
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: parent.path,
            isDirectory: &isDirectory
        )
        guard exists, isDirectory.boolValue,
              fileManager.isWritableFile(atPath: parent.path)
        else {
            throw AppForgeError.fileSystem(
                message: "Der Nix-Bootstrap-Arbeitsordner ist nicht beschreibbar."
            )
        }

        let root = parent.appendingPathComponent(
            "\(prefix)\(UUID().uuidString)",
            isDirectory: true
        )
        try fileManager.createDirectory(
            at: root,
            withIntermediateDirectories: false
        )

        return NixBootstrapWorkspace(
            rootURL: root,
            installerURL: root.appendingPathComponent(installerName),
            commandURL: root.appendingPathComponent(commandName)
        )
    }

    func write(
        installerData: Data,
        fileManager: FileManager = .default
    ) throws {
        try installerData.write(
            to: installerURL,
            options: .atomic
        )
        try Self.commandContents.write(
            to: commandURL,
            atomically: true,
            encoding: .utf8
        )
        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: commandURL.path
        )
    }

    func prepared(
        version: String,
        sha256: String
    ) -> NixBootstrapPreparedInstaller {
        NixBootstrapPreparedInstaller(
            version: version,
            installerSHA256: sha256,
            workspacePath: rootURL.path,
            installerPath: installerURL.path,
            commandPath: commandURL.path
        )
    }

    func commandIsIntact() throws -> Bool {
        let data = try Data(contentsOf: commandURL)
        return data == Data(Self.commandContents.utf8)
    }

    func cleanup(
        fileManager: FileManager = .default
    ) throws {
        if fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.removeItem(at: rootURL)
        }
    }

    static func validate(
        _ prepared: NixBootstrapPreparedInstaller
    ) throws -> NixBootstrapWorkspace {
        let root = URL(
            fileURLWithPath: prepared.workspacePath,
            isDirectory: true
        ).standardizedFileURL
        guard root.lastPathComponent.hasPrefix(prefix) else {
            throw NixBootstrapError.invalidPreparedWorkspace
        }

        let installer = root.appendingPathComponent(installerName)
        let command = root.appendingPathComponent(commandName)
        guard installer.path == URL(
            fileURLWithPath: prepared.installerPath
        ).standardizedFileURL.path,
        command.path == URL(
            fileURLWithPath: prepared.commandPath
        ).standardizedFileURL.path
        else {
            throw NixBootstrapError.invalidPreparedWorkspace
        }

        return NixBootstrapWorkspace(
            rootURL: root,
            installerURL: installer,
            commandURL: command
        )
    }

    private static let commandContents = """
    #!/bin/sh
    set -eu
    SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
    exec /bin/sh "$SCRIPT_DIR/install.sh" --daemon
    """
}
