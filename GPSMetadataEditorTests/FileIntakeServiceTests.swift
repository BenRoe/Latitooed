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
}
