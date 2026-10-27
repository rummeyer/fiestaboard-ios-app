import SwiftUI

/// Home: the board live on top, then History,
/// Favorites and Drafts, and the button to write a message.
struct HomeView: View {
    enum Tab: CaseIterable {
        case history, favorites, drafts

        var title: LocalizedStringKey {
            switch self {
            case .history: "History"
            case .favorites: "Favorites"
            case .drafts: "Drafts"
            }
        }
    }

    @Environment(Settings.self) private var settings
    @Environment(Library.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("board") private var boardID = "primary"

    @State private var boards: [BoardSummary] = []
    @State private var board: BoardDetail?
    @State private var problem: String?
    @State private var tab = Tab.history
    @State private var filtering = false
    @State private var oldestFirst = false
    @State private var sender: String?
    @State private var showingLive = false
    @State private var showingSettings = false
    @State private var composing: ComposeRequest?
    @State private var notice: String?

    /// How often the board is read again while the app is open.
    private let refreshSeconds = 15

    private var shape: BoardShape {
        board.map { BoardShape($0, look: settings.look(for: $0.id, deviceType: $0.deviceType)) } ?? .note
    }

    private var boardName: String {
        board?.name ?? "FiestaBoard"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Style.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if boards.count > 1 {
                    boardSelector
                }
                liveCard
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                tabs
                ScrollView {
                    VStack(spacing: 26) {
                        if let problem {
                            Label(problem, lucide: "triangle-alert")
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        content
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .refreshable { await load() }
                bottomBar
            }
            composeButton
                .padding(.trailing, 20)
                .padding(.bottom, 84)
        }
        .overlay(alignment: .top) {
            if let notice {
                Text(notice)
                    .font(Style.font(.footnote))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation { self.notice = nil }
                    }
            }
        }
        .fullScreenCover(isPresented: $showingLive) {
            liveView
        }
        .fullScreenCover(item: $composing) { request in
            ComposeView(request: request, shape: shape, boardName: boardName) { outgoing, minutes in
                await send(outgoing, minutes: minutes)
            }
            .environment(library)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(boards: boards)
            }
            .environment(settings)
        }
        // Read again now and every so often while open; stopped in the background.
        .task(id: "\(boardID)|\(scenePhase == .active)|\(settings.address)|\(settings.token)|\(settings.demoBoard)") {
            guard scenePhase == .active else {
                return
            }
            while !Task.isCancelled {
                await load()
                try? await Task.sleep(for: .seconds(refreshSeconds))
            }
        }
    }

    // MARK: - The board live

    /// Every board by its whole name, the chosen one in orange; scrolled sideways when they do not fit.
    private var boardSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(boards) { each in
                    Button {
                        boardID = each.id
                    } label: {
                        Text(each.name)
                            .font(Style.font(.subheadline, weight: each.id == boardID ? .semibold : .regular))
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(each.id == boardID ? Style.primaryInk : Style.ink)
                            .background(each.id == boardID ? Style.primary : Style.card, in: Capsule())
                            .overlay(Capsule().stroke(Style.border, lineWidth: each.id == boardID ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(each.id == boardID ? .isSelected : [])
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 2)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.top, 6)
    }

    private var liveCard: some View {
        Button {
            showingLive = true
        } label: {
            VStack(spacing: 8) {
                liveTitle(dark: true)
                    .font(Style.font(.footnote))
                if let board {
                    // Nothing sent to it yet: the board as it stands, empty, rather than waiting.
                    BoardView(characters: board.characters ?? [], rows: board.rows, cols: board.cols, heart: shape.heart, white: shape.white, led: shape.led)
                        .frame(maxWidth: 300)
                } else {
                    ProgressView().frame(height: 36)
                }
                ZStack {
                    LucideIcon("chevron-down", size: 18, relativeTo: .footnote)
                    if let until {
                        Label(String(localized: "Until \(until.formatted(date: .omitted, time: .shortened))"), lucide: "timer")
                            .font(Style.font(.caption2))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let date = liveDate {
                        Text(ago(date))
                            .font(Style.font(.caption2))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .foregroundStyle(Style.ink)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            // Small print on a small card: larger text, but the time stays clear of the chevron.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Live on \(boardName). Show it large.")
    }

    private func liveTitle(dark: Bool) -> some View {
        HStack(spacing: 6) {
            Text("Live on \(boardName)")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if boardID == VirtualBoard.id {
                Text("Demo")
                    .font(Style.font(.caption2, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .foregroundStyle(Style.primaryInk)
                    .background(Style.primary, in: Capsule())
            }
            Circle().fill(board?.paused == true ? Color.orange : Style.live).frame(width: 7, height: 7)
        }
        .foregroundStyle(Style.ink)
    }

    /// When what the board shows came there, as far as the app knows.
    private var liveDate: Date? {
        board?.characters.flatMap { library.latest($0, on: boardID)?.date }
    }

    private var liveView: some View {
        ZStack(alignment: .bottom) {
            Style.background.ignoresSafeArea()
            VStack(spacing: 50) {
                Spacer()
                liveTitle(dark: false)
                    .font(Style.font(.title3, weight: .medium))
                if let board {
                    let characters = board.characters ?? Array(repeating: Array(repeating: 0, count: board.cols), count: board.rows)
                    let kept = library.latest(characters, on: boardID)
                    MessageCard(
                        characters: characters,
                        heart: shape.heart,
                        white: shape.white,
                        sender: kept?.sender,
                        date: kept?.date,
                        favorite: library.isFavorite(characters),
                        onFavorite: { library.toggleFavorite(characters, board: boardID, boardName: boardName) },
                        shareText: kept?.editableText ?? board.text,
                        actions: [
                            CardAction(symbol: "copy", label: "Copy into a new message") {
                                showingLive = false
                                composing = kept.map(request(from:)) ?? ComposeRequest(characters: characters)
                            },
                        ]
                    )
                    .padding(.horizontal, 18)
                    status(of: board)
                }
                Spacer()
                Spacer()
            }
            Button {
                showingLive = false
            } label: {
                LucideIcon("x", size: 26, relativeTo: .title2)
                    .foregroundStyle(Style.ink)
                    .frame(width: 64, height: 64)
                    .background(Style.card, in: Circle())
                    .overlay(Circle().stroke(Style.border, lineWidth: 1))
            }
            .accessibilityLabel("Close")
            .padding(.bottom, 24)
        }
    }

    private func status(of board: BoardDetail) -> some View {
        VStack(spacing: 16) {
            Group {
                if board.paused {
                    Label("Paused", lucide: "circle-pause")
                } else if let until {
                    Label(String(localized: "A message until \(until.formatted(date: .omitted, time: .shortened)), then the schedule again"), lucide: "timer")
                } else if board.source == "schedule" {
                    Label("Following the schedule", lucide: "calendar")
                }
            }
            .font(Style.font(.footnote))
            .foregroundStyle(Style.secondary)
            .multilineTextAlignment(.center)
            if until != nil {
                Button {
                    Task { await backToSchedule() }
                } label: {
                    Label("Back to the schedule", lucide: "calendar")
                        .secondaryButton()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
    }

    /// When a timed message on the board gives way to the schedule again; none without one.
    private var until: Date? {
        guard let text = board?.overrideExpiresAt else {
            return nil
        }
        let precise = ISO8601DateFormatter()
        precise.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return precise.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }

    /// Ends a timed message before its time: the board shows its schedule again.
    private func backToSchedule() async {
        do {
            let response = try await settings.service(for: boardID).clear(boardID)
            notice = response.sent ? String(localized: "Back to the schedule") : response.reason ?? String(localized: "Not sent")
            await load()
        } catch {
            notice = error.localizedDescription
        }
    }

    // MARK: - History, Favorites, Drafts

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { each in
                Button {
                    tab = each
                } label: {
                    VStack(spacing: 8) {
                        Text(each.title)
                            .font(Style.font(.callout, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(tab == each ? Style.ink : Style.muted)
                        Rectangle()
                            .fill(tab == each ? Style.primary : .clear)
                            .frame(height: 2)
                    }
                    // Small, and still a whole finger's height to tap.
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Style.border).frame(height: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .history, .favorites:
            let history = library.history(for: boardID)
            let messages = tab == .history ? shown(history) : library.favorites
            if tab == .history && (!history.isEmpty || sender != nil) {
                filterBar
            }
            if messages.isEmpty && tab == .history {
                empty("No messages yet", "What you send from here, and what the board shows while the app is open, comes here.")
            } else if messages.isEmpty {
                empty("No favorites yet", "Tap the ribbon on a message to keep it here.")
            }
            ForEach(messages) { message in
                card(message)
            }
        case .drafts:
            if library.drafts.isEmpty {
                empty("You have no drafts saved yet", "To keep a message for later, choose Save Draft next to Send while writing it.")
            }
            ForEach(library.drafts) { draft in
                draftCard(draft)
            }
        }
    }

    private func shown(_ messages: [SavedMessage]) -> [SavedMessage] {
        let some = sender.map { name in messages.filter { $0.sender == name } } ?? messages
        return oldestFirst ? some.reversed() : some
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            if filtering {
                HStack {
                    Button {
                        withAnimation { filtering = false }
                    } label: {
                        LucideIcon("x", size: 22, relativeTo: .title3)
                    }
                    .accessibilityLabel("Close the filter")
                    Spacer()
                    Text("Sort By")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Picker("Sort By", selection: $oldestFirst) {
                        Text("Recent").tag(false)
                        Text("Oldest").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip(Text("All"), selected: sender == nil) { sender = nil }
                        ForEach(library.senders(for: boardID), id: \.self) { name in
                            chip(Text(senderName(name)), selected: sender == name) { sender = name }
                        }
                    }
                }
            } else {
                Button {
                    withAnimation { filtering = true }
                } label: {
                    LucideIcon("sliders-horizontal", size: 22, relativeTo: .title3)
                        .frame(width: 52, height: 52)
                        .background(Style.card, in: Circle())
                        .overlay(Circle().stroke(Style.border, lineWidth: 1))
                }
                .accessibilityLabel("Sort and filter")
            }
        }
        .foregroundStyle(Style.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ title: Text, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            title
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? Style.primaryInk : Style.muted)
                .background(selected ? Style.primary : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(Style.border, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private func empty(_ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        VStack(spacing: 14) {
            Text(title).font(Style.font(.title3)).foregroundStyle(Style.ink)
            Text(detail).foregroundStyle(Style.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 40)
        .padding(.horizontal, 20)
    }

    private func card(_ message: SavedMessage) -> some View {
        MessageCard(
            characters: message.characters,
            heart: shape.heart,
            white: shape.white,
            sender: message.sender,
            date: message.date,
            favorite: library.isFavorite(message.characters),
            onFavorite: { library.toggleFavorite(message) },
            shareText: message.editableText,
            actions: [
                CardAction(symbol: "copy", label: "Copy into a new message") {
                    composing = request(from: message)
                },
                CardAction(symbol: "send", label: "Send to the board") { minutes in
                    Task { await resend(message, minutes: minutes) }
                },
            ]
        ) {
            Button {
                library.toggleFavorite(message)
            } label: {
                if library.isFavorite(message.characters) {
                    Label("Remove from Favorites", lucide: "bookmark")
                } else {
                    Label("Add to Favorites", lucide: "bookmark")
                }
            }
            // In Favorites, out of them; in History, out of the history, a favorite of it staying.
            if tab == .history {
                Button(role: .destructive) {
                    library.delete(message)
                } label: {
                    Label("Delete", lucide: "trash-2")
                }
            }
        }
    }

    private func draftCard(_ draft: Draft) -> some View {
        MessageCard(
            characters: draft.characters.map { Layout.fit($0, rows: shape.rows, cols: shape.cols) }
                ?? Layout.grid(draft.text, rows: shape.rows, cols: shape.cols).grid,
            heart: shape.heart,
            white: shape.white,
            sender: "Draft",
            date: draft.date,
            shareText: draft.text,
            actions: [
                CardAction(symbol: "pencil", label: "Edit") {
                    composing = ComposeRequest(text: draft.text, characters: draft.characters, draft: draft.id)
                },
                CardAction(symbol: "send", label: "Send to the board") { minutes in
                    Task {
                        if let outcome = await send(outgoing(of: draft), minutes: minutes) {
                            notice = outcome
                        } else {
                            library.deleteDraft(draft.id)
                        }
                    }
                },
            ]
        ) {
            Button(role: .destructive) {
                library.deleteDraft(draft.id)
            } label: {
                Label("Delete", lucide: "trash-2")
            }
        }
    }

    // MARK: - Bars and buttons

    private var composeButton: some View {
        Button {
            composing = ComposeRequest()
        } label: {
            LucideIcon("square-pen", size: 28, relativeTo: .title)
                .foregroundStyle(Style.primaryInk)
                .frame(width: 68, height: 68)
                .background(Style.primary, in: Circle())
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
        .accessibilityLabel("Write a message")
    }

    private var bottomBar: some View {
        HStack {
            VStack(spacing: 10) {
                Rectangle().fill(Style.primary).frame(width: 40, height: 3)
                LucideIcon("house", size: 26, relativeTo: .title2)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Home")
            Button {
                showingSettings = true
            } label: {
                LucideIcon("settings", size: 26, relativeTo: .title2).padding(.top, 13)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Settings")
        }
        .foregroundStyle(Style.ink.opacity(0.8))
        .padding(.bottom, 6)
        .frame(height: 64, alignment: .top)
        .background(Style.bar.ignoresSafeArea())
        .overlay(alignment: .top) { Rectangle().fill(Style.border).frame(height: 1) }
    }

    // MARK: - FiestaBoard

    private func load() async {
        if Demo.on {
            await Demo.fill(library)
            if Demo.compose && composing == nil {
                composing = ComposeRequest(text: "Kaffee ist fertig {red}")
            }
            if Demo.visual && composing == nil {
                composing = ComposeRequest(characters: Demo.drawn)
            }
            if Demo.live {
                showingLive = true
            }
        }
        // FiestaBoard's boards, then the demo board. FiestaBoard away a moment: its boards as last known.
        var failure: Error?
        var list: [BoardSummary] = []
        if let fiestaBoard = settings.fiestaBoard {
            do {
                list = try await fiestaBoard.boards()
            } catch is CancellationError {
                return
            } catch {
                failure = error
                list = boards.filter { $0.id != VirtualBoard.id }
            }
        }
        if settings.demoBoard {
            list += (try? await VirtualBoard.shared.boards()) ?? []
        }
        if Demo.on {
            list += (try? await SampleClock.shared.boards()) ?? []
        }
        boards = list
        // The board chosen gone, or not chosen yet: FiestaBoard's primary one, else the first.
        if !list.contains(where: { $0.id == boardID }), let pick = list.first(where: \.isPrimary) ?? list.first {
            boardID = pick.id
        }
        do {
            let read = try await settings.service(for: boardID).board(boardID)
            board = read
            if let characters = read.characters {
                library.seen(characters, board: read.id, boardName: read.name)
            }
            problem = failure?.localizedDescription
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            problem = error.localizedDescription
        }
    }

    /// A kept message to start from: its text as written, or, for one only seen on the board, its tiles.
    private func request(from message: SavedMessage) -> ComposeRequest {
        message.text.map { ComposeRequest(text: $0) } ?? ComposeRequest(characters: message.characters)
    }

    /// A draft as it goes out: tile by tile to a board of its size, else as text.
    private func outgoing(of draft: Draft) -> Outgoing {
        if let grid = draft.characters, grid.count == shape.rows, grid.first?.count == shape.cols {
            return .grid(grid)
        }
        return .text(draft.text)
    }

    /// Sends text or tiles; nil when it reached the board, else what came of it.
    private func send(_ outgoing: Outgoing, minutes: Int?) async -> String? {
        do {
            let api = try settings.service(for: boardID)
            switch outgoing {
            case let .text(text):
                return await sent(try await api.send(text, to: boardID, minutes: minutes), text: text)
            case let .grid(grid):
                return await sent(try await api.send(characters: grid, to: boardID, minutes: minutes), text: nil)
            }
        } catch {
            return error.localizedDescription
        }
    }

    /// Sends a kept message again: flap for flap to a board of its size, else its text.
    private func resend(_ message: SavedMessage, minutes: Int?) async {
        do {
            let api = try settings.service(for: boardID)
            let sameSize = message.characters.count == shape.rows && message.characters.first?.count == shape.cols
            let response = sameSize
                ? try await api.send(characters: message.characters, to: boardID, minutes: minutes)
                : try await api.send(message.editableText, to: boardID, minutes: minutes)
            notice = await sent(response, text: message.text) ?? String(localized: "Sent to \(boardName)")
        } catch {
            notice = error.localizedDescription
        }
    }

    private func sent(_ response: MessageResponse, text: String?) async -> String? {
        if response.sent || response.held == true {
            library.sent(response.characters, text: text, board: boardID, boardName: boardName)
            if response.held == true {
                notice = String(localized: "Held until the board's quiet time ends")
            }
            await load()
            return nil
        }
        return response.reason ?? String(localized: "Not sent")
    }
}
