import SwiftUI

enum AppDesign {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let twoXL: CGFloat = 48
        static let threeXL: CGFloat = 64
    }

    enum Radius {
        static let smallSize = CGSize(width: 6, height: 6)
        static let mediumSize = CGSize(width: 8, height: 8)
        static let largeSize = CGSize(width: 12, height: 12)
    }

    enum Layout {
        static let minimumWindowWidth: CGFloat = 920
        static let minimumWindowHeight: CGFloat = 580
        static let leftColumnMinimumWidth: CGFloat = 420
        static let leftColumnIdealWidth: CGFloat = 540
        static let rightColumnMinimumWidth: CGFloat = 320
        static let dropZoneMinimumHeight: CGFloat = 320
        static let footerHeight: CGFloat = 44
        static let minimumControlHeight: CGFloat = 44
    }
}
