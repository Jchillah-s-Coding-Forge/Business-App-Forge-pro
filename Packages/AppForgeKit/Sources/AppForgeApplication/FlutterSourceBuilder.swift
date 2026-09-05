import AppForgeDomain
import Foundation

struct FlutterSourceBuilder {
    let specification: ProjectSpecification
    let graph: ResolvedProductGraph
    let lockfile: ForgeLockfile
    let packageName: String
    let rendererVersion: Int

    func build() throws -> [GeneratedFile] {
        var files = try FlutterProjectCoreSources(
            specification: specification,
            graph: graph,
            lockfile: lockfile,
            packageName: packageName
        ).files()

        for entity in specification.entities.sorted(by: Self.entitySort) {
            try files.append(contentsOf: FlutterFeatureSources(entity: entity).files())
        }

        try files.append(generationManifestFile(existingFiles: files))
        return files
    }

    private func generationManifestFile(
        existingFiles: [GeneratedFile]
    ) throws -> GeneratedFile {
        let manifestPath = "appforge.generated.json"
        let paths = (existingFiles.map(\.relativePath) + [manifestPath]).sorted()
        let manifest = GenerationManifest(
            rendererVersion: rendererVersion,
            projectSchemaVersion: specification.schemaVersion,
            packageName: packageName,
            forgePackages: graph.packages
                .map(\.contract.id.rawValue)
                .sorted(),
            files: paths
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(manifest)
        guard let text = String(data: data, encoding: .utf8) else {
            throw FlutterRendererError.encodingFailed
        }
        return GeneratedFile(relativePath: manifestPath, contents: text)
    }

    private static func entitySort(
        _ lhs: EntityDefinition,
        _ rhs: EntityDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}

private struct GenerationManifest: Codable {
    let rendererVersion: Int
    let projectSchemaVersion: Int
    let packageName: String
    let forgePackages: [String]
    let files: [String]
}
