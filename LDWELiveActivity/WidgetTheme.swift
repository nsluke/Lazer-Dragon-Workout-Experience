import SwiftUI

// MARK: - Outrun Color Palette (Widget Extension)

/// Mirrors the main app's Theme.swift colors for use in widget views.
/// Widget extensions can't share source files from the main app's synchronized groups,
/// so we duplicate the palette here.
extension Color {
    static let widgetBackground = Color(red: 36/255,  green: 23/255,  blue: 52/255)
    static let widgetSurface    = Color(red: 46/255,  green: 33/255,  blue: 70/255)
    static let widgetBlack      = Color(red: 13/255,  green: 2/255,   blue: 33/255)
    static let widgetCyan       = Color(red: 45/255,  green: 226/255, blue: 230/255)
    static let widgetGreen      = Color(red: 30/255,  green: 255/255, blue: 30/255)
    static let widgetYellow     = Color(red: 249/255, green: 200/255, blue: 14/255)
    static let widgetRed        = Color(red: 255/255, green: 56/255,  blue: 100/255)
    static let widgetOrange     = Color(red: 255/255, green: 108/255, blue: 17/255)
    static let widgetPink       = Color(red: 247/255, green: 6/255,   blue: 207/255)
    static let widgetPurple     = Color(red: 101/255, green: 13/255,  blue: 137/255)
}

// MARK: - Fonts

extension Font {
    static func widgetOutrun(_ size: CGFloat) -> Font {
        .custom("Audiowide-Regular", size: size)
    }
}

// MARK: - Widget Backgrounds

struct OutrunWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.widgetBlack, Color.widgetBackground],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Glow Modifier

extension View {
    func neonGlow(_ color: Color, radius: CGFloat = 6) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius)
    }
}
