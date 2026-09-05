import AppForgeCore
import Darwin
import Foundation

public struct ToolchainCommandRequest: Equatable, Sendable {
    public let executablePath: String
    public let arguments: [String]
    public let workingDirectoryPath: String
    public let environment: [String: String]
    public let timeoutSeconds: TimeInterval

    public init(
        executablePath: String,
        arguments: [String],
        workingDirectoryPath: String,
        environment: [String: String],
        timeoutSeconds: TimeInterval
    ) {
        self.executablePath = executablePath
        self.arguments = arguments
        self.workingDirectoryPath = workingDirectoryPath
        self.environment = environment
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct ToolchainCommandResult: Equatable, Sendable {
    public let exitCode: Int32
    public let output: String
    public let timedOut: Bool

    public init(
        exitCode: Int32,
        output: String,
        timedOut: Bool
    ) {
        self.exitCode = exitCode
        self.output = output
        self.timedOut = timedOut
    }
}

public protocol ToolchainCommandRunning: Sendable {
    func run(_ request: ToolchainCommandRequest) throws -> ToolchainCommandResult
}

public struct SystemToolchainCommandRunner: ToolchainCommandRunning {
    private static let outputLimit = 65536

    public init() {}

    public func run(
        _ request: ToolchainCommandRequest
    ) throws -> ToolchainCommandResult {
        let executableURL = URL(fileURLWithPath: request.executablePath).standardizedFileURL
        let workingDirectoryURL = URL(
            fileURLWithPath: request.workingDirectoryPath,
            isDirectory: true
        ).standardizedFileURL

        guard executableURL.path.hasPrefix("/"),
              FileManager.default.isExecutableFile(atPath: executableURL.path)
        else {
            throw AppForgeError.configuration(
                message: "Das angeforderte Toolchain-Programm ist nicht ausführbar."
            )
        }

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: workingDirectoryURL.path,
            isDirectory: &isDirectory
        )
        guard exists, isDirectory.boolValue else {
            throw AppForgeError.fileSystem(
                message: "Das Arbeitsverzeichnis für den Toolchain-Prozess existiert nicht."
            )
        }

        let capture = try BoundedToolchainOutputCapture()
        let process = Process()
        process.executableURL = executableURL
        process.arguments = request.arguments
        process.currentDirectoryURL = workingDirectoryURL
        process.environment = request.environment
        capture.attach(to: process)

        do {
            try process.run()
            let timedOut = waitForProcess(
                process,
                timeoutSeconds: request.timeoutSeconds
            )
            let output = try capture.finish(limit: Self.outputLimit)
            return ToolchainCommandResult(
                exitCode: process.terminationStatus,
                output: output,
                timedOut: timedOut
            )
        } catch {
            capture.cleanup()
            throw error
        }
    }

    private func waitForProcess(
        _ process: Process,
        timeoutSeconds: TimeInterval
    ) -> Bool {
        let timeout = max(timeoutSeconds, 0.1)
        let deadline = Date().addingTimeInterval(timeout)

        while process.isRunning, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        guard process.isRunning else {
            process.waitUntilExit()
            return false
        }

        process.terminate()
        let terminationDeadline = Date().addingTimeInterval(1)

        while process.isRunning, Date() < terminationDeadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if process.isRunning {
            _ = Darwin.kill(process.processIdentifier, SIGKILL)
        }

        process.waitUntilExit()
        return true
    }
}

private final class BoundedToolchainOutputCapture {
    private let outputURL: URL
    private var outputHandle: FileHandle?

    init() throws {
        outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "appforge-toolchain-output-\(UUID().uuidString).log"
        )
        guard FileManager.default.createFile(
            atPath: outputURL.path,
            contents: nil
        ) else {
            throw AppForgeError.fileSystem(
                message: "Temporäre Toolchain-Ausgabe konnte nicht angelegt werden."
            )
        }
        outputHandle = try FileHandle(forWritingTo: outputURL)
    }

    func attach(to process: Process) {
        process.standardOutput = outputHandle
        process.standardError = outputHandle
    }

    func finish(limit: Int) throws -> String {
        try closeHandle()

        let input = try FileHandle(forReadingFrom: outputURL)
        defer { try? input.close() }

        let length = try input.seekToEnd()
        let maximum = UInt64(max(limit, 1))
        let truncated = length > maximum
        if truncated {
            try input.seek(toOffset: length - maximum)
        } else {
            try input.seek(toOffset: 0)
        }

        let data = try input.readToEnd() ?? Data()
        try removeOutputFile()

        let decoded = String(decoding: data, as: UTF8.self)
        let sanitized = sanitize(decoded)
        return truncated
            ? "[output truncated]\n" + sanitized
            : sanitized
    }

    func cleanup() {
        try? closeHandle()
        try? removeOutputFile()
    }

    private func closeHandle() throws {
        guard let outputHandle else {
            return
        }
        try outputHandle.close()
        self.outputHandle = nil
    }

    private func removeOutputFile() throws {
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: outputURL)
    }

    private func sanitize(_ value: String) -> String {
        let withoutANSI = value.replacingOccurrences(
            of: "\u{001B}\\[[0-9;?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
        var sanitized = ""

        for scalar in withoutANSI.unicodeScalars {
            let allowedControl = scalar.value == 9
                || scalar.value == 10
                || scalar.value == 13
            if allowedControl || scalar.value >= 32 {
                sanitized.unicodeScalars.append(scalar)
            }
        }

        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
