import Foundation

struct ProjectConfigurationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        if specification.identity.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyProjectName)
        }
        if !specification.identity.organizationIdentifier.isPortableOrganizationIdentifier {
            issues.append(.invalidOrganizationIdentifier(specification.identity.organizationIdentifier))
        }
        if !specification.hasSupportedTargetConfiguration {
            issues.append(.unsupportedTargetConfiguration)
        }

        switch specification.framework {
        case .flutter:
            if specification.flutterStateManagement == nil {
                issues.append(.flutterStateManagementRequired)
            }
        case .swiftUI, .compose:
            if specification.flutterStateManagement != nil {
                issues.append(.flutterStateManagementNotApplicable)
            }
        }

        let violatesSingleSourceOfTruth = specification.offline.isEnabled
            && !specification.offline.usesLocalSingleSourceOfTruth
        let cloudOfflineRequiresOutbox = specification.offline.isEnabled
            && specification.backend != .localOnly
            && !specification.offline.usesSyncOutbox

        if violatesSingleSourceOfTruth {
            issues.append(.offlineSingleSourceOfTruthRequired)
        }
        if cloudOfflineRequiresOutbox {
            issues.append(.offlineSyncOutboxRequired)
        }
        if let color = specification.design.primaryColorHex, !color.isHexColor {
            issues.append(.invalidPrimaryColorHex(color))
        }
        return issues
    }
}

extension String {
    var isHexColor: Bool {
        let value = hasPrefix("#") ? String(dropFirst()) : self
        guard value.count == 6 || value.count == 8 else {
            return false
        }
        return value.allSatisfy(\.isHexDigit)
    }

    var isPortableOrganizationIdentifier: Bool {
        range(
            of: "^[A-Za-z][A-Za-z0-9-]*(\\.[A-Za-z][A-Za-z0-9-]*)+$",
            options: .regularExpression
        ) != nil
    }
}
