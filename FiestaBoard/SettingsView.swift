import SwiftUI

/// FiestaBoard's address and the API token, tried before they are kept, and
/// the demo board beside FiestaBoard's boards — or alone, without a FiestaBoard.
struct SettingsView: View {
    var isFirstRun = false
    /// The boards there are, to say how each looks.
    var boards: [BoardSummary] = []

    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var token = ""
    @State private var demoBoard = false
    @State private var looks: [String: BoardLook] = [:]
    @State private var checking = false
    @State private var problem: String?

    /// Something of FiestaBoard filled in, to be tried; nothing, for the demo board alone.
    private var withFiestaBoard: Bool {
        !address.trimmingCharacters(in: .whitespaces).isEmpty || !token.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canSave: Bool {
        withFiestaBoard ? !address.isEmpty && !token.isEmpty : demoBoard
    }

    var body: some View {
        Form {
            // Where FiestaBoard is and the key to it.
            Section {
                LabeledContent("Server") {
                    TextField("10.0.1.10:4420 or https://…", text: $address)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                LabeledContent("API token") {
                    SecureField("Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Connection")
            }
            if let problem {
                Section {
                    Label(problem, lucide: "triangle-alert")
                        .foregroundStyle(.red)
                }
            }
            if !flapBoards.isEmpty {
                Section {
                    ForEach(flapBoards) { board in
                        lookRows(board)
                    }
                } header: {
                    Text("Boards")
                }
            }
            Section {
                Toggle("Add demo board", isOn: $demoBoard)
                    .tint(Style.primary)
            } header: {
                Text("Demo")
            }
            if !isFirstRun {
                Section {
                    LabeledContent("Version", value: Self.version)
                    Link(destination: URL(string: "https://github.com/rummeyer/fiestaboard-ios-app")!) {
                        Label("Source code", lucide: "code")
                    }
                    Link(destination: URL(string: "https://buymeacoffee.com/rummeyer")!) {
                        Label("Buy me a coffee", lucide: "coffee")
                    }
                } header: {
                    Text("About")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Style.background)
        .navigationTitle(isFirstRun ? Text(verbatim: "FiestaBoard") : Text("Settings"))
        .toolbar {
            if !isFirstRun {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if checking {
                    ProgressView()
                } else {
                    Button(action: save) {
                        if !isFirstRun {
                            Text("Save")
                        } else if withFiestaBoard {
                            Text("Connect")
                        } else {
                            Text("Start")
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            address = settings.address
            token = settings.token
            demoBoard = settings.demoBoard
            looks = settings.looks
        }
    }

    /// The version and build, as the App Store would show them.
    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }

    /// Split-flap boards: an LED panel has no flaps to colour.
    private var flapBoards: [BoardSummary] {
        boards.filter { $0.deviceType != "panel" }
    }

    @ViewBuilder
    private func lookRows(_ board: BoardSummary) -> some View {
        let look = Binding {
            looks[board.id] ?? settings.look(for: board.id, deviceType: board.deviceType)
        } set: {
            looks[board.id] = $0
        }
        Picker(selection: look.white) {
            Text("Black").tag(false)
            Text("White").tag(true)
        } label: {
            Text(verbatim: board.name)
        }
        Picker("Code 62", selection: look.heart) {
            (Text(verbatim: "❤ ") + Text("Heart")).tag(true)
            (Text(verbatim: "° ") + Text("Degree sign")).tag(false)
        }
    }

    /// FiestaBoard kept only once it has answered with this token; nothing of it, for the demo board alone.
    private func save() {
        problem = nil
        guard withFiestaBoard else {
            settings.save(address: "", token: "")
            settings.demoBoard = demoBoard
            settings.looks = looks
            close()
            return
        }
        checking = true
        Task {
            defer { checking = false }
            do {
                let api = try FiestaBoardAPI(address: address, token: token)
                _ = try await api.boards()
                settings.save(address: address, token: token)
                settings.demoBoard = demoBoard
                settings.looks = looks
                close()
            } catch {
                problem = error.localizedDescription
            }
        }
    }

    private func close() {
        if !isFirstRun {
            dismiss()
        }
    }
}
