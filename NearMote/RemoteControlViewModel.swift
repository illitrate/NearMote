//
//  RemoteControlViewModel.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RemoteControlViewModel: ObservableObject {
    @Published var isExecuting = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let sshService: SSHService
    private let keychainManager: KeychainManager

    init(sshService: SSHService, keychainManager: KeychainManager) {
        self.sshService = sshService
        self.keychainManager = keychainManager

        // Load credentials from keychain on init
        if let credentials = keychainManager.loadCredentials() {
            sshService.setCredentials(credentials)
        }
    }

    /// Execute a remote command
    func executeCommand(_ command: RemoteCommand) {
        Task {
            isExecuting = true
            errorMessage = nil
            showError = false

            do {
                _ = try await sshService.execute(command)
                // Command executed successfully
                // Optionally add haptic feedback here
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

            isExecuting = false
        }
    }

    /// Get the current connection state
    var connectionState: SSHService.ConnectionState {
        sshService.connectionState
    }

    /// Check if credentials are configured
    var hasCredentials: Bool {
        keychainManager.hasCredentials()
    }
}

