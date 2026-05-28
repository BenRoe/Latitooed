import Foundation
import Testing
@testable import GPSMetadataEditor

struct ProcessRunnerTests {
    @Test func launchFailureThrowsCocoaError() async {
        do {
            try await FoundationProcessRunner().run(
                executableURL: URL(filePath: "/tmp/not-a-real-process-\(UUID().uuidString)"),
                arguments: []
            )
            Issue.record("Expected launch to throw but it did not.")
        } catch is CocoaError {
            // expected — process launch failed with CocoaError
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
