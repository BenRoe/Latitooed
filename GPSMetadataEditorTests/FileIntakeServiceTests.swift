import Foundation
import Testing
@testable import GPSMetadataEditor

struct FileIntakeServiceTests {
    @Test(
        "Media file kinds are recognized case-insensitively",
        arguments: [
            ("photo.jpg", MediaFileKind.jpeg),
            ("photo.JPEG", MediaFileKind.jpeg),
            ("photo.HeIc", MediaFileKind.heic),
            ("clip.MOV", MediaFileKind.mov),
            ("clip.mP4", MediaFileKind.mp4),
        ]
    )
    func mediaFileKindRecognizesSupportedExtensions(filename: String, expectedKind: MediaFileKind) {
        #expect(MediaFileKind(filename: filename) == expectedKind)
    }

    @Test func selectedMediaFileStoresOriginalSnapshotValues() {
        let url = URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC")
        let file = SelectedMediaFile(url: url, kind: .heic)

        #expect(file.id == url)
        #expect(file.url == url)
        #expect(file.displayName == "IMG 001.HEIC")
        #expect(file.kind == .heic)
        #expect(file.gpsStatus == .notChecked)
        #expect(file.latestResult == .pending)
        #expect(file.containingFolderURL == URL(filePath: "/Volumes/Photos/Trip", directoryHint: .isDirectory))
    }

    @Test(
        "Warning reasons cover every file-intake rejection",
        arguments: [
            IntakeWarning.Reason.unsupported,
            .directory,
            .missing,
            .inaccessible,
            .readOnly,
            .locked,
            .duplicate,
        ]
    )
    func warningReasonsCoverRejectedInput(reason: IntakeWarning.Reason) {
        let warning = IntakeWarning(filename: "example.txt", url: nil, reason: reason)

        #expect(warning.reason == reason)
        #expect(warning.message.isEmpty == false)
    }

    @Test func supportedFileURLsWithSpacesAndUnicodeAreAcceptedWithoutChangingURLs() throws {
        let directory = try temporaryDirectory()
        let spacedURL = directory.appending(path: "summer trip 01.JPG")
        let unicodeURL = directory.appending(path: "München 雪.HEIC")
        try Data().write(to: spacedURL)
        try Data().write(to: unicodeURL)

        let result = FileIntakeService().intake(urls: [spacedURL, unicodeURL], currentSelection: [])

        #expect(result.accepted.map(\.url) == [spacedURL, unicodeURL])
        #expect(result.accepted.map(\.displayName) == ["summer trip 01.JPG", "München 雪.HEIC"])
        #expect(result.accepted.map(\.kind) == [.jpeg, .heic])
        #expect(result.warnings.isEmpty)
    }

    @Test func unsupportedFilesAndDirectoriesAreRejected() throws {
        let directory = try temporaryDirectory()
        let unsupportedURL = directory.appending(path: "notes.txt")
        let childDirectory = directory.appending(path: "Nested", directoryHint: .isDirectory)
        try Data().write(to: unsupportedURL)
        try FileManager.default.createDirectory(at: childDirectory, withIntermediateDirectories: false)

        let result = FileIntakeService().intake(urls: [unsupportedURL, childDirectory], currentSelection: [])

        #expect(result.accepted.isEmpty)
        #expect(result.warnings.map(\.reason) == [.unsupported, .directory])
        #expect(result.warnings.map(\.filename) == ["notes.txt", "Nested"])
    }

    @Test func duplicateURLsProduceOneWarningAndNoDuplicateSnapshot() throws {
        let directory = try temporaryDirectory()
        let url = directory.appending(path: "clip.MOV")
        try Data().write(to: url)

        let result = FileIntakeService().intake(urls: [url, url], currentSelection: [])

        #expect(result.accepted.map(\.url) == [url])
        #expect(result.warnings.map(\.reason) == [.duplicate])
    }

    @Test func missingFilesProduceWarningRecords() throws {
        let missingURL = try temporaryDirectory().appending(path: "missing.mp4")

        let result = FileIntakeService().intake(urls: [missingURL], currentSelection: [])

        #expect(result.accepted.isEmpty)
        #expect(result.warnings.map(\.reason) == [.missing])
    }

    @Test func readOnlyFilesProduceWarningRecords() throws {
        let url = try temporaryDirectory().appending(path: "readonly.jpeg")
        try Data().write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: url.path(percentEncoded: false))
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path(percentEncoded: false))
        }

        let result = FileIntakeService().intake(urls: [url], currentSelection: [])

        #expect(result.accepted.isEmpty)
        #expect(result.warnings.map(\.reason) == [.readOnly])
    }

    @Test func lockedFilesProduceWarningRecords() throws {
        var url = try temporaryDirectory().appending(path: "locked.mp4")
        try Data().write(to: url)
        var values = URLResourceValues()
        values.isUserImmutable = true
        try url.setResourceValues(values)
        defer {
            var values = URLResourceValues()
            values.isUserImmutable = false
            try? url.setResourceValues(values)
        }

        let result = FileIntakeService().intake(urls: [url], currentSelection: [])

        #expect(result.accepted.isEmpty)
        #expect(result.warnings.map(\.reason) == [.locked])
    }

    private func temporaryDirectory() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
