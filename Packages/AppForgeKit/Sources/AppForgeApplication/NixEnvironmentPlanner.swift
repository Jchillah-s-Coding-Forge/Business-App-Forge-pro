import AppForgeDomain

public struct NixEnvironmentPlanner: Sendable {
    public init() {}

    public func plan(
        for specification: ProjectSpecification
    ) throws -> NixEnvironmentPlan {
        try plan(
            framework: specification.framework,
            targetPlatforms: specification.targetPlatforms
        )
    }

    public func plan(
        framework: OutputFramework,
        targetPlatforms: Set<TargetPlatform>
    ) throws -> NixEnvironmentPlan {
        guard framework == .flutter else {
            throw NixEnvironmentError.unsupportedFramework(
                framework
            )
        }

        var packages: Set<NixEnvironmentPackage> = [
            .flutter,
            .git
        ]
        var unmanaged = Set<ToolIdentifier>()

        if targetPlatforms.contains(.android) {
            packages.insert(.jdk17)
            unmanaged.insert(.androidSDK)
        }
        if targetPlatforms.contains(.iOS) {
            unmanaged.insert(.xcode)
        }

        return NixEnvironmentPlan(
            systems: NixEnvironmentSystem.allCases,
            packages: Array(packages),
            unmanagedRequirements: Array(unmanaged)
        )
    }
}
