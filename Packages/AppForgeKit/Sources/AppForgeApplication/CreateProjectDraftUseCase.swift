import AppForgeDomain

public struct CreateProjectDraftUseCase: Sendable {
    public init() {}

    public func callAsFunction(
        projectName: String = "",
        organizationIdentifier: String = ""
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: projectName,
                organizationIdentifier: organizationIdentifier
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
    }
}
