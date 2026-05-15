import Testing
@testable import GPSMetadataEditor

struct FileIntakeSmokeTests {
    @Test func rootFileIntakeViewCanBeCreated() {
        let view = FileIntakeView()

        #expect(String(describing: type(of: view)) == "FileIntakeView")
    }
}
