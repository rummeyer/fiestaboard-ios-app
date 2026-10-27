import SwiftUI

/// "Send" and the plane after it.
private struct SendLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.title
            configuration.icon
        }
    }
}

extension View {
    /// A secondary action as FiestaBoard draws one: outlined, as tall as Send; widening to share a row of its own.
    func secondaryButton(wide: Bool = false) -> some View {
        self
            .font(Style.font(.body))
            .foregroundStyle(Style.ink)
            .fixedSize()
            .padding(.horizontal, 18)
            .frame(maxWidth: wide ? .infinity : nil)
            .frame(height: 48)
            .background(Style.card, in: RoundedRectangle(cornerRadius: Style.radius))
            .overlay(RoundedRectangle(cornerRadius: Style.radius).stroke(Style.border, lineWidth: 1))
            .contentShape(Rectangle())
    }
}

/// What a message is sent as: text, laid out by FiestaBoard, or the board drawn tile by tile.
enum Outgoing {
    case text(String)
    case grid([[Int]])
}

/// What to start writing from: a new message, a copy of one, or a draft.
struct ComposeRequest: Identifiable {
    let id = UUID()
    var text = ""
    /// The board drawn tile by tile: opens the visual editor.
    var characters: [[Int]]?
    var draft: Draft.ID?
}

/// Writing a message, as text or tile by tile. As text: the board above shows
/// where it will land, the colours put a tile in. Visually: the board is the
/// canvas — a colour or the eraser painted where it is touched, letters typed
/// from the tile chosen — with undo and redo. Both: Cancel, Clear, Send for a
/// while or until the next refresh, and Save Draft.
struct ComposeView: View {
    enum Mode: Hashable {
        case text, visual
    }

    let request: ComposeRequest
    let shape: BoardShape
    let boardName: String
    /// Sends the message, for so many minutes or until the next refresh; says what came of it, nil when it reached the board.
    let send: (Outgoing, Int?) async -> String?

    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var mode = Mode.text
    @State private var text = ""
    @State private var grid: [[Int]] = []
    @State private var tool = EditorTool.letters
    @State private var cursor: Cell?
    @State private var undoStack: [[[Int]]] = []
    @State private var redoStack: [[[Int]]] = []
    /// What the hidden field for letters holds between two keys: one invisible character, so that backspace can be seen.
    @State private var letters = ComposeView.keep
    @State private var sending = false
    /// Minutes the message holds against the schedule; none, until the next refresh.
    @State private var minutes: Int?
    @State private var problem: String?
    @FocusState private var writing: Bool
    @FocusState private var typing: Bool

    private static let keep = "\u{200B}"

    /// The marker, the tile's colour, and what VoiceOver calls it.
    private static let palette: [(String, Color, LocalizedStringKey)] = [
        ("white", Color(white: 0.98), "White tile"),
        ("red", Color(red: 0.85, green: 0.16, blue: 0.11), "Red tile"),
        ("orange", Color(red: 1.0, green: 0.46, blue: 0.0), "Orange tile"),
        ("yellow", Color(red: 1.0, green: 0.72, blue: 0.11), "Yellow tile"),
        ("green", Color(red: 0.0, green: 0.6, blue: 0.27), "Green tile"),
        ("blue", Color(red: 0.0, green: 0.34, blue: 0.72), "Blue tile"),
        ("violet", Color(red: 0.44, green: 0.18, blue: 0.54), "Violet tile"),
        ("black", Color(white: 0.08), "Black tile"),
    ]

    private var blank: [[Int]] {
        Array(repeating: Array(repeating: 0, count: shape.cols), count: shape.rows)
    }

    private var isEmpty: Bool {
        switch mode {
        case .text: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .visual: !grid.contains { $0.contains { $0 != 0 } }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(boardName)
                Circle().fill(Style.live).frame(width: 7, height: 7)
            }
            .font(Style.font(.footnote))
            .foregroundStyle(Style.ink)
            .padding(.top, 12)

            Picker("Mode", selection: Binding(get: { mode }, set: switchMode)) {
                Text("Text").tag(Mode.text)
                Text("Visual").tag(Mode.visual)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            switch mode {
            case .text:
                textEditor
            case .visual:
                visualEditor
            }

            durationChoice
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            // In one row where the words fit, else Send across the width and the other two below it:
            // German and French words are longer than English ones, and text can be larger.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    cancelButton(wide: false)
                    clearButton(wide: false)
                    Spacer(minLength: 0)
                    sendButton
                }
                VStack(spacing: 10) {
                    sendButton
                    HStack(spacing: 10) {
                        cancelButton(wide: true)
                        clearButton(wide: true)
                    }
                }
            }
            .lineLimit(1)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            paletteBar
        }
        .background(Style.background.ignoresSafeArea())
        .onAppear {
            text = request.text
            if let characters = request.characters {
                mode = .visual
                grid = Layout.fit(characters, rows: shape.rows, cols: shape.cols)
            } else {
                writing = true
            }
        }
    }

    // MARK: - As text

    @ViewBuilder
    private var textEditor: some View {
        let laid = Layout.grid(text, rows: shape.rows, cols: shape.cols)
        BoardView(characters: laid.grid, rows: shape.rows, cols: shape.cols, heart: shape.heart, white: shape.heart, led: shape.led)
            .padding(.horizontal)
            .padding(.bottom, 12)

        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Write a message")
                    .foregroundStyle(Style.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($writing)
                .foregroundStyle(Style.ink)
        }
        .font(Style.font(.title3))
        .padding(.horizontal, 24)

        HStack {
            if laid.overflow {
                Label("Too long: the end is cut off", lucide: "triangle-alert")
                    .foregroundStyle(.orange)
            } else if let problem {
                Label(problem, lucide: "circle-alert")
                    .foregroundStyle(.red)
            }
            Spacer()
            Text("\(Layout.tiles(of: text.replacingOccurrences(of: "\n", with: "")).count)/\(shape.rows * shape.cols)")
                .monospacedDigit()
                .foregroundStyle(Style.secondary)
        }
        .font(Style.font(.footnote))
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    // MARK: - Tile by tile

    @ViewBuilder
    private var visualEditor: some View {
        BoardEditor(grid: grid, shape: shape, cursor: tool == .letters ? cursor : nil, begin: beginStroke, touch: touch)
            .padding(.horizontal)
            .padding(.bottom, 12)

        HStack(spacing: 14) {
            Button(action: undo) {
                LucideIcon("undo-2", size: 22, relativeTo: .title3)
            }
            .disabled(undoStack.isEmpty)
            .accessibilityLabel("Undo")
            Button(action: redo) {
                LucideIcon("redo-2", size: 22, relativeTo: .title3)
            }
            .disabled(redoStack.isEmpty)
            .accessibilityLabel("Redo")
            Group {
                if let problem {
                    Label(problem, lucide: "circle-alert")
                        .foregroundStyle(.red)
                } else if tool == .letters {
                    Text("Tap a tile, then type.")
                } else {
                    Text("Tap or drag across the tiles to paint them.")
                }
            }
            .font(Style.font(.footnote))
            .foregroundStyle(Style.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Style.ink)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .background {
            // Takes the letters typed while the letter tool is chosen; never seen.
            TextField("", text: $letters)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($typing)
                .opacity(0.01)
                .frame(width: 1, height: 1)
                .onChange(of: letters) { _, typed in
                    take(typed)
                }
        }

        Spacer(minLength: 0)
    }

    private func switchMode(_ new: Mode) {
        guard new != mode else {
            return
        }
        problem = nil
        switch new {
        case .visual:
            // The text as it lands on the board, to go on with tile by tile.
            grid = Layout.grid(text, rows: shape.rows, cols: shape.cols).grid
            undoStack = []
            redoStack = []
            writing = false
            if tool == .letters {
                cursor = cursor ?? Cell(row: 0, col: 0)
                typing = true
            }
        case .text:
            text = Layout.text(of: grid)
            typing = false
            writing = true
        }
        mode = new
    }

    private func choose(_ new: EditorTool) {
        tool = new
        if new == .letters {
            cursor = cursor ?? Cell(row: 0, col: 0)
            typing = true
        } else {
            typing = false
        }
    }

    private func beginStroke() {
        if tool != .letters {
            remember()
        }
    }

    private func touch(_ cell: Cell) {
        switch tool {
        case let .colour(code):
            grid[cell.row][cell.col] = code
        case .eraser:
            grid[cell.row][cell.col] = 0
        case .letters:
            cursor = cell
            typing = true
        }
    }

    /// The keys typed into the hidden field: letters from the cursor on, a new line for return, backspace back.
    private func take(_ typed: String) {
        guard typed != Self.keep else {
            return
        }
        if typed.isEmpty {
            backspace()
        } else {
            for character in typed.replacingOccurrences(of: Self.keep, with: "") {
                put(character)
            }
        }
        letters = Self.keep
    }

    private func put(_ character: Character) {
        guard var at = cursor else {
            return
        }
        if character.isNewline {
            if at.row + 1 < shape.rows {
                cursor = Cell(row: at.row + 1, col: 0)
            }
            return
        }
        remember()
        grid[at.row][at.col] = Layout.code(of: character)
        if at.col + 1 < shape.cols {
            at.col += 1
        } else if at.row + 1 < shape.rows {
            at = Cell(row: at.row + 1, col: 0)
        }
        cursor = at
    }

    private func backspace() {
        guard var at = cursor else {
            return
        }
        if at.col > 0 {
            at.col -= 1
        } else if at.row > 0 {
            at = Cell(row: at.row - 1, col: shape.cols - 1)
        }
        remember()
        grid[at.row][at.col] = 0
        cursor = at
    }

    /// The board as it is, for undo; a new change forgets what was undone.
    private func remember() {
        undoStack.append(grid)
        if undoStack.count > 100 {
            undoStack.removeFirst()
        }
        redoStack = []
    }

    private func undo() {
        guard let last = undoStack.popLast() else {
            return
        }
        redoStack.append(grid)
        grid = last
    }

    private func redo() {
        guard let next = redoStack.popLast() else {
            return
        }
        undoStack.append(grid)
        grid = next
    }

    // MARK: - Below

    /// The colours: as text, each puts a tile in; tile by tile, the one chosen paints, beside the eraser and the letters.
    private var paletteBar: some View {
        HStack(spacing: mode == .visual ? 6 : 10) {
            ForEach(Self.palette, id: \.0) { name, colour, spoken in
                let code = Layout.colours[name] ?? 0
                Button {
                    switch mode {
                    case .text: text += "{\(name)}"
                    case .visual: choose(.colour(code))
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(colour)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Style.border, lineWidth: 1))
                        .padding(3)
                        .overlay {
                            if mode == .visual && tool == .colour(code) {
                                RoundedRectangle(cornerRadius: 7).stroke(Style.primary, lineWidth: 2.5)
                            }
                        }
                        .frame(height: 44)
                }
                .accessibilityLabel(spoken)
                .accessibilityAddTraits(mode == .visual && tool == .colour(code) ? .isSelected : [])
            }
            if mode == .visual {
                toolButton(.eraser, icon: "eraser", label: "Eraser")
                toolButton(.letters, icon: "type", label: "Letters")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Style.card)
        .overlay(alignment: .top) { Rectangle().fill(Style.border).frame(height: 1) }
    }

    private func toolButton(_ which: EditorTool, icon: String, label: LocalizedStringKey) -> some View {
        Button {
            choose(which)
        } label: {
            LucideIcon(icon, size: 20, relativeTo: .body)
                .foregroundStyle(tool == which ? Style.primaryInk : Style.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(tool == which ? Style.primary : Style.fill, in: RoundedRectangle(cornerRadius: 5))
                .padding(3)
                .frame(height: 44)
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(tool == which ? .isSelected : [])
    }

    /// How long a message holds against the schedule or carousel: until its next refresh, as by
    /// default, or for a while, after which the board goes back to it by itself.
    private static let durations: [(Int?, LocalizedStringKey)] = [
        (nil, "Until the next refresh"),
        (15, "For 15 minutes"),
        (60, "For 1 hour"),
        (240, "For 4 hours"),
        (480, "For 8 hours"),
    ]

    private var durationChoice: some View {
        Menu {
            Picker("Show", selection: $minutes) {
                ForEach(Self.durations, id: \.0) { value, title in
                    Text(title).tag(value)
                }
            }
        } label: {
            HStack(spacing: 8) {
                LucideIcon("timer", size: 18, relativeTo: .subheadline)
                Text(Self.durations.first { $0.0 == minutes }?.1 ?? "Until the next refresh")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                LucideIcon("chevron-down", size: 14, relativeTo: .subheadline)
            }
            .font(Style.font(.subheadline))
            .foregroundStyle(minutes == nil ? Style.muted : Style.ink)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(minutes == nil ? Color.clear : Style.fill, in: Capsule())
            .overlay(Capsule().stroke(Style.border, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Show")
    }

    private func cancelButton(wide: Bool) -> some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel").secondaryButton(wide: wide)
        }
        .buttonStyle(.plain)
    }

    private func clearButton(wide: Bool) -> some View {
        Button {
            switch mode {
            case .text:
                text = ""
            case .visual:
                remember()
                grid = blank
                cursor = tool == .letters ? Cell(row: 0, col: 0) : nil
            }
        } label: {
            Text("Clear").secondaryButton(wide: wide)
        }
        .buttonStyle(.plain)
        .disabled(isEmpty)
        .opacity(isEmpty ? 0.5 : 1)
    }

    /// Send, and beside it the arrow for Save Draft, in FiestaBoard orange.
    private var sendButton: some View {
        HStack(spacing: 0) {
            Button(action: submit) {
                Group {
                    if sending {
                        ProgressView().tint(Style.primaryInk)
                    } else {
                        Label {
                            // Its whole width, so that a row too narrow for it is seen to be.
                            Text("Send").fixedSize()
                        } icon: {
                            LucideIcon("send", size: 20, relativeTo: .body)
                        }
                        .labelStyle(SendLabelStyle())
                    }
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(sending || isEmpty)
            Rectangle().fill(Style.primaryInk.opacity(0.2)).frame(width: 1, height: 48)
            Menu {
                Button {
                    switch mode {
                    case .text: library.saveDraft(text, replacing: request.draft)
                    case .visual: library.saveDraft(Layout.text(of: grid), characters: grid, replacing: request.draft)
                    }
                    dismiss()
                } label: {
                    Label("Save Draft", lucide: "save")
                }
                .disabled(isEmpty)
            } label: {
                LucideIcon("chevron-down", size: 18, relativeTo: .footnote)
                    .frame(width: 44, height: 48)
            }
            .accessibilityLabel("More ways to send")
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Style.primaryInk)
        .background(Style.primary, in: RoundedRectangle(cornerRadius: Style.radius))
    }

    private func submit() {
        sending = true
        problem = nil
        let outgoing: Outgoing = mode == .text ? .text(text) : .grid(grid)
        Task {
            defer { sending = false }
            if let outcome = await send(outgoing, minutes) {
                problem = outcome
            } else {
                if let draft = request.draft {
                    library.deleteDraft(draft)
                }
                dismiss()
            }
        }
    }
}
