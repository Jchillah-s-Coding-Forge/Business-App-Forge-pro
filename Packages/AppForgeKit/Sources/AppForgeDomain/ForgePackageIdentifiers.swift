import Foundation

public struct ForgePackageID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public static func < (lhs: ForgePackageID, rhs: ForgePackageID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ForgePackageID: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension ForgePackageID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public struct ForgeCapabilityID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public static func < (lhs: ForgeCapabilityID, rhs: ForgeCapabilityID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ForgeCapabilityID: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension ForgeCapabilityID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
