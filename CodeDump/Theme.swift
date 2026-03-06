import SwiftUI

// MARK: - Outrun Color Palette

extension Color {
    static let outrunBackground = Color(red: 36/255,  green: 23/255,  blue: 52/255)
    static let outrunSurface    = Color(red: 46/255,  green: 33/255,  blue: 70/255)
    static let outrunBlack      = Color(red: 13/255,  green: 2/255,   blue: 33/255)
    static let outrunCyan       = Color(red: 45/255,  green: 226/255, blue: 230/255)
    static let outrunGreen      = Color(red: 30/255,  green: 255/255, blue: 30/255)
    static let outrunYellow     = Color(red: 249/255, green: 200/255, blue: 14/255)
    static let outrunRed        = Color(red: 255/255, green: 56/255,  blue: 100/255)
    static let outrunOrange     = Color(red: 255/255, green: 108/255, blue: 17/255)
    static let outrunPink       = Color(red: 247/255, green: 6/255,   blue: 207/255)
    static let outrunPurple     = Color(red: 101/255, green: 13/255,  blue: 137/255)
}

// MARK: - Fonts

extension Font {
    static func outrunFuture(_ size: CGFloat) -> Font {
        .custom("OutrunFuture", size: size)
    }
    static func morningStar(_ size: CGFloat) -> Font {
        .custom("MorningStar", size: size)
    }
}

// MARK: - Navigation Bar

extension View {
    func outrunNavBar() -> some View {
        self
            .toolbarBackground(Color.outrunBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Time Formatting

extension Int {
    var formattedTime: String {
        let mins = self / 60
        let secs = self % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return String(format: "0:%02d", secs)
        }
    }

    var formattedTimeLong: String {
        let mins = self / 60
        let secs = self % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
