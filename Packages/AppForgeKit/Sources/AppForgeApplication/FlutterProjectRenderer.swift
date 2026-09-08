import AppForgeDomain

public protocol FlutterProjectRendering: Sendable {
    func makePlan(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile
    ) throws -> GenerationPlan
}

public enum FlutterRendererError: Error, Equatable, Sendable {
    case unsupportedFramework(OutputFramework)
    case invalidSpecification([ProjectSpecificationValidationIssue])
    case lockfileMismatch
    case invalidProjectPackageName(String)
    case invalidGeneratedIdentifier(definitionID: String, code: String)
    case duplicateGeneratedIdentifier(entityID: String, identifier: String)
    case reservedGeneratedMember(definitionID: String, identifier: String)
    case generatedMemberCollision(
        entityID: String,
        firstDefinitionID: String,
        secondDefinitionID: String,
        identifier: String
    )
    case generatedOutputPathCollision(
        firstDefinitionID: String,
        secondDefinitionID: String,
        path: String
    )
    case reservedGeneratedTypeName(definitionID: String, typeName: String)
    case generatedTypeNameCollision(
        firstDefinitionID: String,
        secondDefinitionID: String,
        typeName: String
    )
    case formScreenRequiresEntity(screenID: String)
    case ambiguousFieldPresentation(
        screenID: String,
        fieldID: String,
        firstPresentationID: String,
        secondPresentationID: String
    )
    case reservedGeneratedStorageIdentifier(definitionID: String, identifier: String)
    case duplicateGeneratedStorageIdentifier(entityID: String, identifier: String)
    case encodingFailed
}

public struct DeterministicFlutterProjectRenderer: FlutterProjectRendering {
    public static let rendererVersion = 3

    private let specificationValidator: ProjectSpecificationValidator
    private let lockfileBuilder: ForgeLockfileBuilder

    public init(
        specificationValidator: ProjectSpecificationValidator = ProjectSpecificationValidator(),
        lockfileBuilder: ForgeLockfileBuilder = ForgeLockfileBuilder()
    ) {
        self.specificationValidator = specificationValidator
        self.lockfileBuilder = lockfileBuilder
    }

    public func makePlan(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile
    ) throws -> GenerationPlan {
        guard specification.framework == .flutter else {
            throw FlutterRendererError.unsupportedFramework(specification.framework)
        }

        let issues = specificationValidator.validate(specification)
        guard issues.isEmpty else {
            throw FlutterRendererError.invalidSpecification(issues)
        }

        try FlutterGeneratedContractValidator().validate(
            specification
        )

        let expectedLockfile = lockfileBuilder.build(
            graph: graph,
            specification: specification
        )
        guard expectedLockfile == lockfile else {
            throw FlutterRendererError.lockfileMismatch
        }

        let packageName = try FlutterDartNaming.packageName(
            from: specification.identity.name
        )
        let files = try FlutterSourceBuilder(
            specification: specification,
            graph: graph,
            lockfile: lockfile,
            packageName: packageName,
            rendererVersion: Self.rendererVersion
        ).build()

        return try GenerationPlan(files: files)
    }
}
