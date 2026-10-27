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

/// What to start writing from: a new message, a copy of one, or a draft.
struct ComposeRequest: Identifiable {
    let id = UUID()
    var text = ""
    var draft: Draft.ID?
}

/// Writing a message: the text, how much of the
/// board it takes, Cancel, Clear and Send, and the colours to put in — with
/// the board above showing where it will land.
struct ComposeView: View {
    let request: ComposeRequest
    let shape: BoardShape
    let boardName: String
    /// Sends the text; says what came of it, nil when it reached the board.
    let send: (String) async -> String?

    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var sending = false
    @State private var problem: String?
    @FocusState private var writing: Bool

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

    var body: some View {
        let laid = Layout.grid(text, rows: shape.rows, cols: shape.cols)
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(boardName)
                Circle().fill(Style.live).frame(width: 7, height: 7)
            }
            .font(Style.font(.footnote))
            .foregroundStyle(Style.ink)
            .padding(.vertical, 12)

            BoardView(characters: laid.grid, rows: shape.rows, cols: shape.cols, heart: shape.heart, white: shape.heart)
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

            HStack(spacing: 24) {
                Button("Cancel") { dismiss() }
                    .fixedSize()
                Button("Clear") { text = "" }
                    .fixedSize()
                    .disabled(text.isEmpty)
                Spacer()
                HStack(spacing: 0) {
                    Button(action: submit) {
                        Group {
                            if sending {
                                ProgressView().tint(Style.primaryInk)
                            } else {
                                Label {
                                    Text("Send").fixedSize()
                                } icon: {
                                    LucideIcon("send", size: 20, relativeTo: .body)
                                }
                                .labelStyle(SendLabelStyle())
                            }
                        }
                        .padding(.horizontal, 22)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(sending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Rectangle().fill(Style.primaryInk.opacity(0.2)).frame(width: 1, height: 48)
                    Menu {
                        Button {
                            library.saveDraft(text, replacing: request.draft)
                            dismiss()
                        } label: {
                            Label("Save Draft", lucide: "save")
                        }
                        .disabled(text.isEmpty)
                    } label: {
                        LucideIcon("chevron-down", size: 18, relativeTo: .footnote)
                            .frame(width: 44, height: 48)
                    }
                    .accessibilityLabel("More ways to send")
                }
                .foregroundStyle(Style.primaryInk)
                .background(Style.primary, in: RoundedRectangle(cornerRadius: Style.radius))
            }
            .foregroundStyle(Style.ink)
            .lineLimit(1)
            // Larger text, but the buttons stay on one line beside each other.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            HStack(spacing: 10) {
                ForEach(Self.palette, id: \.0) { name, colour, spoken in
                    Button {
                        text += "{\(name)}"
                    } label: {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(colour)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Style.border, lineWidth: 1))
                            .frame(height: 38)
                    }
                    .accessibilityLabel(spoken)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Style.card)
            .overlay(alignment: .top) { Rectangle().fill(Style.border).frame(height: 1) }
        }
        .background(Style.background.ignoresSafeArea())
        .onAppear {
            text = request.text
            writing = true
        }
    }

    private func submit() {
        sending = true
        problem = nil
        Task {
            defer { sending = false }
            if let outcome = await send(text) {
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
