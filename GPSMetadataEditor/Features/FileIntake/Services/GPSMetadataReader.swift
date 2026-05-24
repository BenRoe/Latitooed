import Foundation

nonisolated protocol GPSMetadataReading: Sendable {
    func gpsStatus(for file: SelectedMediaFile) async -> GPSStatus?
}

nonisolated struct ExifToolGPSMetadataReader: GPSMetadataReading {
    private let resolver: BundledExifToolResolver
    private let processRunner: any ProcessRunning

    init(
        resolver: BundledExifToolResolver = BundledExifToolResolver.mainBundle(),
        processRunner: any ProcessRunning = FoundationProcessRunner()
    ) {
        self.resolver = resolver
        self.processRunner = processRunner
    }

    func gpsStatus(for file: SelectedMediaFile) async -> GPSStatus? {
        do {
            let executableURL = try resolver.executableURL()
            let didStartAccess = file.url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    file.url.stopAccessingSecurityScopedResource()
                }
            }

            let result = try await processRunner.run(
                executableURL: executableURL,
                arguments: readArguments(for: file)
            )

            guard result.terminationStatus == 0,
                  let data = result.standardOutput.data(using: .utf8),
                  let record = try JSONDecoder().decode([ExifToolGPSRecord].self, from: data).first else {
                return nil
            }

            if let coordinate = record.coordinate {
                return .present(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }

            return .notPresent
        } catch {
            return nil
        }
    }

    private func readArguments(for file: SelectedMediaFile) -> [String] {
        [
            "-json",
            "-n",
            "-GPSLatitude",
            "-GPSLongitude",
            "-GPSPosition",
            "-Keys:GPSCoordinates",
            file.url.path(percentEncoded: false),
        ]
    }
}

nonisolated private struct ExifToolGPSRecord: Decodable {
    let gpsLatitude: Double?
    let gpsLongitude: Double?
    let gpsPosition: String?
    let gpsCoordinates: String?

    private enum CodingKeys: String, CodingKey {
        case gpsLatitude = "GPSLatitude"
        case gpsLongitude = "GPSLongitude"
        case gpsPosition = "GPSPosition"
        case gpsCoordinates = "GPSCoordinates"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gpsLatitude = container.flexibleDouble(forKey: .gpsLatitude)
        gpsLongitude = container.flexibleDouble(forKey: .gpsLongitude)
        gpsPosition = try container.decodeIfPresent(String.self, forKey: .gpsPosition)
        gpsCoordinates = try container.decodeIfPresent(String.self, forKey: .gpsCoordinates)
    }

    var coordinate: (latitude: Double, longitude: Double)? {
        if let gpsLatitude, let gpsLongitude {
            guard Self.isValid(latitude: gpsLatitude, longitude: gpsLongitude) else {
                return nil
            }

            return (gpsLatitude, gpsLongitude)
        }

        return Self.coordinatePair(in: gpsPosition) ?? Self.coordinatePair(in: gpsCoordinates)
    }

    private static func coordinatePair(in value: String?) -> (latitude: Double, longitude: Double)? {
        guard let value else {
            return nil
        }

        let spacedNumbers = value
            .replacing(",", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .compactMap { Double(String($0)) }

        if let pair = validPair(from: spacedNumbers) {
            return pair
        }

        return validPair(from: signedNumbers(in: value))
    }

    private static func signedNumbers(in value: String) -> [Double] {
        var numbers: [Double] = []
        var token = ""

        func appendToken() {
            guard token.isEmpty == false else {
                return
            }

            if let number = Double(token) {
                numbers.append(number)
            }

            token = ""
        }

        for character in value {
            if character == "+" || character == "-" {
                appendToken()
                token = String(character)
            } else if character.isNumber || character == "." || character == "e" || character == "E" {
                token.append(character)
            } else {
                appendToken()
            }
        }

        appendToken()
        return numbers
    }

    private static func validPair(from numbers: [Double]) -> (latitude: Double, longitude: Double)? {
        guard numbers.count >= 2,
              isValid(latitude: numbers[0], longitude: numbers[1]) else {
            return nil
        }

        return (numbers[0], numbers[1])
    }

    private static func isValid(latitude: Double, longitude: Double) -> Bool {
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
}

nonisolated private extension KeyedDecodingContainer {
    func flexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }

        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return nil
    }
}
