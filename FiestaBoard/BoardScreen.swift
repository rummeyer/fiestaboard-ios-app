import SwiftUI

/// What the board shows, and a message to send to it.
struct BoardScreen: View {
    @Environment(Settings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("board") private var boardID = "primary"

    @State private var boards: [BoardSummary] = []
    @State private var board: BoardDetail?
    @State private var problem: String?
    @State private var message = ""
    @State private var sending = false
    @State private var outcome: Outcome?
    @State private var showingSettings = false
    @FocusState private var writing: Bool

    /// How often the board is read again while the app is open.
    private let refreshSeconds = 15

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let board {
                        BoardView(
                            characters: board.characters ?? [],
                            rows: board.rows,
                            cols: board.cols,
                            heart: board.deviceType.hasPrefix("note")
                        )
                        status(of: board)
                    } else if problem == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    }
                    if let problem {
                        Label(problem, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                    composer
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await load() }
            .navigationTitle(board?.name ?? "FiestaBoard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if boards.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Picker("Board", selection: $boardID) {
                                ForEach(boards) { each in
                                    Text(each.name).tag(each.id)
                                }
                            }
                        } label: {
                            Label("Board", systemImage: "square.grid.3x3")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
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

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.headline)
            TextField("Text for the board", text: $message, axis: .vertical)
                .lineLimit(2...6)
                .textInputAutocapitalization(.characters)
                .focused($writing)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            HStack {
                if let outcome {
                    Label(outcome.text, systemImage: outcome.ok ? "checkmark.circle" : "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(outcome.ok ? Color.secondary : Color.red)
                }
                Spacer()
                Button(action: send) {
                    if sending {
                        ProgressView()
                    } else {
                        Label("Send", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(sending || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func status(of board: BoardDetail) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if board.paused {
                Label("Paused", systemImage: "pause.circle")
            }
            if let until = board.overrideExpiresAt.flatMap(Self.date) {
                Label("Message until \(until.formatted(date: .omitted, time: .shortened))", systemImage: "timer")
            } else if board.source == "schedule" {
                Label("Following the schedule", systemImage: "calendar")
            } else if board.source == "manual" {
                Label("Showing a chosen page", systemImage: "pin")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func load() async {
        do {
            let api = try settings.api()
            async let detail = api.board(boardID)
            async let list = api.boards()
            board = try await detail
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

    private func send() {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        sending = true
        outcome = nil
        Task {
            defer { sending = false }
            do {
                let response = try await settings.api().send(text, to: boardID)
                if response.sent {
                    outcome = Outcome(ok: true, text: "Sent")
                    message = ""
                    writing = false
                } else if response.held == true {
                    outcome = Outcome(ok: true, text: "Held until the board's quiet time ends")
                    message = ""
                } else {
                    outcome = Outcome(ok: false, text: response.reason ?? "Not sent")
                }
                await load()
            } catch {
                outcome = Outcome(ok: false, text: error.localizedDescription)
            }
        }
    }

    private static func date(_ text: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}

private struct Outcome {
    let ok: Bool
    let text: String
}
