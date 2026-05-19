import Foundation

nonisolated struct ExifToolMetadataWriter: MetadataWriter {
    private let resolver: BundledExifToolResolver
    private let argumentBuilder: ExifToolArgumentBuilder
    private let processRunner: any ProcessRunning

    init(
        resolver: BundledExifToolResolver = BundledExifToolResolver.mainBundle(),
        argumentBuilder: ExifToolArgumentBuilder = ExifToolArgumentBuilder(),
        processRunner: any ProcessRunning = FoundationProcessRunner()
    ) {
        self.resolver = resolver
        self.argumentBuilder = argumentBuilder
        self.processRunner = processRunner
    }

    func writeGPS(_ coordinate: CoordinateSelection, to file: SelectedMediaFile) async -> MetadataWriteResult {
        await writeMetadataGPS(coordinate, to: file)
    }

    private func writeMetadataGPS(_ coordinate: CoordinateSelection, to file: SelectedMediaFile) async -> MetadataWriteResult {
        do {
            let executableURL = try resolver.executableURL()
            let arguments = try argumentBuilder.gpsWriteArguments(for: file, coordinate: coordinate)
            let didStartAccess = file.url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    file.url.stopAccessingSecurityScopedResource()
                }
            }

            let result = try await processRunner.run(executableURL: executableURL, arguments: arguments)
            let diagnostics = diagnosticDetail(for: result)

            guard result.terminationStatus == 0 else {
                return .failure(
                    for: file,
                    message: "GPS metadata could not be written.",
                    diagnosticDetail: diagnostics
                )
            }

            return .success(
                for: file,
                message: "GPS metadata updated.",
                diagnosticDetail: diagnostics
            )
        } catch let error as BundledExifToolResolver.ResolverError {
            return .failure(
                for: file,
                message: helperMessage(for: error),
                diagnosticDetail: String(describing: error)
            )
        } catch {
            return .failure(
                for: file,
                message: "GPS metadata could not be written.",
                diagnosticDetail: error.localizedDescription
            )
        }
    }

    private func diagnosticDetail(for result: ProcessResult) -> String? {
        [
            "Exit status: \(result.terminationStatus)",
            result.standardOutput.isEmpty ? nil : "stdout: \(result.standardOutput)",
            result.standardError.isEmpty ? nil : "stderr: \(result.standardError)",
        ]
        .compactMap(\.self)
        .joined(separator: "\n")
    }

    private func helperMessage(for error: BundledExifToolResolver.ResolverError) -> String {
        switch error {
        case .missingHelper:
            "Bundled ExifTool helper is missing."
        case .helperNotExecutable:
            "Bundled ExifTool helper is not executable."
        }
    }
}
