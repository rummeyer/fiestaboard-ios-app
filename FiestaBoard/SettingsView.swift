import SwiftUI

/// FiestaBoard's address and the API token, tried before they are kept, and
/// the demo board beside FiestaBoard's boards — or alone, without a FiestaBoard.
struct SettingsView: View {
    var isFirstRun = false
    /// The boards there are, to say how each looks.
    var boards: [BoardSummary] = []

    @Environment(Settings.self) private var settings
    @Environment(TipJar.self) private var tips
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var localAddress = ""
    @State private var token = ""
    @State private var demoBoard = false
    @State private var looks: [String: BoardLook] = [:]
    @State private var checking = false
    @State private var problem: String?

    /// Something of FiestaBoard filled in, to be tried; nothing, for the demo board alone.
    private var withFiestaBoard: Bool {
        [localAddress, address, token].contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private var canSave: Bool {
        withFiestaBoard ? (!localAddress.isEmpty || !address.isEmpty) && !token.isEmpty : demoBoard
    }

    var body: some View {
        Form {
            // Where FiestaBoard is and the key to it.
            Section {
                // As iOS's own forms have it: the label on the left, what is typed on the right,
                // in one line however long the address — it scrolls in its field rather than going below.
                // One or both: at home the local server, from anywhere the remote one.
                HStack(spacing: 16) {
                    Text("Local Server").fixedSize()
                    TextField(text: $localAddress) {
                        Text(verbatim: "10.0.1.10:4420")
                    }
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                }
                HStack(spacing: 16) {
                    Text("Remote Server").fixedSize()
                    TextField(text: $address) {
                        Text(verbatim: "fiestaboard.rummeyer.de")
                    }
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                }
                HStack(spacing: 16) {
                    Text("API token").fixedSize()
                    SecureField("Required", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
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
                } header: {
                    Text("About")
                }
                // Only where the App Store offers the tips.
                if !tips.products.isEmpty {
                    Section {
                        TipRows()
                    } header: {
                        Text("Donation")
                    }
                }
            }
        }
        .tipping(tips)
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
            localAddress = settings.localAddress
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

    /// FiestaBoard kept only once it has answered with this token, at one of its addresses; nothing of it, for the demo board alone.
    private func save() {
        problem = nil
        guard withFiestaBoard else {
            settings.save(local: "", remote: "", token: "")
            settings.demoBoard = demoBoard
            settings.looks = looks
            close()
            return
        }
        checking = true
        Task {
            defer { checking = false }
            do {
                // Kept once one of them answers: at home the local one, away the remote one.
                guard let servers = try FiestaBoardServers(local: localAddress, remote: address, token: token) else {
                    throw APIError.badAddress
                }
                _ = try await servers.boards()
                settings.save(local: localAddress, remote: address, token: token)
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
