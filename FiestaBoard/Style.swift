import SwiftUI

/// FiestaBoard's own look, from its web UI's theme (`@fiestaboard/ui`): warm
/// beige or warm near-black, cards a step lighter with a hairline edge, the
/// FiestaBoard orange for whatever is primary or chosen, Archivo for words
/// and Spline Sans Mono for the board. Light and dark follow the iPhone.
enum Style {
    static let background = Color("Background")
    static let card = Color("Card")
    static let ink = Color("Ink")
    static let muted = Color("Muted")
    /// A quiet fill: a control's or a chip's.
    static let fill = Color("Secondary")
    /// FiestaBoard orange, the same in both themes, with board ink on it.
    static let primary = Color("Primary")
    static let primaryInk = Color("PrimaryInk")
    static let live = Color("Success")
    /// A card's edge, a rule between things.
    static let border = Color("Ink").opacity(0.14)
    static let radius: CGFloat = 10

    // The names the views used before, for the same roles.
    static let secondary = muted
    static let faint = muted
    static let rule = border
    static let bar = card

    /// Archivo at a text style's size, growing with the reader's text size.
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .custom("Archivo", size: sizes[style] ?? 17, relativeTo: style).weight(weight)
    }

    /// The board's letters.
    static func board(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .custom("Spline Sans Mono", fixedSize: size).weight(weight)
    }

    private static let sizes: [Font.TextStyle: CGFloat] = [
        .largeTitle: 34, .title: 28, .title2: 22, .title3: 20, .headline: 17, .body: 17,
        .callout: 16, .subheadline: 15, .footnote: 13, .caption: 12, .caption2: 11,
    ]
}

/// A FiestaBoard card: a step lighter than the room, a hairline edge, a soft shadow.
struct CardBackground: ViewModifier {
    var radius: CGFloat = Style.radius

    func body(content: Content) -> some View {
        content
            .background(Style.card, in: RoundedRectangle(cornerRadius: radius))
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Style.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

extension View {
    func card(radius: CGFloat = Style.radius) -> some View {
        modifier(CardBackground(radius: radius))
    }
}

/// The ribbon in a card's top right corner: orange for a favorite.
struct Ribbon: View {
    let filled: Bool

    var body: some View {
        RibbonShape()
            .fill(filled ? Style.primary : Style.ink.opacity(0.1))
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

/// A Lucide icon (lucide.dev, ISC licence), as FiestaBoard's web UI uses:
/// stroked, coloured by the foreground style, and growing with the reader's
/// text size.
struct LucideIcon: View {
    let name: String
    @ScaledMetric private var size: CGFloat

    init(_ name: String, size: CGFloat = 22, relativeTo style: Font.TextStyle = .body) {
        self.name = name
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
    }

    var body: some View {
        Image("lucide-\(name)")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

extension Label where Title == Text, Icon == LucideIcon {
    /// A label with a Lucide icon instead of a system symbol.
    init(_ title: String, lucide name: String) {
        self.init {
            Text(title)
        } icon: {
            LucideIcon(name, size: 16, relativeTo: .footnote)
        }
    }
}
