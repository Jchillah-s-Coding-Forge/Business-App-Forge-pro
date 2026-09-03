import AppForgeDomain
import Foundation

public struct PackageResolutionOutput: Equatable, Sendable {
    public let graph: ResolvedProductGraph
    public let lockfile: ForgeLockfile

    public init(graph: ResolvedProductGraph, lockfile: ForgeLockfile) {
        self.graph = graph
        self.lockfile = lockfile
    }
}

public struct ResolveProductPackagesUseCase: Sendable {
    private let specificationValidator: ProjectSpecificationValidator
    private let resolver: PackageResolver
    private let lockfileBuilder: ForgeLockfileBuilder

    public init(
        specificationValidator: ProjectSpecificationValidator = ProjectSpecificationValidator(),
        resolver: PackageResolver = PackageResolver(),
        lockfileBuilder: ForgeLockfileBuilder = ForgeLockfileBuilder()
    ) {
        self.specificationValidator = specificationValidator
        self.resolver = resolver
        self.lockfileBuilder = lockfileBuilder
    }

    public func callAsFunction<Registry: PackageRegistry>(
        specification: ProjectSpecification,
        requests: [ForgePackageRequirement],
        registry: Registry
    ) throws -> PackageResolutionOutput {
        let specificationIssues = specificationValidator.validate(specification)
        guard specificationIssues.isEmpty else {
            throw PackageResolutionError.invalidProjectSpecification(specificationIssues)
        }

        let graph = try resolver.resolve(
            requests: requests,
            specification: specification,
            registry: registry
        )
        let lockfile = lockfileBuilder.build(graph: graph, specification: specification)
        return PackageResolutionOutput(graph: graph, lockfile: lockfile)
    }
}
