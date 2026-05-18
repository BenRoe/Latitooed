import Foundation

nonisolated struct BundledExifToolResolver: Sendable {
    nonisolated enum ResolverError: Error, Equatable, Sendable {
        case missingHelper
        case helperNotExecutable(URL)
    }

    private let bundle: Bundle

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    static func mainBundle() -> BundledExifToolResolver {
        BundledExifToolResolver(bundle: Bundle.main)
    }

    func executableURL() throws -> URL {
        guard let url = bundle.url(forResource: "exiftool", withExtension: nil, subdirectory: "ExifTool") else {
            throw ResolverError.missingHelper
        }

        guard FileManager.default.isExecutableFile(atPath: url.path(percentEncoded: false)) else {
            throw ResolverError.helperNotExecutable(url)
        }

        return url
    }
}
