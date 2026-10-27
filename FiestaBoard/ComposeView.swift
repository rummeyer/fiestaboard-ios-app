import SwiftUI

/// "Send" and the plane after it, as on Vestaboard's button.
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

/// Writing a message, as in Vestaboard's compose: the text, how much of the
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

    private static let palette: [(String, Color)] = [
        ("white", .white),
        ("red", Color(red: 0.85, green: 0.16, blue: 0.11)),
        ("orange", Color(red: 1.0, green: 0.46, blue: 0.0)),
        ("yellow", Color(red: 1.0, green: 0.72, blue: 0.11)),
        ("green", Color(red: 0.0, green: 0.6, blue: 0.27)),
        ("blue", Color(red: 0.0, green: 0.34, blue: 0.72)),
        ("violet", Color(red: 0.44, green: 0.18, blue: 0.54)),
        ("black", Color(white: 0.08)),
    ]

    var body: some View {
        let laid = Layout.grid(text, rows: shape.rows, cols: shape.cols)
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(boardName)
                Circle().fill(Style.live).frame(width: 7, height: 7)
            }
            .font(.footnote)
            .foregroundStyle(.white)
            .padding(.vertical, 12)

            BoardView(characters: laid.grid, rows: shape.rows, cols: shape.cols, heart: shape.heart)
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
                    .foregroundStyle(.white)
            }
            .font(.title3)
            .padding(.horizontal, 24)

            HStack {
                if laid.overflow {
                    Label("Too long: the end is cut off", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else if let problem {
                    Label(problem, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                }
                Spacer()
                Text("\(Layout.tiles(of: text.replacingOccurrences(of: "\n", with: "")).count)/\(shape.rows * shape.cols)")
                    .monospacedDigit()
                    .foregroundStyle(Style.secondary)
            }
            .font(.footnote)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            HStack(spacing: 28) {
                Button("Cancel") { dismiss() }
                Button("Clear") { text = "" }
                    .disabled(text.isEmpty)
                Spacer()
                HStack(spacing: 0) {
                    Button(action: submit) {
                        Group {
                            if sending {
                                ProgressView().tint(.white)
                            } else {
                                Label {
                                    Text("Send").fixedSize()
                                } icon: {
                                    Image(systemName: "paperplane.fill")
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
                    Rectangle().fill(Color.black.opacity(0.3)).frame(width: 1, height: 48)
                    Menu {
                        Button("Save Draft", systemImage: "square.and.arrow.down") {
                            library.saveDraft(text, replacing: request.draft)
                            dismiss()
                        }
                        .disabled(text.isEmpty)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.footnote)
                            .frame(width: 44, height: 48)
                    }
                    .accessibilityLabel("More ways to send")
                }
                .background(Style.control, in: RoundedRectangle(cornerRadius: 8))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            HStack(spacing: 10) {
                ForEach(Self.palette, id: \.0) { name, colour in
                    Button {
                        text += "{\(name)}"
                    } label: {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(colour)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.25), lineWidth: name == "black" ? 1 : 0))
                            .frame(height: 38)
                    }
                    .accessibilityLabel("\(name.capitalized) tile")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black)
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
