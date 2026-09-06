import AppForgeDomain
import Foundation

public struct IDEHandoffAvailability: Equatable, Identifiable, Sendable {
    public let ide: PreferredIDE
    public let applicationPath: String?

    public init(
        ide: PreferredIDE,
        applicationPath: String?
    ) {
        self.ide = ide
        self.applicationPath = applicationPath
    }

    public var id: PreferredIDE {
        ide
    }

    public var isAvailable: Bool {
        switch ide {
        case .finder, .systemDefault:
            true
        default:
            applicationPath != nil
        }
    }
}

public protocol MacOSApplicationLocating: Sendable {
    func locate(
        bundleIdentifier: String,
        knownPaths: [String]
    ) -> String?
}

public protocol IDEHandoffDetecting: Sendable {
    func detect() -> [IDEHandoffAvailability]
}

public struct SystemIDEHandoffDetector: IDEHandoffDetecting {
    private let locator: any MacOSApplicationLocating

    public init(
        locator: any MacOSApplicationLocating =
            SystemMacOSApplicationLocator()
    ) {
        self.locator = locator
    }

    public func detect() -> [IDEHandoffAvailability] {
        PreferredIDE.allCases.map { ide in
            let descriptor = IDEApplicationDescriptor(
                ide: ide
            )
            let path = descriptor.bundleIdentifier.flatMap {
                locator.locate(
                    bundleIdentifier: $0,
                    knownPaths: descriptor.knownPaths
                )
            }

            return IDEHandoffAvailability(
                ide: ide,
                applicationPath: path
            )
        }
    }
}

public struct SystemMacOSApplicationLocator: MacOSApplicationLocating {
    public init() {}

    public func locate(
        bundleIdentifier: String,
        knownPaths: [String]
    ) -> String? {
        if let known = existingKnownPath(
            knownPaths
        ) {
            return known
        }

        return spotlightApplicationPath(
            bundleIdentifier: bundleIdentifier
        )
    }

    private func existingKnownPath(
        _ paths: [String]
    ) -> String? {
        for path in paths {
            let expanded = NSString(
                string: path
            ).expandingTildeInPath
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(
                atPath: expanded,
                isDirectory: &isDirectory
            )
            if exists, isDirectory.boolValue {
                return URL(
                    fileURLWithPath: expanded,
                    isDirectory: true
                ).standardizedFileURL.path
            }
        }
        return nil
    }

    private func spotlightApplicationPath(
        bundleIdentifier: String
    ) -> String? {
        let query =
            "kMDItemCFBundleIdentifier == '\(bundleIdentifier)'"
        let execution = SystemToolDetectionSupport.run(
            executablePath: "/usr/bin/mdfind",
            arguments: [query]
        )
        guard execution.exitCode == 0 else {
            return nil
        }

        return execution.output
            .split(separator: "\n")
            .map(String.init)
            .first(where: isApplicationPath)
    }

    private func isApplicationPath(
        _ path: String
    ) -> Bool {
        path.hasSuffix(".app")
            && FileManager.default.fileExists(
                atPath: path
            )
    }
}

struct IDEApplicationDescriptor: Sendable {
    let ide: PreferredIDE

    var bundleIdentifier: String? {
        switch ide {
        case .vsCode:
            "com.microsoft.VSCode"
        case .androidStudio:
            "com.google.android.studio"
        case .xcode:
            "com.apple.dt.Xcode"
        case .terminal:
            "com.apple.Terminal"
        case .finder, .systemDefault:
            nil
        }
    }

    var knownPaths: [String] {
        switch ide {
        case .vsCode:
            [
                "/Applications/Visual Studio Code.app",
                "~/Applications/Visual Studio Code.app"
            ]
        case .androidStudio:
            [
                "/Applications/Android Studio.app",
                "~/Applications/Android Studio.app"
            ]
        case .xcode:
            [
                "/Applications/Xcode.app",
                "~/Applications/Xcode.app"
            ]
        case .terminal:
            [
                "/System/Applications/Utilities/Terminal.app",
                "/Applications/Utilities/Terminal.app"
            ]
        case .finder, .systemDefault:
            []
        }
    }
}

public struct IDEHandoffCommandBuilder: Sendable {
    public init() {}

    public func arguments(
        for ide: PreferredIDE,
        projectURL: URL
    ) -> [String] {
        let path = projectURL.standardizedFileURL.path

        switch ide {
        case .vsCode:
            ["-b", "com.microsoft.VSCode", path]
        case .androidStudio:
            ["-b", "com.google.android.studio", path]
        case .xcode:
            ["-b", "com.apple.dt.Xcode", path]
        case .finder:
            ["-R", path]
        case .terminal:
            ["-b", "com.apple.Terminal", path]
        case .systemDefault:
            [path]
        }
    }
}
