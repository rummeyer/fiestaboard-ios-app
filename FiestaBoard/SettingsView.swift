import SwiftUI

/// FiestaBoard's address and the API token, tried before they are kept, and
/// the demo board beside FiestaBoard's boards — or alone, without a FiestaBoard.
struct SettingsView: View {
    var isFirstRun = false

    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var token = ""
    @State private var demoBoard = false
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
            Section {
                TextField("10.0.1.10:4420 or https://…", text: $address)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Server")
            } footer: {
                Text("FiestaBoard's address: https:// from anywhere, or its address at home, such as 10.0.1.10:4420, on your network or through a VPN.")
            }
            Section {
                SecureField("Token", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("API token")
            } footer: {
                Text("Made in FiestaBoard under Settings → AI. Kept in this iPhone's Keychain.")
            }
            Section {
                Toggle("Add demo board", isOn: $demoBoard)
                    .tint(Style.primary)
            } footer: {
                Text("A board simulated in this app, beside your FiestaBoard's boards or without a FiestaBoard at all, to try everything out. It has its own history.")
            }
            if let problem {
                Section {
                    Label(problem, lucide: "triangle-alert")
                        .foregroundStyle(.red)
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
        }
    }

    /// FiestaBoard kept only once it has answered with this token; nothing of it, for the demo board alone.
    private func save() {
        problem = nil
        guard withFiestaBoard else {
            settings.save(address: "", token: "")
            settings.demoBoard = demoBoard
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
