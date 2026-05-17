//
//  ContentView.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import SwiftUI

// MARK: - Design Tokens

struct DesignTokens {
    // Colors
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.3)
    static let blackGlass = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let darkMetal = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let offWhite = Color(red: 0.85, green: 0.85, blue: 0.87)
    static let signalGlow = Color(red: 0.2, green: 1.0, blue: 0.3).opacity(0.6)
}

struct ContentView: View {
    @StateObject private var viewModel: RemoteControlViewModel
    @ObservedObject var sshService: SSHService
    private let keychainManager: KeychainManager

    @State private var showingSettings = false
    @State private var pressedButton: RemoteCommand?
    @State private var volumeLevel: Double = 60.0

    init(sshService: SSHService, keychainManager: KeychainManager) {
        self.sshService = sshService
        self.keychainManager = keychainManager
        _viewModel = StateObject(wrappedValue: RemoteControlViewModel(sshService: sshService, keychainManager: keychainManager))
    }

    var body: some View {
        ZStack {
            // Black glass background
            DesignTokens.blackGlass
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Minimal header
                statusBar

                Spacer()

                // Main control surface
                VStack(spacing: 48) {
                    // Transport controls (7-button layout)
                    transportControls

                    // Volume controls (interactive slider)
                    volumeControls

                    // System controls (peripheral)
                    systemControls
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView(sshService: sshService, keychainManager: keychainManager)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            // Status indicator (minimal)
            statusIndicator

            Spacer()

            // Settings access
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(DesignTokens.offWhite.opacity(0.4))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 6, height: 6)
                .shadow(color: connectionStatusColor, radius: 3, x: 0, y: 0)

            if !viewModel.hasCredentials {
                Text("NOT CONFIGURED")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignTokens.offWhite.opacity(0.5))
                    .tracking(1.2)
            }
        }
    }

    private var connectionStatusColor: Color {
        switch viewModel.connectionState {
        case .connected, .executing:
            return DesignTokens.neonGreen
        case .connecting:
            return DesignTokens.neonGreen.opacity(0.5)
        case .error:
            return .red.opacity(0.8)
        case .disconnected:
            return DesignTokens.offWhite.opacity(0.3)
        }
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        VStack(spacing: 16) {
            // Top row: Skip Back, Rewind, Play, FF, Skip Forward
            HStack(spacing: 12) {
                HardwareButton(
                    command: .skipBack,
                    icon: "backward.end.fill",
                    isPressed: pressedButton == .skipBack,
                    isExecuting: false
                ) {
                    executeCommand(.skipBack)
                }

                HardwareButton(
                    command: .rewind,
                    icon: "backward.fill",
                    isPressed: pressedButton == .rewind,
                    isExecuting: false
                ) {
                    executeCommand(.rewind)
                }

                HardwareButton(
                    command: .play,
                    icon: "play.fill",
                    isPrimary: true,
                    isPressed: pressedButton == .play,
                    isExecuting: false
                ) {
                    executeCommand(.play)
                }

                HardwareButton(
                    command: .fastForward,
                    icon: "forward.fill",
                    isPressed: pressedButton == .fastForward,
                    isExecuting: false
                ) {
                    executeCommand(.fastForward)
                }

                HardwareButton(
                    command: .skipForward,
                    icon: "forward.end.fill",
                    isPressed: pressedButton == .skipForward,
                    isExecuting: false
                ) {
                    executeCommand(.skipForward)
                }
            }

            // Bottom row: Pause, Stop (centered)
            HStack(spacing: 24) {
                HardwareButton(
                    command: .pause,
                    icon: "pause.fill",
                    isPressed: pressedButton == .pause,
                    isExecuting: false
                ) {
                    executeCommand(.pause)
                }

                HardwareButton(
                    command: .stop,
                    icon: "stop.fill",
                    isPressed: pressedButton == .stop,
                    isExecuting: false
                ) {
                    executeCommand(.stop)
                }
            }
        }
    }

    // MARK: - Volume Controls

    private var volumeControls: some View {
        VStack(spacing: 16) {
            // Volume buttons
            HStack(spacing: 32) {
                HardwareButton(
                    command: .volumeDown,
                    icon: "speaker.wave.1",
                    isPressed: pressedButton == .volumeDown,
                    isExecuting: false
                ) {
                    if volumeLevel > 0 {
                        volumeLevel = max(0, volumeLevel - 10)
                    }
                    executeCommand(.volumeDown)
                }

                // Interactive volume slider
                VStack(spacing: 8) {
                    Slider(value: $volumeLevel, in: 0...100, step: 5)
                        .accentColor(DesignTokens.neonGreen)
                        .frame(width: 180)
                        .onChange(of: volumeLevel) { oldValue, newValue in
                            // Haptic feedback on slider change
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }

                    Text("VOLUME \(Int(volumeLevel))%")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(DesignTokens.offWhite.opacity(0.4))
                        .tracking(1.5)
                }

                HardwareButton(
                    command: .volumeUp,
                    icon: "speaker.wave.3",
                    isPressed: pressedButton == .volumeUp,
                    isExecuting: false
                ) {
                    if volumeLevel < 100 {
                        volumeLevel = min(100, volumeLevel + 10)
                    }
                    executeCommand(.volumeUp)
                }
            }
        }
    }

    // MARK: - System Controls

    private var systemControls: some View {
        HStack(spacing: 24) {
            HardwareButton(
                command: .wake,
                icon: "sun.max",
                isSmall: true,
                isPressed: pressedButton == .wake,
                isExecuting: false
            ) {
                executeCommand(.wake)
            }

            HardwareButton(
                command: .sleep,
                icon: "moon",
                isSmall: true,
                isPressed: pressedButton == .sleep,
                isExecuting: false
            ) {
                executeCommand(.sleep)
            }
        }
    }

    // MARK: - Actions

    private func executeCommand(_ command: RemoteCommand) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        pressedButton = command
        viewModel.executeCommand(command)

        // Reset pressed state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            pressedButton = nil
        }
    }
}

// MARK: - Hardware Button

struct HardwareButton: View {
    let command: RemoteCommand
    let icon: String
    var isPrimary: Bool = false
    var isSmall: Bool = false
    var isPressed: Bool = false
    var isExecuting: Bool = false
    let action: () -> Void

    private var size: CGFloat {
        if isPrimary { return 72 }
        if isSmall { return 48 }
        return 60
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Backlight glow - subtle neon green behind the button
                Circle()
                    .fill(DesignTokens.neonGreen.opacity(0.15))
                    .blur(radius: 2)
                    .scaleEffect(1.1)

                // Stronger backlight when pressed/executing
                if isPressed || isExecuting {
                    Circle()
                        .fill(DesignTokens.neonGreen.opacity(0.75))
                        .blur(radius: 5)
                        .scaleEffect(1.15)
                }

                // Button body - dark metal
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignTokens.darkMetal.opacity(0.8),
                                DesignTokens.darkMetal
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),  // More pronounced
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2  // Thicker edge
                            )
                    )
                    // Additional inner edge highlight
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(0.15),
                                lineWidth: 1
                            )
                            .padding(1)
                    )

                // Inner shadow when pressed
                if isPressed {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .blur(radius: 4)
                        .offset(y: 1)
                }

                // Icon
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 28 : (isSmall ? 18 : 24), weight: .light))
                    .foregroundColor(isExecuting || isPressed ? DesignTokens.neonGreen : DesignTokens.offWhite)
                    .shadow(
                        color: isExecuting || isPressed ? DesignTokens.signalGlow : .clear,
                        radius: 8,
                        x: 0,
                        y: 0
                    )
            }
            .frame(width: size, height: size)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isExecuting)
    }
}
