import AppForgeCore
import AppForgeDomain
import CryptoKit
import Foundation

struct FlutterMaterializationWorkspace {
    let targetURL: URL
    let stagingRoot: URL
    let projectURL: URL

    static func validateTarget(
        _ targetURL: URL,
        fileManager: FileManager = .default
    ) throws {
        let target = targetURL.standardizedFileURL
        let parent = target.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        let parentExists = fileManager.fileExists(
            atPath: parent.path,
            isDirectory: &isDirectory
        )

        guard parentExists, isDirectory.boolValue else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für die Flutter-Materialisierung existiert nicht."
            )
        }
        guard fileManager.isWritableFile(atPath: parent.path) else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für die Flutter-Materialisierung ist nicht beschreibbar."
            )
        }
        guard !fileManager.fileExists(atPath: target.path) else {
            throw FlutterMaterializationError.targetAlreadyExists
        }
    }

    static func create(
        targetURL: URL,
        fileManager: FileManager = .default
    ) throws -> FlutterMaterializationWorkspace {
        let target = targetURL.standardizedFileURL
        let parent = target.deletingLastPathComponent()
        let stagingRoot = parent.appendingPathComponent(
            ".appforge-materialize-\(UUID().uuidString)",
            isDirectory: true
        )
        try fileManager.createDirectory(
            at: stagingRoot,
            withIntermediateDirectories: false
        )

        return FlutterMaterializationWorkspace(
            targetURL: target,
            stagingRoot: stagingRoot,
            projectURL: stagingRoot.appendingPathComponent(
                "project",
                isDirectory: true
            )
        )
    }

    func validateCreatedProject(
        fileManager: FileManager = .default
    ) throws {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: projectURL.path,
            isDirectory: &isDirectory
        )
        guard exists, isDirectory.boolValue else {
            throw AppForgeError.generation(
                message: "Flutter hat keinen vollständigen Projektordner erzeugt."
            )
        }
    }

    func prepareForOverlay(
        fileManager: FileManager = .default
    ) throws {
        let relativePaths = [
            "lib",
            "test",
            "analysis_options.yaml",
            "pubspec.lock",
            ".dart_tool"
        ]

        for relativePath in relativePaths {
            let url = projectURL.appendingPathComponent(relativePath)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    func write(
        plan: GenerationPlan,
        fileManager: FileManager = .default
    ) throws {
        try GenerationPlanFileWriter().write(
            plan: plan,
            into: projectURL,
            fileManager: fileManager
        )
    }

    func pubspecLockSHA256(
        fileManager: FileManager = .default
    ) throws -> String {
        let lockURL = projectURL.appendingPathComponent("pubspec.lock")
        guard fileManager.fileExists(atPath: lockURL.path) else {
            throw FlutterMaterializationError.missingPubspecLock
        }

        let data = try Data(contentsOf: lockURL)
        return SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    func write(
        receipt: FlutterToolchainReceipt
    ) throws {
        let data = try FlutterToolchainReceiptCodec().encode(receipt)
        let receiptURL = projectURL.appendingPathComponent(
            FlutterToolchainReceipt.defaultFileName
        )
        try data.write(to: receiptURL, options: .atomic)
    }

    func publish(
        fileManager: FileManager = .default
    ) throws -> URL {
        guard !fileManager.fileExists(atPath: targetURL.path) else {
            throw FlutterMaterializationError.targetAlreadyExists
        }

        try fileManager.moveItem(at: projectURL, to: targetURL)
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
            let message = "Flutter-Materialisierung fehlgeschlagen und das Staging-Verzeichnis "
                + "konnte nicht vollständig entfernt werden. Ursprünglicher Fehler: "
                + originalError.localizedDescription
                + " Cleanup-Fehler: "
                + error.localizedDescription
            throw AppForgeError.fileSystem(message: message)
        }

        throw originalError
    }
}
