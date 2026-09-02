import AppForgeCore
import AppForgeDomain
import CryptoKit
import Foundation

public protocol FlutterSDKInstalling: Sendable {
    func install(
        into parentDirectoryPath: String,
        progress: @escaping @Sendable (FlutterInstallationPhase) async -> Void
    ) async throws -> FlutterInstallationResult
}

public protocol FlutterReleaseCatalogProviding: Sendable {
    func latestStable(for architecture: FlutterSDKArchitecture) async throws -> FlutterReleaseArtifact
}

public protocol FlutterArchiveDownloading: Sendable {
    func download(_ artifact: FlutterReleaseArtifact) async throws -> URL
}

public protocol FlutterArchiveChecksumVerifying: Sendable {
    func verify(fileURL: URL, expectedSHA256: String) throws -> Bool
}

public protocol FlutterArchiveExtracting: Sendable {
    func extract(archiveURL: URL, into parentDirectoryURL: URL) throws
}

public protocol FlutterSDKValidating: Sendable {
    func validate(sdkURL: URL) throws
}

public struct VerifiedFlutterSDKInstaller: FlutterSDKInstalling {
    private let catalog: any FlutterReleaseCatalogProviding
    private let downloader: any FlutterArchiveDownloading
    private let checksumVerifier: any FlutterArchiveChecksumVerifying
    private let extractor: any FlutterArchiveExtracting
    private let validator: any FlutterSDKValidating

    public init(
        catalog: any FlutterReleaseCatalogProviding = FlutterReleaseCatalogClient(),
        downloader: any FlutterArchiveDownloading = SystemFlutterArchiveDownloader(),
        checksumVerifier: any FlutterArchiveChecksumVerifying = SHA256ArchiveChecksumVerifier(),
        extractor: any FlutterArchiveExtracting = SystemFlutterArchiveExtractor(),
        validator: any FlutterSDKValidating = SystemFlutterSDKValidator()
    ) {
        self.catalog = catalog
        self.downloader = downloader
        self.checksumVerifier = checksumVerifier
        self.extractor = extractor
        self.validator = validator
    }

    public func install(
        into parentDirectoryPath: String,
        progress: @escaping @Sendable (FlutterInstallationPhase) async -> Void
    ) async throws -> FlutterInstallationResult {
        let parentURL = try validatedParentDirectory(path: parentDirectoryPath)
        let sdkURL = parentURL.appendingPathComponent("flutter", isDirectory: true)
        try ensureInstallTargetIsAvailable(sdkURL)

        await progress(.resolvingRelease)
        let architecture = try HostFlutterArchitecture.current()
        let artifact = try await catalog.latestStable(for: architecture)

        await progress(.downloading)
        let archiveURL = try await downloader.download(artifact)
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        await progress(.verifying)
        guard try checksumVerifier.verify(fileURL: archiveURL, expectedSHA256: artifact.sha256) else {
            throw AppForgeError.configuration(
                message: "Die Prüfsumme des Flutter-SDK-Downloads stimmt nicht mit dem offiziellen Release überein."
            )
        }

        let stagingURL = try makeStagingDirectory(in: parentURL)
        defer { try? FileManager.default.removeItem(at: stagingURL) }
        let stagedSDKURL = stagingURL.appendingPathComponent("flutter", isDirectory: true)

        await progress(.extracting)
        try extractor.extract(archiveURL: archiveURL, into: stagingURL)

        await progress(.validating)
        try validator.validate(sdkURL: stagedSDKURL)
        try ensureInstallTargetIsAvailable(sdkURL)
        try FileManager.default.moveItem(at: stagedSDKURL, to: sdkURL)

        await progress(.completed)
        return FlutterInstallationResult(sdkPath: sdkURL.path, version: artifact.version)
    }

    private func validatedParentDirectory(path: String) throws -> URL {
        let expanded = NSString(string: path).expandingTildeInPath
        let parentURL = URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
        var isDirectory: ObjCBool = false

        guard !expanded.isEmpty else {
            throw AppForgeError.validation(message: "Bitte wählen Sie einen Installationsordner für Flutter.")
        }
        guard !parentURL.path.contains(where: \.isWhitespace) else {
            throw AppForgeError.validation(
                message: "Der Flutter-Installationspfad darf keine Leerzeichen enthalten."
            )
        }

        let directoryExists = FileManager.default.fileExists(
            atPath: parentURL.path,
            isDirectory: &isDirectory
        )
        guard directoryExists, isDirectory.boolValue else {
            throw AppForgeError.fileSystem(message: "Der gewählte Installationsordner existiert nicht.")
        }
        guard FileManager.default.isWritableFile(atPath: parentURL.path) else {
            throw AppForgeError.fileSystem(
                message: "Der gewählte Installationsordner ist ohne erhöhte Rechte nicht beschreibbar."
            )
        }

        return parentURL
    }

    private func ensureInstallTargetIsAvailable(_ sdkURL: URL) throws {
        guard !FileManager.default.fileExists(atPath: sdkURL.path) else {
            throw AppForgeError.fileSystem(
                message: "Im gewählten Ordner existiert bereits ein Eintrag namens flutter."
            )
        }
    }

    private func makeStagingDirectory(in parentURL: URL) throws -> URL {
        let stagingURL = parentURL.appendingPathComponent(
            ".appforge-flutter-install-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: stagingURL,
            withIntermediateDirectories: false
        )
        return stagingURL
    }
}

public struct FlutterReleaseCatalogClient: FlutterReleaseCatalogProviding {
    private static let catalogURL = URL(
        string: "https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json"
    )!
    private static let allowedBaseURL = "https://storage.googleapis.com/flutter_infra_release/releases"

    public init() {}

    public func latestStable(
        for architecture: FlutterSDKArchitecture
    ) async throws -> FlutterReleaseArtifact {
        let (data, response) = try await URLSession.shared.data(from: Self.catalogURL)
        try validateHTTPResponse(response)

        let manifest = try JSONDecoder().decode(FlutterReleaseManifest.self, from: data)
        guard manifest.baseURL == Self.allowedBaseURL else {
            throw AppForgeError.configuration(
                message: "Das Flutter-Release-Manifest verwendet eine unerwartete Quelle."
            )
        }

        guard let release = manifest.releases.first(where: { candidate in
            candidate.hash == manifest.currentRelease.stable
                && candidate.channel == "stable"
                && candidate.dartSDKArchitecture == architecture.rawValue
        }) else {
            throw AppForgeError.configuration(
                message: "Für diese Mac-Architektur wurde kein aktuelles stabiles Flutter-SDK gefunden."
            )
        }

        try validateRelease(release)
        return FlutterReleaseArtifact(
            version: release.version,
            architecture: architecture,
            archivePath: release.archive,
            sha256: release.sha256.lowercased()
        )
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ..< 300).contains(httpResponse.statusCode),
              httpResponse.url?.host == "storage.googleapis.com"
        else {
            throw AppForgeError.configuration(
                message: "Das offizielle Flutter-Release-Manifest ist nicht erreichbar."
            )
        }
    }

    private func validateRelease(_ release: FlutterReleaseManifest.Release) throws {
        let isSafeArchive = release.archive.hasPrefix("stable/macos/")
            && release.archive.hasSuffix(".zip")
            && !release.archive.contains("..")
        let isSHA256 = release.sha256.count == 64
            && release.sha256.allSatisfy(\.isHexDigit)

        guard !release.version.isEmpty, isSafeArchive, isSHA256 else {
            throw AppForgeError.configuration(
                message: "Das Flutter-Release-Manifest enthält ungültige Artefaktdaten."
            )
        }
    }
}

public struct SystemFlutterArchiveDownloader: FlutterArchiveDownloading {
    private static let baseURL = URL(
        string: "https://storage.googleapis.com/flutter_infra_release/releases/"
    )!

    public init() {}

    public func download(_ artifact: FlutterReleaseArtifact) async throws -> URL {
        guard let url = URL(string: artifact.archivePath, relativeTo: Self.baseURL)?.absoluteURL,
              url.scheme == "https",
              url.host == "storage.googleapis.com"
        else {
            throw AppForgeError.configuration(message: "Die Flutter-Downloadadresse ist ungültig.")
        }

        let (temporaryURL, response) = try await URLSession.shared.download(from: url)
        try validateHTTPResponse(response)

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("appforge-flutter-\(UUID().uuidString).zip")
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ..< 300).contains(httpResponse.statusCode),
              httpResponse.url?.host == "storage.googleapis.com"
        else {
            throw AppForgeError.configuration(message: "Das Flutter-SDK konnte nicht heruntergeladen werden.")
        }
    }
}

public struct SHA256ArchiveChecksumVerifier: FlutterArchiveChecksumVerifying {
    public init() {}

    public func verify(fileURL: URL, expectedSHA256: String) throws -> Bool {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        var hasher = SHA256()
        while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty {
            hasher.update(data: data)
        }

        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        return digest.caseInsensitiveCompare(expectedSHA256) == .orderedSame
    }
}

public struct SystemFlutterArchiveExtractor: FlutterArchiveExtracting {
    public init() {}

    public func extract(archiveURL: URL, into parentDirectoryURL: URL) throws {
        let execution = try SystemCommand.run(
            executablePath: "/usr/bin/ditto",
            arguments: ["-x", "-k", archiveURL.path, parentDirectoryURL.path]
        )

        guard execution.exitCode == 0 else {
            throw AppForgeError.fileSystem(
                message: "Das Flutter-SDK konnte nicht entpackt werden: \(execution.output)"
            )
        }
    }
}

public struct SystemFlutterSDKValidator: FlutterSDKValidating {
    public init() {}

    public func validate(sdkURL: URL) throws {
        let executable = sdkURL.appendingPathComponent("bin/flutter").path
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            throw AppForgeError.fileSystem(
                message: "Die Installation enthält keine ausführbare Datei bin/flutter."
            )
        }

        let execution = try SystemCommand.run(executablePath: executable, arguments: ["--version"])
        guard execution.exitCode == 0 else {
            throw AppForgeError.configuration(
                message: "Das installierte Flutter SDK konnte nicht validiert werden: \(execution.output)"
            )
        }
    }
}

private enum HostFlutterArchitecture {
    static func current() throws -> FlutterSDKArchitecture {
        #if arch(arm64)
            return .arm64
        #elseif arch(x86_64)
            return .x64
        #else
            throw AppForgeError.configuration(message: "Diese Mac-Prozessorarchitektur wird noch nicht unterstützt.")
        #endif
    }
}

private struct FlutterReleaseManifest: Decodable {
    let baseURL: String
    let currentRelease: CurrentRelease
    let releases: [Release]

    enum CodingKeys: String, CodingKey {
        case baseURL = "base_url"
        case currentRelease = "current_release"
        case releases
    }

    struct CurrentRelease: Decodable {
        let stable: String
    }

    struct Release: Decodable {
        let hash: String
        let channel: String
        let version: String
        let dartSDKArchitecture: String
        let archive: String
        let sha256: String

        enum CodingKeys: String, CodingKey {
            case hash
            case channel
            case version
            case dartSDKArchitecture = "dart_sdk_arch"
            case archive
            case sha256
        }
    }
}

private enum SystemCommand {
    static func run(executablePath: String, arguments: [String]) throws -> CommandExecution {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = (String(data: data, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return CommandExecution(exitCode: process.terminationStatus, output: output)
    }
}

private struct CommandExecution {
    let exitCode: Int32
    let output: String
}
