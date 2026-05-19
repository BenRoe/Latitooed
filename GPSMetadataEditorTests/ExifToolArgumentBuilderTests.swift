import Foundation
import Testing
@testable import GPSMetadataEditor

struct ExifToolArgumentBuilderTests {
    @Test func jpegArgumentsUseOverwriteGPSPositionAndFinalPath() throws {
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/IMG_0001.jpg"), kind: .jpeg)
        let coordinate = try #require(CoordinateSelection(latitude: 52.52, longitude: 13.405))

        let arguments = try ExifToolArgumentBuilder().gpsWriteArguments(for: file, coordinate: coordinate)

        #expect(arguments == [
            "-overwrite_original",
            "-gpsposition=52.52, 13.405",
            "/Volumes/Photos/IMG_0001.jpg",
        ])
    }

    @Test func heicArgumentsUseSameGPSPositionStrategy() throws {
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/IMG_0002.heic"), kind: .heic)
        let coordinate = try #require(CoordinateSelection(latitude: 48.137154, longitude: 11.576124))

        let arguments = try ExifToolArgumentBuilder().gpsWriteArguments(for: file, coordinate: coordinate)

        #expect(arguments == [
            "-overwrite_original",
            "-gpsposition=48.137154, 11.576124",
            "/Volumes/Photos/IMG_0002.heic",
        ])
    }

    @Test func signedCoordinatesRemainSignedInGPSPosition() throws {
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/south-west.jpeg"), kind: .jpeg)
        let coordinate = try #require(CoordinateSelection(latitude: -33.8688, longitude: -151.2093))

        let arguments = try ExifToolArgumentBuilder().gpsWriteArguments(for: file, coordinate: coordinate)

        #expect(arguments[1] == "-gpsposition=-33.8688, -151.2093")
    }

    @Test func pathWithSpacesUnicodeAndShellCharactersStaysOneArgument() throws {
        let path = "/Volumes/Trip Photos/München 雪; rm -rf nope/IMG 1 & 2.HEIC"
        let file = SelectedMediaFile(url: URL(filePath: path), kind: .heic)
        let coordinate = try #require(CoordinateSelection(latitude: 52.520008, longitude: 13.404954))

        let arguments = try ExifToolArgumentBuilder().gpsWriteArguments(for: file, coordinate: coordinate)

        #expect(arguments.count == 3)
        #expect(arguments.last == path)
    }

    @Test(
        "Video files use QuickTime Keys GPS coordinates",
        arguments: [
            MediaFileKind.mov,
            .mp4,
        ]
    )
    func videoFilesUseKeysGPSCoordinates(kind: MediaFileKind) throws {
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/video.\(kind.rawValue)"), kind: kind)
        let coordinate = try #require(CoordinateSelection(latitude: 52.520008, longitude: 13.404954))

        let arguments = try ExifToolArgumentBuilder().gpsWriteArguments(for: file, coordinate: coordinate)

        #expect(arguments == [
            "-overwrite_original",
            "-Keys:GPSCoordinates=52.520008, 13.404954",
            "/Volumes/Photos/video.\(kind.rawValue)",
        ])
    }

    @Test func videoPathWithSpacesUnicodeAndShellCharactersStaysOneArgument() throws {
        let path = "/Volumes/Trip Photos/München 雪; rm -rf nope/video 1 & 2.MOV"
        let file = SelectedMediaFile(url: URL(filePath: path), kind: .mov)
        let coordinate = try #require(CoordinateSelection(latitude: -33.8688, longitude: -151.2093))

        let arguments = try ExifToolArgumentBuilder().gpsWriteArguments(for: file, coordinate: coordinate)

        #expect(arguments.count == 3)
        #expect(arguments[1] == "-Keys:GPSCoordinates=-33.8688, -151.2093")
        #expect(arguments.last == path)
    }
}
