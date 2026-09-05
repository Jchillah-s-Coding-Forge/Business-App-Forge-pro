import AppForgeDomain
import Foundation

public struct GeneratedProjectResult: Equatable, Sendable {
    public let projectPath: String
    public let plan: GenerationPlan
    public let graph: ResolvedProductGraph
    public let lockfile: ForgeLockfile

    public init(
        projectPath: String,
        plan: GenerationPlan,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile
    ) {
        self.projectPath = projectPath
        self.plan = plan
        self.graph = graph
        self.lockfile = lockfile
    }
}

public struct GenerateFlutterProjectUseCase: Sendable {
    private let packageResolver: ResolveProductPackagesUseCase
    private let renderer: any FlutterProjectRendering
    private let writer: any GeneratedProjectWriting

    public init(
        packageResolver: ResolveProductPackagesUseCase = ResolveProductPackagesUseCase(),
        renderer: any FlutterProjectRendering = DeterministicFlutterProjectRenderer(),
        writer: any GeneratedProjectWriting = AtomicGeneratedProjectWriter()
    ) {
        self.packageResolver = packageResolver
        self.renderer = renderer
        self.writer = writer
    }

    public func callAsFunction(
        specification: ProjectSpecification,
        requests: [ForgePackageRequirement],
        registry: some PackageRegistry,
        targetURL: URL
    ) throws -> GeneratedProjectResult {
        let resolution = try packageResolver(
            specification: specification,
            requests: requests,
            registry: registry
        )
        let plan = try renderer.makePlan(
            specification: specification,
            graph: resolution.graph,
            lockfile: resolution.lockfile
        )
        let projectURL = try writer.write(plan: plan, to: targetURL)

        return GeneratedProjectResult(
            projectPath: projectURL.path,
            plan: plan,
            graph: resolution.graph,
            lockfile: resolution.lockfile
        )
    }
}
