import SwiftUI

/// One tile of a board, by row and column.
struct Cell: Hashable {
    var row: Int
    var col: Int
}

/// What a touch on the board does in the visual editor.
enum EditorTool: Equatable {
    /// Paints the tiles touched in a colour.
    case colour(Int)
    /// Blanks them.
    case eraser
    /// Puts a cursor on the tile touched, for letters typed from there.
    case letters
}

/// The board as a canvas: drawn as it looks, a tile painted or erased where it
/// is touched, several in one stroke of the finger, and the cursor on the
/// tile letters go to.
struct BoardEditor: View {
    let grid: [[Int]]
    let shape: BoardShape
    let cursor: Cell?
    /// A stroke begins, so that it can be undone as one.
    let begin: () -> Void
    let touch: (Cell) -> Void

    // As BoardView lays out its tiles.
    private let inset: CGFloat = 10
    private let gap: CGFloat = 2
    private let tileAspect: CGFloat = 1.3

    @State private var stroking = false

    var body: some View {
        BoardView(characters: grid, rows: shape.rows, cols: shape.cols, heart: shape.heart, white: shape.heart, led: shape.led)
            .overlay {
                GeometryReader { geometry in
                    let size = tileSize(in: geometry.size)
                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if !stroking {
                                            stroking = true
                                            begin()
                                        }
                                        if let cell = cell(at: value.location, tile: size) {
                                            touch(cell)
                                        }
                                    }
                                    .onEnded { _ in stroking = false }
                            )
                        if let cursor {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Style.primary, lineWidth: 2.5)
                                .frame(width: size.width + 2, height: size.height + 2)
                                .offset(x: inset + CGFloat(cursor.col) * (size.width + gap) - 1,
                                        y: inset + CGFloat(cursor.row) * (size.height + gap) - 1)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .accessibilityHint(Text("Tap or drag across the tiles to paint them."))
    }

    private func tileSize(in size: CGSize) -> CGSize {
        let width = (size.width - 2 * inset - gap * CGFloat(shape.cols - 1)) / CGFloat(shape.cols)
        return CGSize(width: width, height: width * tileAspect)
    }

    private func cell(at point: CGPoint, tile: CGSize) -> Cell? {
        let col = Int(((point.x - inset) / (tile.width + gap)).rounded(.down))
        let row = Int(((point.y - inset) / (tile.height + gap)).rounded(.down))
        guard (0..<shape.rows).contains(row), (0..<shape.cols).contains(col) else {
            return nil
        }
        return Cell(row: row, col: col)
    }
}
