import AppForgeDomain
import Foundation

struct FlutterSourceBuilder {
    let specification: ProjectSpecification
    let graph: ResolvedProductGraph
    let lockfile: ForgeLockfile
    let packageName: String
    let rendererVersion: Int

    func build() throws -> [GeneratedFile] {
        var files = try baseFiles()
        files.append(contentsOf: try featureFiles())
        files.append(contentsOf: try presentationFiles())
        try files.append(generationManifestFile(existingFiles: files))
        return files
    }

    private func baseFiles() throws -> [GeneratedFile] {
        var files = try FlutterProjectCoreSources(
            specification: specification,
            graph: graph,
            lockfile: lockfile,
            packageName: packageName
        ).files()
        try replaceAppShell(in: &files)
        files.append(
            contentsOf: FlutterDomainContractSources(
                specification: specification
            ).files()
        )
        try files.append(
            contentsOf: FlutterOfflineCoreSources(
                specification: specification,
                packageName: packageName
            ).files()
        )
        return files
    }

    private func featureFiles() throws -> [GeneratedFile] {
        var result: [GeneratedFile] = []
        for entity in specification.entities.sorted(by: Self.entitySort) {
            try result.append(
                contentsOf: FlutterFeatureSources(
                    specification: specification,
                    entity: entity
                ).files()
            )
            try result.append(
                contentsOf: FlutterOfflineFeatureSources(
                    specification: specification,
                    entity: entity
                ).files()
            )
        }
        return result
    }

    private func presentationFiles() throws -> [GeneratedFile] {
        var result = try FlutterGeneratedFormSources(
            specification: specification
        ).files()
        try result.append(
            contentsOf: FlutterGeneratedCreateSources(
                specification: specification
            ).files()
        )
        result.append(
            contentsOf: FlutterGeneratedRecordDisplaySources(
                specification: specification
            ).files()
        )
        try result.append(
            contentsOf: FlutterGeneratedListSources(
                specification: specification
            ).files()
        )
        try result.append(
            contentsOf: FlutterGeneratedDetailSources(
                specification: specification
            ).files()
        )
        return result
    }

    private func replaceAppShell(
        in files: inout [GeneratedFile]
    ) throws {
        let replacements = try FlutterGeneratedAppSources(
            specification: specification,
            packageName: packageName
        ).files()
        let replacementPaths = Set(replacements.map(\.relativePath))
        files.removeAll { replacementPaths.contains($0.relativePath) }
        files.append(contentsOf: replacements)
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
