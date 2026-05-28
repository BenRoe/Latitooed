import SwiftUI
import Testing
@testable import Latitooed

struct FileIntakeSmokeTests {
    @Test func rootFileIntakeViewCanBeCreated() {
        let view = FileIntakeView()

        #expect(String(describing: type(of: view)) == "FileIntakeView")
    }

    @Test func selectedFilesGridCanBeCreated() {
        let view = SelectedFilesGrid(files: [], selection: .constant([]), activateFile: { _, _ in }, thumbnailSize: .medium)

        #expect(String(describing: type(of: view)) == "SelectedFilesGrid")
    }

    @Test func fileDetailPanelCanBeCreated() {
        let view = FileDetailPanel(review: .none, latestWarnings: [])

        #expect(String(describing: type(of: view)) == "FileDetailPanel")
    }

    @Test func designConstantsReserveUtilityWindowSpace() {
        #expect(AppDesign.Layout.leftColumnMinimumWidth >= 420)
        #expect(AppDesign.Layout.rightColumnMinimumWidth >= 320)
        #expect(AppDesign.Layout.footerHeight <= 48)
    }
}
