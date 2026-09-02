import Foundation

struct ProjectConfigurationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
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
        guard value.count == 6 || value.count == 8 else { return false }
        return value.allSatisfy(\.isHexDigit)
    }
}
