import Foundation
import Testing
@testable import GPSMetadataEditor

struct ProcessRunnerTests {
    @Test func launchFailureThrowsProcessError() async {
        await #expect(throws: (any Error).self) {
            try await FoundationProcessRunner().run(
                executableURL: URL(filePath: "/tmp/not-a-real-process-\(UUID().uuidString)"),
                arguments: []
            )
        }
    }
}
