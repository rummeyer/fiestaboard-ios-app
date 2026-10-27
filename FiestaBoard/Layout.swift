import Foundation

/// Text laid out on a board as FiestaBoard lays out a text message: from the
/// top left, word-wrapped to the board's width, a line break where one is
/// typed, a colour marker such as `{red}` one tile, and what does not fit cut
/// off at the bottom. The preview shows what the board will.
enum Layout {
    /// A grid made to a board's size: cut where it is larger, blank where it is smaller.
    static func fit(_ grid: [[Int]], rows: Int, cols: Int) -> [[Int]] {
        (0..<rows).map { row in
            (0..<cols).map { col in row < grid.count && col < grid[row].count ? grid[row][col] : 0 }
        }
    }

    /// A grid as text to write on: its letters, a marker such as `{red}` for each colour,
    /// a line for each row — the blanks before a word kept, where they place it.
    static func text(of grid: [[Int]]) -> String {
        grid.map { row in
            row.map { code -> String in
                if let name = colours.first(where: { $0.value == code && $0.key != "purple" })?.key {
                    return "{\(name)}"
                }
                if case let .character(letter) = Flap.of(code, heart: false) {
                    return letter.isEmpty ? " " : letter
                }
                return " "
            }.joined().replacingOccurrences(of: " +$", with: "", options: .regularExpression)
        }.joined(separator: "\n").replacingOccurrences(of: "\n+$", with: "", options: .regularExpression)
    }

    /// A grid as rows of text that come out as the same flaps: a letter, digit or sign
    /// as itself, a blank as a space, every other flap as its code, such as `{63}`.
    static func lines(of grid: [[Int]]) -> [String] {
        grid.map { row in
            row.map { code -> String in
                if code == 0 {
                    return " "
                }
                if code != 62, case let .character(letter) = Flap.of(code, heart: false), !letter.isEmpty,
                   let back = letter.first, Layout.code(of: back) == code {
                    return letter
                }
                return "{\(code)}"
            }.joined().replacingOccurrences(of: " +$", with: "", options: .regularExpression)
        }
    }

    static func grid(_ text: String, rows: Int, cols: Int) -> (grid: [[Int]], overflow: Bool) {
        var lines: [[Int]] = []
        for line in text.components(separatedBy: "\n") {
            let tiles = tiles(of: line)
            if tiles.count <= cols {
                lines.append(tiles)
            } else {
                lines.append(contentsOf: wrap(tiles, cols: cols))
            }
        }
        let overflow = lines.count > rows
        var grid = Array(lines.prefix(rows)).map { Array($0.prefix(cols)) + Array(repeating: 0, count: max(0, cols - $0.count)) }
        while grid.count < rows {
            grid.append(Array(repeating: 0, count: cols))
        }
        return (grid, overflow)
    }

    /// Greedy word wrap on tiles, a word wider than the board flowing on.
    private static func wrap(_ tiles: [Int], cols: Int) -> [[Int]] {
        let words = tiles.split(separator: 0, omittingEmptySubsequences: true).map(Array.init)
        guard !words.isEmpty else {
            return [[]]
        }
        var wrapped: [[Int]] = []
        var current: [Int] = []
        for var word in words {
            if !current.isEmpty && current.count + 1 + word.count <= cols {
                current += [0] + word
                continue
            }
            if !current.isEmpty {
                wrapped.append(current)
                current = []
            }
            while word.count > cols {
                wrapped.append(Array(word.prefix(cols)))
                word = Array(word.dropFirst(cols))
            }
            current = word
        }
        if !current.isEmpty {
            wrapped.append(current)
        }
        return wrapped
    }

    /// A line as flap codes: a marker `{red}` or `{63}` one tile, other braces as they are.
    static func tiles(of line: String) -> [Int] {
        var codes: [Int] = []
        var rest = Substring(line)
        while let first = rest.first {
            if first == "{", let close = rest.firstIndex(of: "}") {
                let name = rest[rest.index(after: rest.startIndex)..<close].lowercased()
                if let code = colours[name] ?? Int(name).flatMap({ (0...71).contains($0) ? $0 : nil }) {
                    codes.append(code)
                    rest = rest[rest.index(after: close)...]
                    continue
                }
            }
            codes.append(code(of: first))
            rest = rest.dropFirst()
        }
        return codes
    }

    static let colours: [String: Int] = [
        "red": 63, "orange": 64, "yellow": 65, "green": 66, "blue": 67, "violet": 68, "purple": 68,
        "white": 69, "black": 70, "filled": 71,
    ]

    /// A typed character's flap code; 0, a blank, for one the board has not.
    static func code(of character: Character) -> Int {
        let upper = String(character).uppercased()
        if let scalar = upper.unicodeScalars.first, upper.count == 1 {
            switch scalar.value {
            case 65...90:
                return Int(scalar.value) - 64
            case 49...57:
                return Int(scalar.value) - 49 + 27
            case 48:
                return 36
            default:
                break
            }
        }
        return punctuation[upper] ?? 0
    }

    private static let punctuation: [String: Int] = [
        "!": 37, "@": 38, "#": 39, "$": 40, "(": 41, ")": 42, "-": 44, "+": 46, "&": 47, "=": 48,
        ";": 49, ":": 50, "'": 52, "\"": 53, "%": 54, ",": 55, ".": 56, "/": 59, "?": 60, "°": 62, "❤": 62, "♥": 62,
    ]
}
