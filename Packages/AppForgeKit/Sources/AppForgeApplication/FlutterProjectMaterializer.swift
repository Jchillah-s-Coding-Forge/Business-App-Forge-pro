import AppForgeDomain
import Foundation

public struct FlutterRenderedProduct: Equatable, Sendable {
    public let graph: ResolvedProductGraph
    public let lockfile: ForgeLockfile
    public let plan: GenerationPlan

    public init(
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile,
        plan: GenerationPlan
    ) {
        self.graph = graph
        self.lockfile = lockfile
        self.plan = plan
    }
}

public struct FlutterMaterializationInput: Equatable, Sendable {
    public let specification: ProjectSpecification
    public let renderedProduct: FlutterRenderedProduct
    public let flutterSDKPath: String
    public let targetURL: URL

    public init(
        specification: ProjectSpecification,
        renderedProduct: FlutterRenderedProduct,
        flutterSDKPath: String,
        targetURL: URL
    ) {
        self.specification = specification
        self.renderedProduct = renderedProduct
        self.flutterSDKPath = flutterSDKPath
        self.targetURL = targetURL
    }
}

public struct FlutterMaterializationResult: Equatable, Sendable {
    public let projectPath: String
    public let receipt: FlutterToolchainReceipt

    public init(
        projectPath: String,
        receipt: FlutterToolchainReceipt
    ) {
        self.projectPath = projectPath
        self.receipt = receipt
    }
}

public struct MaterializeFlutterProjectUseCase: Sendable {
    private let specificationValidator: ProjectSpecificationValidator
    private let renderer: any FlutterProjectRendering
    private let inspector: any FlutterToolchainInspecting
    private let runner: any ToolchainCommandRunning

    public init(
        specificationValidator: ProjectSpecificationValidator = ProjectSpecificationValidator(),
        renderer: any FlutterProjectRendering = DeterministicFlutterProjectRenderer(),
        inspector: any FlutterToolchainInspecting = SystemFlutterToolchainInspector(),
        runner: any ToolchainCommandRunning = SystemToolchainCommandRunner()
    ) {
        self.specificationValidator = specificationValidator
        self.renderer = renderer
        self.inspector = inspector
        self.runner = runner
    }

    public func callAsFunction(
        _ input: FlutterMaterializationInput
    ) throws -> FlutterMaterializationResult {
        try validate(input)
        try FlutterMaterializationWorkspace.validateTarget(
            input.targetURL
        )

        let inspection = try inspector.inspect(
            sdkRootPath: input.flutterSDKPath
        )
        let workspace = try FlutterMaterializationWorkspace.create(
            targetURL: input.targetURL
        )
        let executor = FlutterMaterializationCommandExecutor(
            inspection: inspection,
            runner: runner
        )

        do {
            return try materialize(
                input,
                inspection: inspection,
                workspace: workspace,
                executor: executor
            )
        } catch {
            try workspace.fail(with: error)
        }
    }

    private func validate(
        _ input: FlutterMaterializationInput
    ) throws {
        let specification = input.specification
        let issues = specificationValidator.validate(specification)
        guard issues.isEmpty else {
            throw FlutterMaterializationError.invalidSpecification(issues)
        }

        let rendered = input.renderedProduct
        let expectedPlan = try renderer.makePlan(
            specification: specification,
            graph: rendered.graph,
            lockfile: rendered.lockfile
        )
        guard expectedPlan == rendered.plan else {
            throw FlutterMaterializationError.generationPlanMismatch
        }
    }

    private func materialize(
        _ input: FlutterMaterializationInput,
        inspection: FlutterToolchainInspection,
        workspace: FlutterMaterializationWorkspace,
        executor: FlutterMaterializationCommandExecutor
    ) throws -> FlutterMaterializationResult {
        let specification = input.specification
        let packageName = try FlutterDartNaming.packageName(
            from: specification.identity.name
        )
        let platformNames = try FlutterMaterializationPlatformMapper.names(
            for: specification.targetPlatforms
        )

        try executor.createProject(
            packageName: packageName,
            organizationIdentifier: specification.identity.organizationIdentifier,
            platformNames: platformNames,
            in: workspace.stagingRoot
        )
        try workspace.validateCreatedProject()
        try workspace.prepareForOverlay()
        try workspace.write(plan: input.renderedProduct.plan)

        try executor.resolveDependencies(in: workspace.projectURL)
        try executor.analyze(projectURL: workspace.projectURL)
        try executor.test(projectURL: workspace.projectURL)

        let receipt = try makeReceipt(
            specification: specification,
            inspection: inspection,
            packageName: packageName,
            lockHash: workspace.pubspecLockSHA256()
        )
        try workspace.write(receipt: receipt)
        let finalURL = try workspace.publish()

        return FlutterMaterializationResult(
            projectPath: finalURL.path,
            receipt: receipt
        )
    }

    private func makeReceipt(
        specification: ProjectSpecification,
        inspection: FlutterToolchainInspection,
        packageName: String,
        lockHash: String
    ) -> FlutterToolchainReceipt {
        FlutterToolchainReceipt(
            flutter: inspection.identity,
            projectPackageName: packageName,
            organizationIdentifier: specification.identity.organizationIdentifier,
            targetPlatforms: FlutterMaterializationPlatformMapper.sortedPlatforms(
                specification.targetPlatforms
            ),
            pubspecLockSHA256: lockHash,
            validatedSteps: [
                .inspectToolchain,
                .create,
                .pubGet,
                .analyze,
                .test
            ]
        )
    }
}
