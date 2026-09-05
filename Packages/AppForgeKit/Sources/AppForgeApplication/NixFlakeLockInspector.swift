import AppForgeDomain
import CryptoKit
import Foundation

struct NixFlakeLockProvenance: Equatable {
    let nixpkgsRevision: String
    let sha256: String
}

struct NixFlakeLockInspector {
    func inspect(
        lockFileURL: URL
    ) throws -> NixFlakeLockProvenance {
        guard FileManager.default.fileExists(atPath: lockFileURL.path) else {
            throw NixEnvironmentError.invalidFlakeLock
        }

        let data = try Data(contentsOf: lockFileURL)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any],
              let nodes = root["nodes"] as? [String: Any],
              let rootNode = nodes["root"] as? [String: Any],
              let inputs = rootNode["inputs"] as? [String: Any],
              let nixpkgsNodeName = inputs["nixpkgs"] as? String,
              let nixpkgsNode = nodes[nixpkgsNodeName] as? [String: Any],
              let locked = nixpkgsNode["locked"] as? [String: Any],
              let revision = locked["rev"] as? String,
              revision.isGitRevision
        else {
            throw NixEnvironmentError.missingLockedNixpkgsRevision
        }

        let digest = SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()

        return NixFlakeLockProvenance(
            nixpkgsRevision: revision.lowercased(),
            sha256: digest
        )
    }
}

private extension String {
    var isGitRevision: Bool {
        range(
            of: "^[0-9a-fA-F]{7,64}$",
            options: .regularExpression
        ) != nil
    }
}
