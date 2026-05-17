//
//  MacRemoteApp.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import SwiftUI

@main
struct NearMoteApp: App {
    @StateObject private var sshService = SSHService()
    private let keychainManager = KeychainManager()

    var body: some Scene {
        WindowGroup {
            ContentView(sshService: sshService, keychainManager: keychainManager)
        }
    }
}

