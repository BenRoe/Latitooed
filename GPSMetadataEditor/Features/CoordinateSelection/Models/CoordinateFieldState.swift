import Foundation

enum CoordinateFieldKind: Sendable {
    case latitude
    case longitude

    var validationMessage: String {
        switch self {
        case .latitude:
            "Latitude must be between -90 and 90."
        case .longitude:
            "Longitude must be between -180 and 180."
        }
    }

    func isValid(_ value: Double) -> Bool {
        switch self {
        case .latitude:
            CoordinateSelection.isValidLatitude(value)
        case .longitude:
            CoordinateSelection.isValidLongitude(value)
        }
    }
}

struct CoordinateFieldState: Equatable, Sendable {
    var text: String
    var value: Double?
    var validationMessage: String?

    var isValid: Bool {
        validationMessage == nil
    }

    init(text: String = "", kind: CoordinateFieldKind) {
        self.text = text
        self.value = nil
        self.validationMessage = nil
        update(text, kind: kind)
    }

    mutating func update(_ newText: String, kind: CoordinateFieldKind) {
        text = newText

        let trimmedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else {
            value = nil
            validationMessage = nil
            return
        }

        guard let parsedValue = Double(trimmedText), kind.isValid(parsedValue) else {
            value = nil
            validationMessage = kind.validationMessage
            return
        }

        value = parsedValue
        validationMessage = nil
    }

    mutating func sync(with value: Double) {
        text = value.formatted(.number.precision(.fractionLength(6)))
        self.value = value
        validationMessage = nil
    }
}
