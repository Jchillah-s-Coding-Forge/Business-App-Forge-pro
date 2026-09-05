import AppForgeCore
import AppForgeDomain
import Foundation

struct GenerationPlanFileWriter {
    func write(
        plan: GenerationPlan,
        into rootURL: URL,
        fileManager: FileManager = .default
    ) throws {
        let standardizedRoot = rootURL.standardizedFileURL
        let rootPrefix = standardizedRoot.path + "/"

        for file in plan.files {
            let destinationURL = standardizedRoot
                .appendingPathComponent(file.relativePath)
                .standardizedFileURL

            guard destinationURL.path.hasPrefix(rootPrefix) else {
                throw AppForgeError.fileSystem(
                    message: "Eine generierte Datei würde den Projektordner verlassen."
                )
            }

            try fileManager.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            guard let data = file.contents.data(using: .utf8) else {
                throw AppForgeError.generation(
                    message: "Die Datei \(file.relativePath) konnte nicht als UTF-8 codiert werden."
                )
            }
            try data.write(to: destinationURL, options: .atomic)
        }
    }
}
