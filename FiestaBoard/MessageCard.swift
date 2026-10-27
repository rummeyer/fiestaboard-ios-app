import SwiftUI

/// The board's shape, to draw and lay out messages for it.
struct BoardShape: Equatable {
    var rows: Int
    var cols: Int
    /// Code 62 is a heart on a Note, a degree sign on a Flagship.
    var heart: Bool

    static let note = BoardShape(rows: 3, cols: 15, heart: true)

    init(rows: Int, cols: Int, heart: Bool) {
        self.rows = rows
        self.cols = cols
        self.heart = heart
    }

    init(_ board: BoardDetail) {
        self.init(rows: board.rows, cols: board.cols, heart: board.deviceType.hasPrefix("note"))
    }
}

/// One action in a card's bottom bar.
struct CardAction: Identifiable {
    let id = UUID()
    let symbol: String
    let label: String
    let run: () -> Void
}

/// A message as Vestaboard's app shows one: who and when on top, the ribbon
/// for a favorite, the message in the middle, and a bar of actions below.
struct MessageCard<More: View>: View {
    let characters: [[Int]]
    let heart: Bool
    var sender: String?
    var date: Date?
    var favorite: Bool?
    var onFavorite: () -> Void = {}
    var shareText: String?
    let actions: [CardAction]
    @ViewBuilder var more: () -> More

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                if let sender {
                    Avatar(name: sender)
                    // Who on one line, when beside it, both smaller rather than wrapped.
                    HStack(spacing: 10) {
                        Text(sender)
                            .foregroundStyle(Style.ink)
                            .layoutPriority(1)
                        if let date {
                            Text(ago(date))
                                .foregroundStyle(Style.faint)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                Spacer()
                if let favorite {
                    Button(action: onFavorite) {
                        Ribbon(filled: favorite)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, -14)
                }
            }
            .font(.subheadline)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .frame(minHeight: 44, alignment: .top)

            BoardView(
                characters: characters,
                rows: characters.count,
                cols: characters.first?.count ?? 0,
                heart: heart,
                plain: true,
                ink: Style.ink
            )
            .frame(maxWidth: 250)
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)

            Rectangle().fill(Style.rule).frame(height: 1)
            HStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    if index > 0 {
                        Rectangle().fill(Style.rule).frame(width: 1)
                    }
                    Button(action: action.run) {
                        Image(systemName: action.symbol)
                            .font(.title3)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .accessibilityLabel(action.label)
                }
                if let shareText {
                    Rectangle().fill(Style.rule).frame(width: 1)
                    ShareLink(item: shareText) {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .font(.title3)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .accessibilityLabel("Share")
                }
                if More.self != EmptyView.self {
                    Rectangle().fill(Style.rule).frame(width: 1)
                    Menu {
                        more()
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.title3)
                            .frame(width: 64)
                            .frame(maxHeight: .infinity)
                    }
                    .accessibilityLabel("More")
                }
            }
            .foregroundStyle(Style.faint)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .frame(height: 56)
        }
        .card()
    }
}

extension MessageCard where More == EmptyView {
    init(characters: [[Int]], heart: Bool, sender: String? = nil, date: Date? = nil, favorite: Bool? = nil,
         onFavorite: @escaping () -> Void = {}, shareText: String? = nil, actions: [CardAction]) {
        self.init(characters: characters, heart: heart, sender: sender, date: date, favorite: favorite,
                  onFavorite: onFavorite, shareText: shareText, actions: actions, more: { EmptyView() })
    }
}

/// A sender's round badge: the app's own sends as a person, others by their first letter.
struct Avatar: View {
    let name: String

    var body: some View {
        Circle()
            .fill(Style.ink)
            .frame(width: 30, height: 30)
            .overlay {
                if name == "You" {
                    Image(systemName: "person.fill").font(.caption).foregroundStyle(.white)
                } else {
                    Text(name.prefix(1)).font(.caption).foregroundStyle(.white)
                }
            }
    }
}
