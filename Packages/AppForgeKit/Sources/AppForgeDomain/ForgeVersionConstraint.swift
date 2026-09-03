import Foundation

public struct ForgeVersionConstraint: Codable, Equatable, Sendable, CustomStringConvertible {
    public static let any = ForgeVersionConstraint()

    public let exact: ForgeSemanticVersion?
    public let minimumInclusive: ForgeSemanticVersion?
    public let maximumExclusive: ForgeSemanticVersion?

    public init(
        exact: ForgeSemanticVersion? = nil,
        minimumInclusive: ForgeSemanticVersion? = nil,
        maximumExclusive: ForgeSemanticVersion? = nil
    ) {
        self.exact = exact
        self.minimumInclusive = minimumInclusive
        self.maximumExclusive = maximumExclusive
    }

    public static func exactly(_ version: ForgeSemanticVersion) -> ForgeVersionConstraint {
        ForgeVersionConstraint(exact: version)
    }

    public static func atLeast(_ version: ForgeSemanticVersion) -> ForgeVersionConstraint {
        ForgeVersionConstraint(minimumInclusive: version)
    }

    public static func range(
        from minimumInclusive: ForgeSemanticVersion,
        to maximumExclusive: ForgeSemanticVersion
    ) -> ForgeVersionConstraint {
        ForgeVersionConstraint(
            minimumInclusive: minimumInclusive,
            maximumExclusive: maximumExclusive
        )
    }

    public func accepts(_ version: ForgeSemanticVersion) -> Bool {
        if let exact, version != exact {
            return false
        }
        if let minimumInclusive, version < minimumInclusive {
            return false
        }
        if let maximumExclusive, version >= maximumExclusive {
            return false
        }
        return true
    }

    public var isSatisfiable: Bool {
        if let minimumInclusive, let maximumExclusive, minimumInclusive >= maximumExclusive {
            return false
        }
        if let exact {
            if let minimumInclusive, exact < minimumInclusive {
                return false
            }
            if let maximumExclusive, exact >= maximumExclusive {
                return false
            }
        }
        return true
    }

    public var description: String {
        if let exact {
            return "=\(exact)"
        }
        switch (minimumInclusive, maximumExclusive) {
        case let (.some(minimum), .some(maximum)):
            return ">=\(minimum) <\(maximum)"
        case let (.some(minimum), .none):
            return ">=\(minimum)"
        case let (.none, .some(maximum)):
            return "<\(maximum)"
        case (.none, .none):
            return "*"
        }
    }
}
