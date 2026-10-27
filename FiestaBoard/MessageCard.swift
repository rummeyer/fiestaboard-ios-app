import SwiftUI

/// The board's shape, to draw and lay out messages for it.
struct BoardShape: Equatable {
    var rows: Int
    var cols: Int
    /// Code 62: a heart, as on a Note, or a degree sign, as on a Flagship until 2026.
    var heart: Bool
    /// A white board: white flaps, and its white and black tiles the other way round.
    var white: Bool
    /// An LED panel — a pixel clock, a matrix — rather than split flaps.
    var led = false

    static let note = BoardShape(rows: 3, cols: 15, heart: true)

    init(rows: Int, cols: Int, heart: Bool, white: Bool? = nil, led: Bool = false) {
        self.rows = rows
        self.cols = cols
        self.heart = heart
        self.white = white ?? heart
        self.led = led
    }

    init(_ board: BoardDetail, look: BoardLook) {
        let led = board.deviceType == "panel"
        self.init(rows: board.rows, cols: board.cols, heart: look.heart, white: look.white && !led, led: led)
    }
}

/// One action in a card's bottom bar.
struct CardAction: Identifiable {
    let id = UUID()
    /// A Lucide icon's name.
    let symbol: String
    let label: LocalizedStringKey
    let run: () -> Void
    /// Sending: how long the message shows chosen first, from a menu; minutes, or none until the next refresh.
    var send: ((Int?) -> Void)?

    init(symbol: String, label: LocalizedStringKey, run: @escaping () -> Void) {
        self.symbol = symbol
        self.label = label
        self.run = run
    }

    init(symbol: String, label: LocalizedStringKey, send: @escaping (Int?) -> Void) {
        self.symbol = symbol
        self.label = label
        self.run = {}
        self.send = send
    }
}

/// A message as a card: who and when on top, the ribbon
/// for a favorite, the message in the middle, and a bar of actions below.
struct MessageCard<More: View>: View {
    let characters: [[Int]]
    let heart: Bool
    var white = false
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
                        Text(senderName(sender))
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
            .font(Style.font(.subheadline))
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
                ink: Style.ink,
                white: white
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
                    Group {
                        if let send = action.send {
                            Menu {
                                Section(action.label) {
                                    ForEach(showDurations, id: \.0) { minutes, title in
                                        Button(title) { send(minutes) }
                                    }
                                }
                            } label: {
                                LucideIcon(action.symbol, size: 22, relativeTo: .title3)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            Button(action: action.run) {
                                LucideIcon(action.symbol, size: 22, relativeTo: .title3)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                    .accessibilityLabel(action.label)
                }
                if let shareText {
                    Rectangle().fill(Style.rule).frame(width: 1)
                    ShareLink(item: shareText) {
                        LucideIcon("forward", size: 22, relativeTo: .title3)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .accessibilityLabel("Share")
                }
                if More.self != EmptyView.self {
                    Rectangle().fill(Style.rule).frame(width: 1)
                    Menu {
                        more()
                    } label: {
                        LucideIcon("ellipsis-vertical", size: 22, relativeTo: .title3)
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
    init(characters: [[Int]], heart: Bool, white: Bool = false, sender: String? = nil, date: Date? = nil, favorite: Bool? = nil,
         onFavorite: @escaping () -> Void = {}, shareText: String? = nil, actions: [CardAction]) {
        self.init(characters: characters, heart: heart, white: white, sender: sender, date: date, favorite: favorite,
                  onFavorite: onFavorite, shareText: shareText, actions: actions, more: { EmptyView() })
    }
}

/// Who put a message there, in the reader's language: "You" and "Draft" are
/// the app's own words, a board's or FiestaBoard's name stays as it is.
func senderName(_ sender: String) -> String {
    switch sender {
    case "You": String(localized: "You")
    case "Draft": String(localized: "Draft")
    default: sender
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
                    LucideIcon("user", size: 16, relativeTo: .caption).foregroundStyle(Style.card)
                } else {
                    Text(senderName(name).prefix(1)).font(Style.font(.caption, weight: .semibold)).foregroundStyle(Style.card)
                }
            }
    }
}
