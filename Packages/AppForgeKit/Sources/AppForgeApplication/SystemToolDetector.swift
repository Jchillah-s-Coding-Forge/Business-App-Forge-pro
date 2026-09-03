import AppForgeDomain

public struct SystemToolDetector: ToolDetector {
    public init() {}

    public func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) async -> ToolDetectionResult {
        switch requirement.id {
        case .xcode:
            AppleToolDetector().detect(requirement: requirement)
        case .androidSDK:
            AndroidSDKToolDetector().detect(requirement: requirement)
        default:
            ExecutableToolDetector().detect(
                requirement: requirement,
                flutterSDKPath: flutterSDKPath
            )
        }
    }
}
