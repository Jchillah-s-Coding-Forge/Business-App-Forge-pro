import Foundation

public struct ForgeSemanticVersion:
    Codable,
    Hashable,
    Comparable,
    Sendable,
    LosslessStringConvertible,
    CustomStringConvertible
{
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: [String]
    public let buildMetadata: [String]

    public init(
        major: Int,
        minor: Int,
        patch: Int,
        prerelease: [String] = [],
        buildMetadata: [String] = []
    ) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }

    public init?(_ description: String) {
        let buildSplit = description.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false)
        guard buildSplit.count <= 2 else { return nil }

        let versionAndPrerelease = String(buildSplit[0])
        let build = buildSplit.count == 2 ? String(buildSplit[1]) : nil

        let prereleaseSplit = versionAndPrerelease.split(
            separator: "-",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        let core = String(prereleaseSplit[0])
        let prereleaseValue = prereleaseSplit.count == 2 ? String(prereleaseSplit[1]) : nil

        let coreParts = core.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard coreParts.count == 3,
              Self.isValidCoreNumber(coreParts[0]),
              Self.isValidCoreNumber(coreParts[1]),
              Self.isValidCoreNumber(coreParts[2]),
              let major = Int(coreParts[0]),
              let minor = Int(coreParts[1]),
              let patch = Int(coreParts[2])
        else {
            return nil
        }

        let prerelease = Self.parseIdentifiers(prereleaseValue, numericLeadingZeroForbidden: true)
        if prereleaseValue != nil, prerelease == nil {
            return nil
        }

        let buildMetadata = Self.parseIdentifiers(build, numericLeadingZeroForbidden: false)
        if build != nil, buildMetadata == nil {
            return nil
        }

        self.init(
            major: major,
            minor: minor,
            patch: patch,
            prerelease: prerelease ?? [],
            buildMetadata: buildMetadata ?? []
        )
    }

    public var description: String {
        var value = "\(major).\(minor).\(patch)"
        if !prerelease.isEmpty {
            value += "-\(prerelease.joined(separator: "."))"
        }
        if !buildMetadata.isEmpty {
            value += "+\(buildMetadata.joined(separator: "."))"
        }
        return value
    }

    public static func < (lhs: ForgeSemanticVersion, rhs: ForgeSemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        if lhs.patch != rhs.patch {
            return lhs.patch < rhs.patch
        }

        if lhs.prerelease.isEmpty != rhs.prerelease.isEmpty {
            return !lhs.prerelease.isEmpty
        }
        if lhs.prerelease.isEmpty {
            return false
        }

        for index in 0 ..< min(lhs.prerelease.count, rhs.prerelease.count) {
            let left = lhs.prerelease[index]
            let right = rhs.prerelease[index]
            if left == right {
                continue
            }

            let leftNumber = Int(left)
            let rightNumber = Int(right)
            switch (leftNumber, rightNumber) {
            case let (.some(leftValue), .some(rightValue)):
                return leftValue < rightValue
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return left < right
            }
        }

        return lhs.prerelease.count < rhs.prerelease.count
    }

    private static func isValidCoreNumber(_ value: String) -> Bool {
        guard !value.isEmpty, value.allSatisfy(\.isNumber) else { return false }
        return value == "0" || !value.hasPrefix("0")
    }

    private static func parseIdentifiers(
        _ value: String?,
        numericLeadingZeroForbidden: Bool
    ) -> [String]? {
        guard let value else { return [] }
        guard !value.isEmpty else { return nil }

        let parts = value.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        for part in parts {
            guard !part.isEmpty, part.allSatisfy(Self.isSemVerIdentifierCharacter) else { return nil }
            if numericLeadingZeroForbidden,
               part.allSatisfy(\.isNumber),
               part.count > 1,
               part.hasPrefix("0")
            {
                return nil
            }
        }
        return parts
    }

    private static func isSemVerIdentifierCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "-")
    }
}
