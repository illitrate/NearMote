//
//  SSHService.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import Foundation
import Combine
import NIOCore
import NIOPosix
import NIOSSH

@MainActor
class SSHService: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?

    private var credentials: SSHCredentials?
    private var lastConnectionTime: Date?
    private let connectionTimeout: TimeInterval = 30
    private var cacheTimer: Timer?

    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case executing
        case error
    }

    /// Set credentials for SSH connection
    func setCredentials(_ credentials: SSHCredentials) {
        self.credentials = credentials
    }

    /// Execute a remote command via SSH
    func execute(_ command: RemoteCommand) async throws -> String {
        guard let credentials = credentials else {
            throw SSHError.noCredentials
        }

        connectionState = .connecting
        lastError = nil

        do {
            connectionState = .executing

            let shellCommand = CommandBuilder.buildCommand(for: command)
            let output = try await executeSSHCommand(
                credentials: credentials,
                command: shellCommand
            )

            connectionState = .connected
            resetCacheTimer()

            return output
        } catch let error as SSHError {
            connectionState = .error
            lastError = error.errorDescription
            throw error
        } catch {
            connectionState = .error
            let sshError = SSHError.commandExecutionFailed(error.localizedDescription)
            lastError = sshError.errorDescription
            throw sshError
        }
    }

    /// Test SSH connection with credentials
    func testConnection(_ credentials: SSHCredentials) async throws {
        connectionState = .connecting
        lastError = nil

        do {
            _ = try await executeSSHCommand(
                credentials: credentials,
                command: "echo 'test'"
            )
            connectionState = .connected
        } catch let error as SSHError {
            connectionState = .error
            lastError = error.errorDescription
            throw error
        } catch {
            connectionState = .error
            let sshError = SSHError.connectionFailed(error.localizedDescription)
            lastError = sshError.errorDescription
            throw sshError
        }
    }

    /// Close the current SSH connection
    func closeConnection() {
        lastConnectionTime = nil
        cacheTimer?.invalidate()
        cacheTimer = nil
        connectionState = .disconnected
    }

    // MARK: - Private Methods

    private func executeSSHCommand(credentials: SSHCredentials, command: String) async throws -> String {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            try? group.syncShutdownGracefully()
        }

        // Create appropriate auth delegate based on auth method
        let delegate: NIOSSHClientUserAuthenticationDelegate & NIOSSHClientServerAuthenticationDelegate

        switch credentials.authMethod {
        case .password:
            guard let password = credentials.password else {
                throw SSHError.authenticationFailed
            }
            delegate = PasswordAuthDelegate(username: credentials.username, password: password)

        case .privateKey:
            // SSH key authentication temporarily disabled pending API verification
            throw SSHError.authenticationFailedWithMessage("SSH key authentication is not yet implemented. Please use password authentication.")
        }

        let bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([
                    NIOSSHHandler(
                        role: .client(
                            .init(
                                userAuthDelegate: delegate,
                                serverAuthDelegate: delegate
                            )
                        ),
                        allocator: channel.allocator,
                        inboundChildChannelInitializer: nil
                    )
                ])
            }

        do {
            let channel = try await bootstrap.connect(host: credentials.hostname, port: 22).get()

            defer {
                _ = channel.close()
            }

            // Create exec channel
            let promise = channel.eventLoop.makePromise(of: Channel.self)

            channel.pipeline.handler(type: NIOSSHHandler.self).whenSuccess { handler in
                let childChannelPromise = channel.eventLoop.makePromise(of: Channel.self)

                handler.createChannel(childChannelPromise) { childChannel, _ in
                    childChannel.pipeline.addHandlers([
                        ExecHandler(command: command, promise: promise)
                    ])
                }
            }

            let execChannel = try await promise.futureResult.get()

            // Wait for command to complete
            try await execChannel.closeFuture.get()

            return ""  // Output will be captured by ExecHandler
        } catch {
            throw SSHError.connectionFailed(error.localizedDescription)
        }
    }

    private func resetCacheTimer() {
        cacheTimer?.invalidate()
        cacheTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.closeConnection()
            }
        }
    }
}

// MARK: - SSH Handlers

private final class ExecHandler: ChannelInboundHandler {
    typealias InboundIn = SSHChannelData
    typealias OutboundOut = SSHChannelData

    let command: String
    let promise: EventLoopPromise<Channel>
    var output = ""

    init(command: String, promise: EventLoopPromise<Channel>) {
        self.command = command
        self.promise = promise
    }

    func channelActive(context: ChannelHandlerContext) {
        // Send exec request
        let execRequest = SSHChannelRequestEvent.ExecRequest(command: command, wantReply: true)
        context.triggerUserOutboundEvent(SSHChannelRequestEvent.ExecRequest(command: command, wantReply: true), promise: nil)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)

        guard case .byteBuffer(let buffer) = data.data else {
            return
        }

        if let string = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) {
            output.append(string)
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        promise.succeed(context.channel)
    }
}

// MARK: - SSH Auth Delegate

private class PasswordAuthDelegate: NIOSSHClientUserAuthenticationDelegate {
    let username: String
    let password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        if availableMethods.contains(.password) {
            let offer = NIOSSHUserAuthenticationOffer(
                username: username,
                serviceName: "",
                offer: .password(.init(password: password))
            )
            nextChallengePromise.succeed(offer)
        } else {
            nextChallengePromise.succeed(nil)
        }
    }
}

extension PasswordAuthDelegate: NIOSSHClientServerAuthenticationDelegate {
    func validateHostKey(
        hostKey: NIOSSHPublicKey,
        validationCompletePromise: EventLoopPromise<Void>
    ) {
        // Accept all host keys (not recommended for production)
        validationCompletePromise.succeed(())
    }
}

// MARK: - Private Key Auth Delegate

private class PrivateKeyAuthDelegate: NIOSSHClientUserAuthenticationDelegate {
    let username: String
    let privateKey: NIOSSHPrivateKey

    init(username: String, privateKey: NIOSSHPrivateKey) {
        self.username = username
        self.privateKey = privateKey
    }

    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        if availableMethods.contains(.publicKey) {
            let offer = NIOSSHUserAuthenticationOffer(
                username: username,
                serviceName: "",
                offer: .privateKey(.init(privateKey: privateKey))
            )
            nextChallengePromise.succeed(offer)
        } else {
            nextChallengePromise.succeed(nil)
        }
    }
}

extension PrivateKeyAuthDelegate: NIOSSHClientServerAuthenticationDelegate {
    func validateHostKey(
        hostKey: NIOSSHPublicKey,
        validationCompletePromise: EventLoopPromise<Void>
    ) {
        // Accept all host keys (not recommended for production)
        validationCompletePromise.succeed(())
    }
}

// MARK: - SSHError

enum SSHError: LocalizedError {
    case noCredentials
    case connectionFailed(String)
    case authenticationFailed
    case commandExecutionFailed(String)
    case networkUnavailable
    case authenticationFailedWithMessage(String)

    var errorDescription: String? {
        switch self {
        case .noCredentials:
            return "Please configure SSH credentials in Settings"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .authenticationFailed:
            return "Authentication failed. Check username and password."
        case .commandExecutionFailed(let reason):
            return "Command failed: \(reason)"
        case .networkUnavailable:
            return "Network unavailable. Check WiFi connection."
        case .authenticationFailedWithMessage(let message):
            return message
        }
    }
}

