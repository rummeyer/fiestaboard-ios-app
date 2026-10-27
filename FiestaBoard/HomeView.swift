import SwiftUI

/// Home, as in Vestaboard's app: the board live on top, then History,
/// Favorites and Drafts, and the button to write a message.
struct HomeView: View {
    enum Tab: String, CaseIterable {
        case history = "History", favorites = "Favorites", drafts = "Drafts"
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
        board.map(BoardShape.init) ?? .note
    }

    private var boardName: String {
        board?.name ?? "FiestaBoard"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Style.background.ignoresSafeArea()
            VStack(spacing: 0) {
                liveCard
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                tabs
                ScrollView {
                    VStack(spacing: 26) {
                        if let problem {
                            Label(problem, systemImage: "exclamationmark.triangle")
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
                    .font(.footnote)
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
            ComposeView(request: request, shape: shape, boardName: boardName) { text in
                await sendText(text)
            }
            .environment(library)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
            .environment(settings)
        }
        // Read again now and every so often while open; stopped in the background.
        .task(id: "\(boardID)|\(scenePhase == .active)|\(settings.address)|\(settings.token)") {
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

    private var liveCard: some View {
        Button {
            showingLive = true
        } label: {
            VStack(spacing: 8) {
                liveTitle(dark: true)
                    .font(.footnote)
                if let board, let characters = board.characters {
                    BoardView(characters: characters, rows: board.rows, cols: board.cols, heart: shape.heart, plain: true, ink: Style.ink)
                        .frame(maxWidth: 220)
                } else {
                    ProgressView().frame(height: 36)
                }
                ZStack {
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                    if let date = liveDate {
                        Text(ago(date))
                            .font(.caption2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .foregroundStyle(Style.ink)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Live on \(boardName). Show it large.")
    }

    private func liveTitle(dark: Bool) -> some View {
        HStack(spacing: 6) {
            Text("Live on \(boardName)")
            Circle().fill(board?.paused == true ? Color.orange : Style.live).frame(width: 7, height: 7)
        }
        .foregroundStyle(dark ? Style.ink : .white)
    }

    /// When what the board shows came there, as far as the app knows.
    private var liveDate: Date? {
        board?.characters.flatMap { library.latest($0)?.date }
    }

    private var liveView: some View {
        ZStack(alignment: .bottom) {
            Style.background.ignoresSafeArea()
            VStack(spacing: 50) {
                Spacer()
                liveTitle(dark: false)
                    .font(.title3.weight(.medium))
                if let board, let characters = board.characters {
                    let kept = library.latest(characters)
                    MessageCard(
                        characters: characters,
                        heart: shape.heart,
                        sender: kept?.sender,
                        date: kept?.date,
                        favorite: library.isFavorite(characters),
                        onFavorite: { library.toggleFavorite(characters, boardName: boardName) },
                        shareText: kept?.editableText ?? board.text,
                        actions: [
                            CardAction(symbol: "square.on.square.fill", label: "Copy into a new message") {
                                showingLive = false
                                composing = ComposeRequest(text: kept?.editableText ?? "")
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
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(Style.ink)
                    .frame(width: 64, height: 64)
                    .background(Color.white, in: Circle())
            }
            .accessibilityLabel("Close")
            .padding(.bottom, 24)
        }
    }

    private func status(of board: BoardDetail) -> some View {
        Group {
            if board.paused {
                Label("Paused", systemImage: "pause.circle")
            } else if board.overrideExpiresAt != nil {
                Label("A message for a while, then the schedule again", systemImage: "timer")
            } else if board.source == "schedule" {
                Label("Following the schedule", systemImage: "calendar")
            }
        }
        .font(.footnote)
        .foregroundStyle(Style.secondary)
    }

    // MARK: - History, Favorites, Drafts

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { each in
                Button {
                    tab = each
                } label: {
                    VStack(spacing: 12) {
                        Text(each.rawValue)
                            .font(.title3)
                            .foregroundStyle(tab == each ? Color.white : Style.secondary)
                        Rectangle()
                            .fill(tab == each ? Color.white : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 18)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .history, .favorites:
            let messages = shown(tab == .history ? library.messages : library.favorites)
            if tab == .history && !library.messages.isEmpty || sender != nil {
                filterBar
            }
            if messages.isEmpty {
                empty(tab == .history ? "No messages yet" : "No favorites yet",
                      tab == .history
                        ? "What you send from here, and what the board shows while the app is open, comes here."
                        : "Tap the ribbon on a message to keep it here.")
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
                        Image(systemName: "xmark").font(.title3)
                    }
                    .accessibilityLabel("Close the filter")
                    Spacer()
                    Text("Sort By")
                    Picker("Sort By", selection: $oldestFirst) {
                        Text("Recent").tag(false)
                        Text("Oldest").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("All", selected: sender == nil) { sender = nil }
                        ForEach(library.senders, id: \.self) { name in
                            chip(name, selected: sender == name) { sender = name }
                        }
                    }
                }
            } else {
                Button {
                    withAnimation { filtering = true }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .frame(width: 52, height: 52)
                        .background(Color.black, in: Circle())
                }
                .accessibilityLabel("Sort and filter")
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? Style.ink : Style.secondary)
                .background(selected ? Color.white : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(Style.secondary, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private func empty(_ title: String, _ detail: String) -> some View {
        VStack(spacing: 14) {
            Text(title).font(.title3).foregroundStyle(.white)
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
            sender: message.sender,
            date: message.date,
            favorite: message.favorite,
            onFavorite: { library.toggleFavorite(message.characters, boardName: message.boardName) },
            shareText: message.editableText,
            actions: [
                CardAction(symbol: "square.on.square.fill", label: "Copy into a new message") {
                    composing = ComposeRequest(text: message.editableText)
                },
                CardAction(symbol: "paperplane.fill", label: "Send to the board") {
                    Task { await resend(message) }
                },
            ]
        ) {
            Button(message.favorite ? "Remove from Favorites" : "Add to Favorites", systemImage: "bookmark") {
                library.toggleFavorite(message.characters, boardName: message.boardName)
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                library.delete(message)
            }
        }
    }

    private func draftCard(_ draft: Draft) -> some View {
        MessageCard(
            characters: Layout.grid(draft.text, rows: shape.rows, cols: shape.cols).grid,
            heart: shape.heart,
            sender: "Draft",
            date: draft.date,
            shareText: draft.text,
            actions: [
                CardAction(symbol: "pencil", label: "Edit") {
                    composing = ComposeRequest(text: draft.text, draft: draft.id)
                },
                CardAction(symbol: "paperplane.fill", label: "Send to the board") {
                    Task {
                        if let outcome = await sendText(draft.text) {
                            notice = outcome
                        } else {
                            library.deleteDraft(draft.id)
                        }
                    }
                },
            ]
        ) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                library.deleteDraft(draft.id)
            }
        }
    }

    // MARK: - Bars and buttons

    private var composeButton: some View {
        Button {
            composing = ComposeRequest()
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.title)
                .foregroundStyle(Style.ink)
                .frame(width: 68, height: 68)
                .background(Color.white, in: Circle())
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        }
        .accessibilityLabel("Write a message")
    }

    private var bottomBar: some View {
        HStack {
            VStack(spacing: 10) {
                Rectangle().fill(Color.white).frame(width: 40, height: 3)
                Image(systemName: "house.fill").font(.title2)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Home")
            if boards.count > 1 {
                Menu {
                    Picker("Board", selection: $boardID) {
                        ForEach(boards) { each in
                            Text(each.name).tag(each.id)
                        }
                    }
                } label: {
                    Image(systemName: "square.grid.3x3").font(.title2).padding(.top, 13)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Board")
            }
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape").font(.title2).padding(.top, 13)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Settings")
        }
        .foregroundStyle(Color.white.opacity(0.75))
        .padding(.bottom, 6)
        .frame(height: 64, alignment: .top)
        .background(Style.bar.ignoresSafeArea())
    }

    // MARK: - FiestaBoard

    private func load() async {
        if Demo.on {
            Demo.fill(library)
            board = Demo.board
            if Demo.compose && composing == nil {
                composing = ComposeRequest(text: "Kaffee ist fertig {red}")
            }
            return
        }
        do {
            let api = try settings.api()
            async let detail = api.board(boardID)
            async let list = api.boards()
            let read = try await detail
            board = read
            if let characters = read.characters {
                library.seen(characters, boardName: read.name)
            }
            boards = (try? await list) ?? boards
            problem = nil
            // The alias, until the boards are known: then the primary one's id, for the picker.
            if boardID == "primary", let primary = boards.first(where: \.isPrimary) {
                boardID = primary.id
            }
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            problem = error.localizedDescription
        }
    }

    /// Sends text; nil when it reached the board, else what came of it.
    private func sendText(_ text: String) async -> String? {
        if Demo.on {
            library.sent(Layout.grid(text, rows: shape.rows, cols: shape.cols).grid, text: text, boardName: boardName)
            return nil
        }
        do {
            let response = try await settings.api().send(text, to: boardID)
            return await sent(response, text: text)
        } catch {
            return error.localizedDescription
        }
    }

    /// Sends a kept message again: flap for flap to a board of its size, else its text.
    private func resend(_ message: SavedMessage) async {
        do {
            let api = try settings.api()
            let sameSize = message.characters.count == shape.rows && message.characters.first?.count == shape.cols
            let response = sameSize
                ? try await api.send(characters: message.characters, to: boardID)
                : try await api.send(message.editableText, to: boardID)
            notice = await sent(response, text: message.editableText) ?? "Sent to \(boardName)"
        } catch {
            notice = error.localizedDescription
        }
    }

    private func sent(_ response: MessageResponse, text: String) async -> String? {
        if response.sent || response.held == true {
            library.sent(response.characters, text: text, boardName: boardName)
            if response.held == true {
                notice = "Held until the board's quiet time ends"
            }
            await load()
            return nil
        }
        return response.reason ?? "Not sent"
    }
}
