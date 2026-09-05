import AppForgeDomain

public struct NixEnvironmentPlanner: Sendable {
    public init() {}

    public func plan(
        for specification: ProjectSpecification
    ) throws -> NixEnvironmentPlan {
        guard specification.framework == .flutter else {
            throw NixEnvironmentError.unsupportedFramework(
                specification.framework
            )
        }

        var packages: Set<NixEnvironmentPackage> = [
            .flutter,
            .git
        ]
        var unmanaged = Set<ToolIdentifier>()

        if specification.targetPlatforms.contains(.android) {
            packages.insert(.jdk17)
            unmanaged.insert(.androidSDK)
        }
        if specification.targetPlatforms.contains(.iOS) {
            unmanaged.insert(.xcode)
        }

        return NixEnvironmentPlan(
            systems: NixEnvironmentSystem.allCases,
            packages: Array(packages),
            unmanagedRequirements: Array(unmanaged)
        )
    }
}
