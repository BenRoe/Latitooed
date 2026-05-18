import Foundation
import UniformTypeIdentifiers

nonisolated struct FileIntakeService: Sendable {
    func intake(urls: [URL], currentSelection: [SelectedMediaFile]) -> FileIntakeResult {
        var accepted: [SelectedMediaFile] = []
        var warnings: [IntakeWarning] = []
        var seenURLs = Set(currentSelection.map(\.url))

        for url in urls {
            let filename = displayName(for: url)

            guard seenURLs.contains(url) == false else {
                warnings.append(IntakeWarning(filename: filename, url: url, reason: .duplicate))
                continue
            }

            switch classify(url: url) {
            case .accepted(let kind):
                let file = SelectedMediaFile(url: url, kind: kind)
                accepted.append(file)
                seenURLs.insert(url)
            case .rejected(let reason):
                warnings.append(IntakeWarning(filename: filename, url: url, reason: reason))
            }
        }

        return FileIntakeResult(accepted: accepted, warnings: warnings)
    }

    private func classify(url: URL) -> Classification {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let values: URLResourceValues
        do {
            guard try url.checkResourceIsReachable() else {
                return .rejected(.missing)
            }
            values = try url.resourceValues(forKeys: Self.resourceKeys)
        } catch {
            return missingReason(for: url)
        }

        if values.isDirectory == true {
            return .rejected(.directory)
        }

        if values.isReadable == false {
            return .rejected(.inaccessible)
        }

        if values.isUserImmutable == true {
            return .rejected(.locked)
        }

        if values.isWritable == false {
            return .rejected(.readOnly)
        }

        if let contentType = values.contentType, let kind = MediaFileKind(contentType: contentType) {
            return .accepted(kind)
        }

        if let kind = MediaFileKind(fileExtension: url.pathExtension) {
            return .accepted(kind)
        }

        return .rejected(.unsupported)
    }

    private func missingReason(for url: URL) -> Classification {
        do {
            return try url.checkResourceIsReachable() ? .rejected(.inaccessible) : .rejected(.missing)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return .rejected(.missing)
        } catch {
            return .rejected(.inaccessible)
        }
    }

    private func displayName(for url: URL) -> String {
        let name = url.lastPathComponent
        return name.isEmpty ? url.absoluteString : name
    }

    private static let resourceKeys: Set<URLResourceKey> = [
        .contentTypeKey,
        .isDirectoryKey,
        .isReadableKey,
        .isUserImmutableKey,
        .isWritableKey,
    ]
}

nonisolated private enum Classification {
    case accepted(MediaFileKind)
    case rejected(IntakeWarning.Reason)
}
