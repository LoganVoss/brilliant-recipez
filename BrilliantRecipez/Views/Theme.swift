import SwiftUI

enum Theme {
    static let green = Color(red: 0.09, green: 0.25, blue: 0.21)
    static let tint = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.90, green: 0.94, blue: 0.50, alpha: 1) : UIColor(red: 0.09, green: 0.25, blue: 0.21, alpha: 1) })
    static let cream = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor.systemGroupedBackground : UIColor(red: 0.98, green: 0.965, blue: 0.93, alpha: 1) })
    static let paper = Color(uiColor: .secondarySystemGroupedBackground)
    static let citrus = Color(red: 0.90, green: 0.94, blue: 0.50)
    static let muted = Color.secondary
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 17)
            .foregroundStyle(.white).background(Theme.green, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.caption.weight(.bold)).tracking(2) }
}

struct BowlArtwork: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Color(red: 0.91, green: 0.88, blue: 0.79))
                Circle().fill(.white).padding(size * 0.035)
                Circle().fill(Color(red: 0.95, green: 0.93, blue: 0.87)).padding(size * 0.13)
                ForEach(0..<14) { index in
                    Ellipse().fill(index.isMultiple(of: 3) ? Theme.green : Color(red: 0.39, green: 0.55, blue: 0.30))
                        .frame(width: size * 0.16, height: size * 0.32)
                        .rotationEffect(.degrees(Double(index) * 47))
                        .offset(x: cos(Double(index) * 2.4) * size * 0.22, y: sin(Double(index) * 2.4) * size * 0.22)
                }
                ForEach(0..<8) { index in
                    Circle().fill(Color(red: 0.80, green: 0.25, blue: 0.15))
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2).padding(4))
                        .frame(width: size * 0.16, height: size * 0.16)
                        .offset(x: cos(Double(index) * 2.5) * size * 0.23, y: sin(Double(index) * 2.5) * size * 0.19)
                }
                ForEach(0..<18) { index in
                    Circle().fill(Color(red: 0.88, green: 0.72, blue: 0.42))
                        .frame(width: size * 0.058, height: size * 0.058)
                        .offset(x: cos(Double(index) * 2.4) * size * Double(index % 5 + 1) * 0.052,
                                y: sin(Double(index) * 2.4) * size * Double(index % 4 + 1) * 0.05)
                }
            }.frame(width: size, height: size).frame(maxWidth: .infinity, maxHeight: .infinity)
        }.accessibilityHidden(true)
    }
}
