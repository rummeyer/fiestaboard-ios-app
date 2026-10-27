import SwiftUI

/// The look of Vestaboard's own app: a dark room, light cards with a soft glow,
/// letters spaced wide.
enum Style {
    static let background = Color(red: 0.125, green: 0.13, blue: 0.14)
    static let bar = Color(red: 0.07, green: 0.07, blue: 0.08)
    static let secondary = Color.white.opacity(0.5)
    static let live = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let ink = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let faint = Color(red: 0.45, green: 0.46, blue: 0.48)
    static let rule = Color.black.opacity(0.15)
    static let control = Color(red: 0.24, green: 0.25, blue: 0.27)
}

/// A light card, grey at the edges and white in the middle, with a shadow below.
struct CardBackground: ViewModifier {
    var radius: CGFloat = 6

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    LinearGradient(colors: [Color(white: 0.84), Color(white: 0.95)], startPoint: .top, endPoint: .bottom)
                    RadialGradient(colors: [Color.white.opacity(0.9), .clear], center: .bottom, startRadius: 10, endRadius: 260)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: .black.opacity(0.6), radius: 14, y: 12)
    }
}

extension View {
    func card(radius: CGFloat = 6) -> some View {
        modifier(CardBackground(radius: radius))
    }
}

/// The ribbon in a card's top right corner: dark for a favorite.
struct Ribbon: View {
    let filled: Bool

    var body: some View {
        RibbonShape()
            .fill(filled ? Style.ink : Color.black.opacity(0.08))
            .frame(width: 18, height: 26)
            .accessibilityLabel(filled ? "Favorite" : "Not a favorite")
    }
}

private struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width * 0.4))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// "3 days ago", "Just now".
func ago(_ date: Date) -> String {
    if Date.now.timeIntervalSince(date) < 60 {
        return "Just now"
    }
    return date.formatted(.relative(presentation: .named))
}
