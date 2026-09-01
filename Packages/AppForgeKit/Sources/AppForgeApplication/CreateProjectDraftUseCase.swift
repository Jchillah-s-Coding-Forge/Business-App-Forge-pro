import AppForgeDomain

public struct CreateProjectDraftUseCase: Sendable {
    public init() {}

    public func callAsFunction(projectName: String = "") -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: projectName,
                organizationIdentifier: "com.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
    }
}
