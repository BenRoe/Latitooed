import UniformTypeIdentifiers

enum MediaFileKind: String, CaseIterable, Sendable {
    case jpeg
    case heic
    case mov
    case mp4

    init?(filename: String) {
        self.init(fileExtension: URL(filePath: filename).pathExtension)
    }

    init?(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            self = .jpeg
        case "heic":
            self = .heic
        case "mov":
            self = .mov
        case "mp4":
            self = .mp4
        default:
            return nil
        }
    }

    init?(contentType: UTType) {
        if contentType.conforms(to: .jpeg) {
            self = .jpeg
        } else if contentType.conforms(to: .heic) {
            self = .heic
        } else if contentType.conforms(to: .quickTimeMovie) {
            self = .mov
        } else if contentType.conforms(to: .mpeg4Movie) {
            self = .mp4
        } else {
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .jpeg:
            "JPEG"
        case .heic:
            "HEIC"
        case .mov:
            "MOV"
        case .mp4:
            "MP4"
        }
    }
}
