import AppForgeCore
import AppForgeDomain
import Foundation

public protocol GeneratedProjectWriting: Sendable {
    func write(plan: GenerationPlan, to targetURL: URL) throws -> URL
}

public struct AtomicGeneratedProjectWriter: GeneratedProjectWriting {
    public init() {}

    public func write(plan: GenerationPlan, to targetURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let standardizedTarget = targetURL.standardizedFileURL
        let parentURL = standardizedTarget.deletingLastPathComponent()
        try validateParent(parentURL, fileManager: fileManager)
        try ensureTargetIsAvailable(standardizedTarget, fileManager: fileManager)

        let stagingURL = parentURL.appendingPathComponent(
            ".appforge-project-\(UUID().uuidString)",
            isDirectory: true
        )

        do {
            try fileManager.createDirectory(
                at: stagingURL,
                withIntermediateDirectories: false
            )
            try GenerationPlanFileWriter().write(
                plan: plan,
                into: stagingURL,
                fileManager: fileManager
            )
            try ensureTargetIsAvailable(standardizedTarget, fileManager: fileManager)
            try fileManager.moveItem(at: stagingURL, to: standardizedTarget)
            return standardizedTarget
        } catch {
            try? cleanup(stagingURL, fileManager: fileManager)
            if let appForgeError = error as? AppForgeError {
                throw appForgeError
            }
            let message = "Der generierte Projektbaum konnte nicht atomar gespeichert werden: "
                + error.localizedDescription
            throw AppForgeError.fileSystem(message: message)
        }
    }

    private func validateParent(
        _ parentURL: URL,
        fileManager: FileManager
    ) throws {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: parentURL.path,
            isDirectory: &isDirectory
        )

        guard exists, isDirectory.boolValue else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für das generierte Projekt existiert nicht."
            )
        }
        guard fileManager.isWritableFile(atPath: parentURL.path) else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für das generierte Projekt ist nicht beschreibbar."
            )
        }
    }

    private func ensureTargetIsAvailable(
        _ targetURL: URL,
        fileManager: FileManager
    ) throws {
        guard !fileManager.fileExists(atPath: targetURL.path) else {
            throw AppForgeError.fileSystem(
                message: "Am gewählten Ziel existiert bereits eine Datei oder ein Projekt."
            )
        }
    }

    private func cleanup(
        _ stagingURL: URL,
        fileManager: FileManager
    ) throws {
        guard fileManager.fileExists(atPath: stagingURL.path) else {
            return
        }
        try fileManager.removeItem(at: stagingURL)
    }
}
