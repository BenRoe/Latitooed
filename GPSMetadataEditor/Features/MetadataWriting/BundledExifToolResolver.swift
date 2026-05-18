import Foundation

struct BundledExifToolResolver: Sendable {
    enum ResolverError: Error, Equatable, Sendable {
        case missingHelper
        case helperNotExecutable(URL)
    }

    private let bundle: Bundle

    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
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
