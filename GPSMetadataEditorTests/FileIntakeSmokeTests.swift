import SwiftUI
import Testing
@testable import GPSMetadataEditor

struct FileIntakeSmokeTests {
    @Test func rootFileIntakeViewCanBeCreated() {
        let view = FileIntakeView()

        #expect(String(describing: type(of: view)) == "FileIntakeView")
    }

    @Test func selectedFilesGridCanBeCreated() {
        let view = SelectedFilesGrid(files: [], selection: .constant([])) { _, _ in }

        #expect(String(describing: type(of: view)) == "SelectedFilesGrid")
    }

    @Test func designConstantsReserveUtilityWindowSpace() {
        #expect(AppDesign.Layout.leftColumnMinimumWidth >= 420)
        #expect(AppDesign.Layout.rightColumnMinimumWidth >= 320)
        #expect(AppDesign.Layout.footerHeight <= 48)
    }
}
