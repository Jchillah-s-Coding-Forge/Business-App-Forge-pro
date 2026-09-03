import Foundation

public enum ToolIdentifier: String, CaseIterable, Codable, Identifiable, Sendable {
    case git
    case flutter
    case xcode
    case xcodeGen
    case androidSDK
    case java
    case vsCode
    case androidStudio
    case supabaseCLI
    case docker

    public var id: String {
        rawValue
    }
}

public enum ToolAvailability: String, Codable, Sendable {
    case ready
    case missing
    case incompatible
}

public enum ToolInstallStrategy: String, Codable, Sendable {
    case systemManaged
    case userSelectedLocation
    case externalApplication
    case manual
}

public struct SemanticVersion: Codable, Equatable, Comparable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public init?(parsing text: String) {
        let token = text.split { character in
            !(character.isNumber || character == ".")
        }.first { candidate in
            candidate.contains(".")
        }

        guard let token else { return nil }
        let numbers = token.split(separator: ".").compactMap { component in
            Int(String(component))
        }
        guard numbers.count >= 2 else { return nil }

        major = numbers[0]
        minor = numbers[1]
        patch = numbers.count > 2 ? numbers[2] : 0
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}

public struct ToolVersionConstraint: Codable, Equatable, Sendable {
    public static let any = ToolVersionConstraint(minimum: nil)

    public let minimum: SemanticVersion?

    public init(minimum: SemanticVersion?) {
        self.minimum = minimum
    }

    public func accepts(_ version: SemanticVersion?) -> Bool {
        guard let minimum else { return true }
        guard let version else { return false }
        return version >= minimum
    }
}

public struct ToolRequirement: Codable, Equatable, Identifiable, Sendable {
    public let id: ToolIdentifier
    public let displayName: String
    public let purpose: String
    public let isRequired: Bool
    public let versionConstraint: ToolVersionConstraint
    public let installStrategy: ToolInstallStrategy

    public init(
        id: ToolIdentifier,
        displayName: String,
        purpose: String,
        isRequired: Bool,
        versionConstraint: ToolVersionConstraint = .any,
        installStrategy: ToolInstallStrategy
    ) {
        self.id = id
        self.displayName = displayName
        self.purpose = purpose
        self.isRequired = isRequired
        self.versionConstraint = versionConstraint
        self.installStrategy = installStrategy
    }
}

public struct ToolDetectionResult: Codable, Equatable, Identifiable, Sendable {
    public var id: ToolIdentifier {
        requirement.id
    }

    public let requirement: ToolRequirement
    public let availability: ToolAvailability
    public let version: SemanticVersion?
    public let path: String?
    public let detail: String

    public init(
        requirement: ToolRequirement,
        availability: ToolAvailability,
        version: SemanticVersion?,
        path: String?,
        detail: String
    ) {
        self.requirement = requirement
        self.availability = availability
        self.version = version
        self.path = path
        self.detail = detail
    }
}

public struct ToolchainReport: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let results: [ToolDetectionResult]

    public init(generatedAt: Date = Date(), results: [ToolDetectionResult]) {
        self.generatedAt = generatedAt
        self.results = results
    }

    public var isReady: Bool {
        results.allSatisfy { result in
            !result.requirement.isRequired || result.availability == .ready
        }
    }

    public var requiredFailures: [ToolDetectionResult] {
        results.filter { $0.requirement.isRequired && $0.availability != .ready }
    }
}

public enum PreferredIDE: String, CaseIterable, Codable, Identifiable, Sendable {
    case vsCode = "VS Code"
    case androidStudio = "Android Studio"
    case xcode = "Xcode"
    case finder = "Finder"
    case terminal = "Terminal"

    public var id: String {
        rawValue
    }
}

public struct ToolchainPreferences: Codable, Equatable, Sendable {
    public var flutterSDKPath: String?
    public var preferredIDE: PreferredIDE

    public init(flutterSDKPath: String? = nil, preferredIDE: PreferredIDE = .vsCode) {
        self.flutterSDKPath = flutterSDKPath
        self.preferredIDE = preferredIDE
    }
}
