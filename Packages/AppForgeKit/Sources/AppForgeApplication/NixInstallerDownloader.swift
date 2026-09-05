import AppForgeDomain
import Foundation

public struct NixInstallerDownload: Equatable, Sendable {
    public let data: Data
    public let responseURL: URL
    public let statusCode: Int

    public init(
        data: Data,
        responseURL: URL,
        statusCode: Int
    ) {
        self.data = data
        self.responseURL = responseURL
        self.statusCode = statusCode
    }
}

public protocol NixInstallerDownloading: Sendable {
    func download(from url: URL) async throws -> NixInstallerDownload
}

public struct URLSessionNixInstallerDownloader: NixInstallerDownloading {
    public init() {}

    public func download(
        from url: URL
    ) async throws -> NixInstallerDownload {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse,
              let finalURL = http.url
        else {
            throw NixBootstrapError.unexpectedResponseURL
        }

        return NixInstallerDownload(
            data: data,
            responseURL: finalURL,
            statusCode: http.statusCode
        )
    }
}
