import Foundation

public struct ForgePackageID:
    RawRepresentable,
    Codable,
    Hashable,
    Comparable,
    Sendable,
    CustomStringConvertible,
    ExpressibleByStringLiteral
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public var description: String { rawValue }

    public static func < (lhs: ForgePackageID, rhs: ForgePackageID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct ForgeCapabilityID:
    RawRepresentable,
    Codable,
    Hashable,
    Comparable,
    Sendable,
    CustomStringConvertible,
    ExpressibleByStringLiteral
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public var description: String { rawValue }

    public static func < (lhs: ForgeCapabilityID, rhs: ForgeCapabilityID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
