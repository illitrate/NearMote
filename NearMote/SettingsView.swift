//
//  SettingsView.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sshService: SSHService

    @State private var hostname: String = ""
    @State private var username: String = ""
    @State private var authMethod: AuthMethod = .password
    @State private var password: String = ""
    @State private var privateKey: String = ""
    @State private var showingSaveSuccess = false
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var isTesting = false

    private let keychainManager: KeychainManager

    init(sshService: SSHService, keychainManager: KeychainManager) {
        self.sshService = sshService
        self.keychainManager = keychainManager

        // Load existing credentials
        if let credentials = keychainManager.loadCredentials() {
            _hostname = State(initialValue: credentials.hostname)
            _username = State(initialValue: credentials.username)
            _authMethod = State(initialValue: credentials.authMethod)
            _password = State(initialValue: credentials.password ?? "")
            _privateKey = State(initialValue: credentials.privateKey ?? "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Hostname or IP", text: $hostname)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("SSH Connection")
                } footer: {
                    Text("Enter the hostname or IP address of your Mac. Ensure Remote Login is enabled in System Settings > Sharing.")
                }

                Section {
                    Picker("Authentication Method", selection: $authMethod) {
                        Text("Password").tag(AuthMethod.password)
                        Text("SSH Key").tag(AuthMethod.privateKey)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Authentication")
                } footer: {
                    Text(authMethod == .password ?
                         "Use your Mac account password." :
                         "Use SSH private key (more secure, no password needed).")
                }

                if authMethod == .password {
                    Section {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                    } footer: {
                        Text("Your Mac account password. Stored securely in iOS Keychain.")
                    }
                } else {
                    Section {
                        TextEditor(text: $privateKey)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 120)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } header: {
                        Text("Private Key")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Paste your SSH private key in PEM format (e.g., ~/.ssh/id_rsa).")
                            Text("The key should start with '-----BEGIN ... PRIVATE KEY-----'")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Button(action: testConnection) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Test Connection")
                        }
                    }
                    .disabled(!isFormValid || isTesting)

                    Button(action: saveCredentials) {
                        Text("Save Credentials")
                    }
                    .disabled(!isFormValid)
                }

                Section {
                    Button(role: .destructive, action: clearCredentials) {
                        Text("Clear Saved Credentials")
                    }
                    .disabled(!keychainManager.hasCredentials())
                }
            }
            .navigationTitle("SSH Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Connection Test", isPresented: $showingTestResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(testResultMessage)
            }
            .alert("Saved", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("SSH credentials have been saved securely to your iOS Keychain.")
            }
        }
    }

    private var isFormValid: Bool {
        guard !hostname.isEmpty && !username.isEmpty else {
            return false
        }

        switch authMethod {
        case .password:
            return !password.isEmpty
        case .privateKey:
            return !privateKey.isEmpty && privateKey.contains("PRIVATE KEY")
        }
    }

    private func testConnection() {
        let credentials = SSHCredentials(
            hostname: hostname,
            username: username,
            authMethod: authMethod,
            password: authMethod == .password ? password : nil,
            privateKey: authMethod == .privateKey ? privateKey : nil
        )

        isTesting = true

        Task {
            do {
                try await sshService.testConnection(credentials)
                testResultMessage = "✓ Connection successful! You can now save these credentials."
            } catch {
                testResultMessage = "✗ Connection failed: \(error.localizedDescription)"
            }
            showingTestResult = true
            isTesting = false
        }
    }

    private func saveCredentials() {
        let credentials = SSHCredentials(
            hostname: hostname,
            username: username,
            authMethod: authMethod,
            password: authMethod == .password ? password : nil,
            privateKey: authMethod == .privateKey ? privateKey : nil
        )

        do {
            try keychainManager.saveCredentials(credentials)
            sshService.setCredentials(credentials)
            showingSaveSuccess = true
        } catch {
            testResultMessage = "Failed to save credentials: \(error.localizedDescription)"
            showingTestResult = true
        }
    }

    private func clearCredentials() {
        do {
            try keychainManager.clearCredentials()
            hostname = ""
            username = ""
            password = ""
            privateKey = ""
            authMethod = .password
            testResultMessage = "Credentials cleared successfully."
            showingTestResult = true
        } catch {
            testResultMessage = "Failed to clear credentials: \(error.localizedDescription)"
            showingTestResult = true
        }
    }
}

