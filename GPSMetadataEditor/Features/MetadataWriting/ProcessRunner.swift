import Foundation

nonisolated struct ProcessResult: Equatable, Sendable {
    let terminationStatus: Int32
    let standardOutput: String
    let standardError: String
}

nonisolated protocol ProcessRunning: Sendable {
    func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult
}

nonisolated struct FoundationProcessRunner: ProcessRunning {
    func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult {
        let process = Process()
        let standardOutput = Pipe()
        let standardError = Pipe()

        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = standardOutput
        process.standardError = standardError

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { terminatedProcess in
                    let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
                    let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(
                        returning: ProcessResult(
                            terminationStatus: terminatedProcess.terminationStatus,
                            standardOutput: String(decoding: outputData, as: UTF8.self),
                            standardError: String(decoding: errorData, as: UTF8.self)
                        )
                    )
                }

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            process.terminate()
        }
    }
}
