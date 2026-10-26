import SwiftUI

/// What a flap code shows: a character, or a colour tile.
enum Flap: Equatable {
    case character(String)
    case colour(Color)

    /// The board's character set, 0–71, as FiestaBoard documents it. Undefined codes are blank.
    static func of(_ code: Int, heart: Bool) -> Flap {
        switch code {
        case 1...26:
            return .character(String(UnicodeScalar(UInt8(64 + code))))
        case 27...35:
            return .character(String(code - 26))
        case 36:
            return .character("0")
        case 62:
            // One flap, two faces: a Note shows a heart, a Flagship a degree sign.
            return .character(heart ? "❤" : "°")
        case 63...71:
            return .colour(colours[code - 63])
        default:
            return .character(punctuation[code] ?? "")
        }
    }

    private static let punctuation: [Int: String] = [
        37: "!", 38: "@", 39: "#", 40: "$", 41: "(", 42: ")", 44: "-", 46: "+", 47: "&", 48: "=",
        49: ";", 50: ":", 52: "'", 53: "\"", 54: "%", 55: ",", 56: ".", 59: "/", 60: "?",
    ]

    /// Red, orange, yellow, green, blue, violet, white, black, and 71, filled.
    private static let colours: [Color] = [
        Color(red: 0.85, green: 0.16, blue: 0.11),
        Color(red: 1.00, green: 0.46, blue: 0.00),
        Color(red: 1.00, green: 0.72, blue: 0.11),
        Color(red: 0.00, green: 0.60, blue: 0.27),
        Color(red: 0.00, green: 0.34, blue: 0.72),
        Color(red: 0.44, green: 0.18, blue: 0.54),
        .white,
        .black,
        .white,
    ]

    /// The tile's face: dark behind a character, else its colour.
    var fill: Color {
        if case let .colour(colour) = self {
            return colour
        }
        return Color(white: 0.12)
    }
}

/// The board's flaps, drawn as the board looks: dark tiles, white characters, colour tiles.
struct BoardView: View {
    let characters: [[Int]]
    let rows: Int
    let cols: Int
    let heart: Bool

    /// A flap is taller than wide.
    private let tileAspect: CGFloat = 1.3
    private let gap: CGFloat = 2

    var body: some View {
        Grid(horizontalSpacing: gap, verticalSpacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<cols, id: \.self) { col in
                        tile(Flap.of(code(row, col), heart: heart))
                    }
                }
            }
        }
        .padding(8)
        .background(Color(white: 0.05), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleText)
    }

    private func code(_ row: Int, _ col: Int) -> Int {
        guard row < characters.count, col < characters[row].count else {
            return 0
        }
        return characters[row][col]
    }

    private func tile(_ flap: Flap) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(flap.fill)
            .aspectRatio(1 / tileAspect, contentMode: .fit)
            .overlay {
                if case let .character(text) = flap, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 200, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.01)
                        .lineLimit(1)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 1)
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                if case .character = flap {
                    // The split between the two halves of a flap.
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(height: 0.5)
                }
            }
    }

    private var accessibleText: String {
        characters.map { row in
            row.map { code -> String in
                if case let .character(text) = Flap.of(code, heart: heart) {
                    return text.isEmpty ? " " : text
                }
                return " "
            }.joined().trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

#Preview {
    BoardView(
        characters: [
            [0, 8, 5, 12, 12, 15, 0, 23, 15, 18, 12, 4, 37, 0, 0],
            [63, 64, 65, 66, 67, 68, 69, 0, 62, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 27, 28, 50, 29, 30, 0, 16, 13, 0, 0, 0, 0],
        ],
        rows: 3, cols: 15, heart: true
    )
    .padding()
}
