import AppForgeDomain
import Foundation

public protocol FlutterProjectMaterializing: Sendable {
    func materialize(
        _ input: FlutterMaterializationInput
    ) throws -> FlutterMaterializationResult
}

extension MaterializeFlutterProjectUseCase: FlutterProjectMaterializing {
    public func materialize(
        _ input: FlutterMaterializationInput
    ) throws -> FlutterMaterializationResult {
        try self(input)
    }
}

public protocol MaterializedFlutterProjectBuilding: Sendable {
    func build(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain,
        targetURL: URL
    ) throws -> MaterializedFlutterGenerationResult
}

public struct MaterializedFlutterGenerationResult: Equatable, Sendable {
    public let projectPath: String
    public let graph: ResolvedProductGraph
    public let lockfile: ForgeLockfile
    public let plan: GenerationPlan
    public let toolchainReceipt: FlutterToolchainReceipt

    public init(
        projectPath: String,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile,
        plan: GenerationPlan,
        toolchainReceipt: FlutterToolchainReceipt
    ) {
        self.projectPath = projectPath
        self.graph = graph
        self.lockfile = lockfile
        self.plan = plan
        self.toolchainReceipt = toolchainReceipt
    }
}

public struct BuildFlutterProjectUseCase: Sendable {
    private let packageResolver: ResolveProductPackagesUseCase
    private let renderer: any FlutterProjectRendering
    private let materializer: any FlutterProjectMaterializing

    public init(
        packageResolver: ResolveProductPackagesUseCase =
            ResolveProductPackagesUseCase(),
        renderer: any FlutterProjectRendering =
            DeterministicFlutterProjectRenderer(),
        materializer: any FlutterProjectMaterializing =
            MaterializeFlutterProjectUseCase()
    ) {
        self.packageResolver = packageResolver
        self.renderer = renderer
        self.materializer = materializer
    }

    public func callAsFunction(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain,
        targetURL: URL
    ) throws -> MaterializedFlutterGenerationResult {
        let registry = try BundledPackageRegistry()
        return try self(
            specification: specification,
            requests: BundledPackageRegistry
                .defaultRootRequirements,
            registry: registry,
            toolchain: toolchain,
            targetURL: targetURL
        )
    }

    public func callAsFunction(
        specification: ProjectSpecification,
        requests: [ForgePackageRequirement],
        registry: some PackageRegistry,
        toolchain: FlutterMaterializationToolchain,
        targetURL: URL
    ) throws -> MaterializedFlutterGenerationResult {
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
        let materialization = try materializer.materialize(
            FlutterMaterializationInput(
                specification: specification,
                renderedProduct: FlutterRenderedProduct(
                    graph: resolution.graph,
                    lockfile: resolution.lockfile,
                    plan: plan
                ),
                toolchain: toolchain,
                targetURL: targetURL
            )
        )

        return MaterializedFlutterGenerationResult(
            projectPath: materialization.projectPath,
            graph: resolution.graph,
            lockfile: resolution.lockfile,
            plan: plan,
            toolchainReceipt: materialization.receipt
        )
    }
}


extension BuildFlutterProjectUseCase: MaterializedFlutterProjectBuilding {
    public func build(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain,
        targetURL: URL
    ) throws -> MaterializedFlutterGenerationResult {
        try self(
            specification: specification,
            toolchain: toolchain,
            targetURL: targetURL
        )
    }
}
