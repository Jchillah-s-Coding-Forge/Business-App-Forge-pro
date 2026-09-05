import AppForgeCore
import AppForgeDomain
import Foundation

struct NixEnvironmentWorkspace {
    let targetURL: URL
    let stagingRoot: URL
    let environmentURL: URL

    static func create(
        targetURL: URL,
        fileManager: FileManager = .default
    ) throws -> NixEnvironmentWorkspace {
        let target = targetURL.standardizedFileURL
        let parent = target.deletingLastPathComponent()

        var isDirectory: ObjCBool = false
        let parentExists = fileManager.fileExists(
            atPath: parent.path,
            isDirectory: &isDirectory
        )
        guard parentExists, isDirectory.boolValue else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für die Nix-Umgebung existiert nicht."
            )
        }
        guard fileManager.isWritableFile(atPath: parent.path) else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für die Nix-Umgebung ist nicht beschreibbar."
            )
        }
        guard !fileManager.fileExists(atPath: target.path) else {
            throw NixEnvironmentError.targetAlreadyExists
        }

        let stagingRoot = parent.appendingPathComponent(
            ".appforge-nix-\(UUID().uuidString)",
            isDirectory: true
        )
        let environmentURL = stagingRoot.appendingPathComponent(
            "environment",
            isDirectory: true
        )

        try fileManager.createDirectory(
            at: environmentURL,
            withIntermediateDirectories: true
        )

        return NixEnvironmentWorkspace(
            targetURL: target,
            stagingRoot: stagingRoot,
            environmentURL: environmentURL
        )
    }

    func writeFlake(
        _ contents: String
    ) throws {
        let url = environmentURL.appendingPathComponent("flake.nix")
        try Data(contents.utf8).write(to: url, options: .atomic)
    }

    func writeReceipt(
        _ receipt: NixEnvironmentReceipt
    ) throws {
        let data = try NixEnvironmentReceiptCodec().encode(receipt)
        let url = environmentURL.appendingPathComponent(
            NixEnvironmentReceipt.defaultFileName
        )
        try data.write(to: url, options: .atomic)
    }

    func lockFileURL() -> URL {
        environmentURL.appendingPathComponent("flake.lock")
    }

    func publish(
        fileManager: FileManager = .default
    ) throws -> URL {
        guard !fileManager.fileExists(atPath: targetURL.path) else {
            throw NixEnvironmentError.targetAlreadyExists
        }

        try fileManager.moveItem(at: environmentURL, to: targetURL)
        try? fileManager.removeItem(at: stagingRoot)
        return targetURL
    }

    func fail(
        with originalError: Error,
        fileManager: FileManager = .default
    ) throws -> Never {
        do {
            if fileManager.fileExists(atPath: stagingRoot.path) {
                try fileManager.removeItem(at: stagingRoot)
            }
        } catch {
            throw AppForgeError.fileSystem(
                message: "Nix-Provisioning fehlgeschlagen und das Staging-Verzeichnis konnte nicht entfernt werden. "
                    + "Ursprünglicher Fehler: \(originalError.localizedDescription). "
                    + "Cleanup-Fehler: \(error.localizedDescription)"
            )
        }

        throw originalError
    }
}
