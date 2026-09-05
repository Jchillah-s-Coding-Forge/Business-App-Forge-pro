import AppForgeDomain
import Foundation

public struct ForgeLockfileBuilder: Sendable {
    public init() {}

    public func build(
        graph: ResolvedProductGraph,
        specification: ProjectSpecification
    ) -> ForgeLockfile {
        let versions = Dictionary(uniqueKeysWithValues: graph.packages.map { package in
            (package.contract.id, package.contract.version)
        })

        let entries = graph.packages
            .map { package -> ForgeLockfileEntry in
                let contract = package.contract
                let dependencies = contract.dependencies.compactMap { dependency -> ForgeLockfileDependency? in
                    guard let version = versions[dependency.packageID] else { return nil }
                    return ForgeLockfileDependency(packageID: dependency.packageID, version: version)
                }.sorted { $0.packageID < $1.packageID }

                return ForgeLockfileEntry(
                    packageID: contract.id,
                    version: contract.version,
                    kind: contract.kind,
                    dependencies: dependencies,
                    providedCapabilities: contract.providedCapabilities.sorted(),
                    maturity: contract.maturity,
                    source: contract.source
                )
            }
            .sorted { $0.packageID < $1.packageID }

        return ForgeLockfile(
            projectSchemaVersion: specification.schemaVersion,
            framework: specification.framework,
            backend: specification.backend,
            packages: entries,
            capabilities: graph.capabilities.sorted()
        )
    }
}
