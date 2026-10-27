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

    var isCharacter: Bool {
        if case .character = self {
            return true
        }
        return false
    }

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
    /// As on a card: the letters alone, only colours as tiles.
    var plain = false
    /// The letters' colour when plain: dark on a light card.
    var ink: Color = .white
    /// White flaps with dark letters, as a white board's are; else black ones with white.
    var white = false

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
        .padding(plain ? 0 : 10)
        .background {
            if !plain {
                // The board's frame, as FiestaBoard draws it: silver round a Note, black round a Flagship.
                RoundedRectangle(cornerRadius: 10)
                    .fill(white
                        ? LinearGradient(colors: [Color(white: 0.95), Color(white: 0.86)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(white: 0.1), Color(white: 0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(white ? 0.08 : 0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            }
        }
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
        RoundedRectangle(cornerRadius: plain ? 1 : 2)
            .fill(plain && flap.isCharacter ? Color.clear : flap.isCharacter ? (white ? Color(white: 0.985) : Color(white: 0.12)) : flap.fill)
            // On a card a colour is a small tile, as high as a letter, not the whole flap.
            .scaleEffect(plain && !flap.isCharacter ? CGSize(width: 0.72, height: 0.62) : CGSize(width: 1, height: 1))
            .aspectRatio(1 / tileAspect, contentMode: .fit)
            .overlay {
                if case let .character(text) = flap, !text.isEmpty {
                    Text(text)
                        .font(Style.board(size: 200, weight: plain ? .regular : .semibold))
                        .minimumScaleFactor(0.01)
                        .lineLimit(1)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 1)
                        .foregroundStyle(plain ? ink : white ? Color(white: 0.1) : .white)
                }
            }
            .overlay {
                if plain, case .colour(.white) = flap {
                    // A white tile on a light card, seen by its edge.
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                        .scaleEffect(CGSize(width: 0.72, height: 0.62))
                }
                if case .character = flap, !plain {
                    // The split between the two halves of a flap.
                    Rectangle()
                        .fill(Color.black.opacity(white ? 0.07 : 0.5))
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
