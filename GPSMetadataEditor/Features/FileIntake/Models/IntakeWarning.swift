import Foundation

struct IntakeWarning: Identifiable, Hashable, Sendable {
    enum Reason: String, CaseIterable, Sendable {
        case unsupported
        case directory
        case missing
        case inaccessible
        case readOnly
        case locked
        case duplicate
    }

    let id: UUID
    let filename: String
    let url: URL?
    let reason: Reason
    let message: String

    init(filename: String, url: URL?, reason: Reason, id: UUID = UUID()) {
        self.id = id
        self.filename = filename
        self.url = url
        self.reason = reason
        self.message = Self.message(filename: filename, reason: reason)
    }

    private static func message(filename: String, reason: Reason) -> String {
        switch reason {
        case .unsupported:
            "\"\(filename)\" is not a supported media file. Add JPEG, HEIC, MOV, or MP4 files."
        case .directory:
            "\"\(filename)\" is a folder. Add individual media files for now."
        case .missing:
            "\"\(filename)\" could not be found. Choose the file again from Finder."
        case .inaccessible:
            "\"\(filename)\" could not be accessed. Check permissions or choose another copy."
        case .readOnly:
            "\"\(filename)\" is read-only. Choose a writable copy before editing metadata."
        case .locked:
            "\"\(filename)\" is locked. Unlock it in Finder before adding it."
        case .duplicate:
            "\"\(filename)\" is already in the selected file set."
        }
    }
}
