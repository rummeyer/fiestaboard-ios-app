import SwiftUI

/// The server's address and the API token, tried before they are kept.
struct SettingsView: View {
    var isFirstRun = false

    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var token = ""
    @State private var checking = false
    @State private var problem: String?

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
            if let problem {
                Section {
                    Label(problem, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(isFirstRun ? "FiestaBoard" : "Settings")
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
                    Button(isFirstRun ? "Connect" : "Save", action: connect)
                        .disabled(address.isEmpty || token.isEmpty)
                }
            }
        }
        .onAppear {
            address = settings.address
            token = settings.token
        }
    }

    /// Kept only once the server has answered with this token.
    private func connect() {
        problem = nil
        checking = true
        Task {
            defer { checking = false }
            do {
                let api = try FiestaBoardAPI(address: address, token: token)
                _ = try await api.boards()
                settings.save(address: address, token: token)
                if !isFirstRun {
                    dismiss()
                }
            } catch {
                problem = error.localizedDescription
            }
        }
    }
}
