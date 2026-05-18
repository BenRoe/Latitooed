import Foundation
import Testing
@testable import GPSMetadataEditor

struct ExifToolMetadataWriterTests {
    @Test func missingHelperMapsToStructuredFailure() async throws {
        let bundle = try emptyBundle()
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/IMG_0001.jpg"), kind: .jpeg)
        let coordinate = CoordinateSelection.berlin
        let writer = ExifToolMetadataWriter(resolver: BundledExifToolResolver(bundle: bundle), processRunner: RecordingRunner())

        let result = await writer.writeGPS(coordinate, to: file)

        #expect(result.status == .failure)
        #expect(result.message == "Bundled ExifTool helper is missing.")
    }

    @Test func nonExecutableHelperMapsToStructuredFailure() async throws {
        let bundle = try bundleWithHelper(isExecutable: false)
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/IMG_0001.jpg"), kind: .jpeg)
        let writer = ExifToolMetadataWriter(resolver: BundledExifToolResolver(bundle: bundle), processRunner: RecordingRunner())

        let result = await writer.writeGPS(.berlin, to: file)

        #expect(result.status == .failure)
        #expect(result.message == "Bundled ExifTool helper is not executable.")
    }

    @Test func resolverUsesOnlyBundleResourceHelper() async throws {
        let bundle = try bundleWithHelper(isExecutable: true)
        let resolvedURL = try BundledExifToolResolver(bundle: bundle).executableURL()

        #expect(resolvedURL.path(percentEncoded: false).hasSuffix("/ExifTool/exiftool"))
    }

    @Test func jpegSuccessMapsToSuccessUpdatedGPSAndPreservesDiagnostics() async throws {
        let bundle = try bundleWithHelper(isExecutable: true)
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/IMG_0001.jpg"), kind: .jpeg)
        let runner = RecordingRunner(result: ProcessResult(terminationStatus: 0, standardOutput: "ok", standardError: "minor note"))
        let writer = ExifToolMetadataWriter(resolver: BundledExifToolResolver(bundle: bundle), processRunner: runner)

        let result = await writer.writeGPS(.berlin, to: file)

        #expect(result.status == .success)
        #expect(result.gpsStatus == .updated)
        #expect(result.diagnosticDetail?.contains("ok") == true)
        #expect(result.diagnosticDetail?.contains("minor note") == true)
        #expect(await runner.calls.count == 1)
    }

    @Test func heicSuccessFollowsStillImagePath() async throws {
        let bundle = try bundleWithHelper(isExecutable: true)
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/IMG_0002.heic"), kind: .heic)
        let runner = RecordingRunner()
        let writer = ExifToolMetadataWriter(resolver: BundledExifToolResolver(bundle: bundle), processRunner: runner)

        let result = await writer.writeGPS(.berlin, to: file)

        #expect(result.status == .success)
        #expect(result.gpsStatus == .updated)
        #expect(await runner.calls.count == 1)
    }

    @Test(
        "Videos return warnings without invoking the runner",
        arguments: [
            MediaFileKind.mov,
            .mp4,
        ]
    )
    func videoWarningsDoNotInvokeRunner(kind: MediaFileKind) async throws {
        let bundle = try bundleWithHelper(isExecutable: true)
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/video.\(kind.rawValue)"), kind: kind)
        let runner = RecordingRunner()
        let writer = ExifToolMetadataWriter(resolver: BundledExifToolResolver(bundle: bundle), processRunner: runner)

        let result = await writer.writeGPS(.berlin, to: file)

        #expect(result.status == .warning)
        #expect(result.message == "Video metadata writing is deferred to Phase 4.")
        #expect(await runner.calls.isEmpty)
    }

    @Test func nonzeroExitMapsToFailureWithDiagnostics() async throws {
        let bundle = try bundleWithHelper(isExecutable: true)
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/IMG_0001.jpg"), kind: .jpeg)
        let runner = RecordingRunner(result: ProcessResult(terminationStatus: 1, standardOutput: "out", standardError: "bad gps"))
        let writer = ExifToolMetadataWriter(resolver: BundledExifToolResolver(bundle: bundle), processRunner: runner)

        let result = await writer.writeGPS(.berlin, to: file)

        #expect(result.status == .failure)
        #expect(result.diagnosticDetail?.contains("bad gps") == true)
        #expect(result.diagnosticDetail?.contains("Exit status: 1") == true)
    }

    private func emptyBundle() throws -> Bundle {
        let bundleURL = URL.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        return try #require(Bundle(path: bundleURL.path(percentEncoded: false)))
    }

    private func bundleWithHelper(isExecutable: Bool) throws -> Bundle {
        let bundleURL = URL.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let helperDirectoryURL = bundleURL.appending(path: "ExifTool", directoryHint: .isDirectory)
        let helperURL = helperDirectoryURL.appending(path: "exiftool")
        try FileManager.default.createDirectory(at: helperDirectoryURL, withIntermediateDirectories: true)
        try "#!/usr/bin/perl\n".write(to: helperURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: isExecutable ? 0o755 : 0o644],
            ofItemAtPath: helperURL.path(percentEncoded: false)
        )
        return try #require(Bundle(path: bundleURL.path(percentEncoded: false)))
    }
}

private actor RecordingRunner: ProcessRunning {
    struct Call: Equatable {
        let executableURL: URL
        let arguments: [String]
    }

    private(set) var calls: [Call] = []
    private let result: ProcessResult

    init(result: ProcessResult = ProcessResult(terminationStatus: 0, standardOutput: "", standardError: "")) {
        self.result = result
    }

    func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult {
        calls.append(Call(executableURL: executableURL, arguments: arguments))
        return result
    }
}
