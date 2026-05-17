//
//  CommandBuilder.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import Foundation

struct CommandBuilder {
    /// Converts a RemoteCommand enum to its corresponding shell script command
    static func buildCommand(for command: RemoteCommand) -> String {
        switch command {
        case .volumeUp:
            return "osascript -e \"set volume output volume (output volume of (get volume settings) + 10)\""

        case .volumeDown:
            return "osascript -e \"set volume output volume (output volume of (get volume settings) - 10)\""

        case .skipBack:
            return "osascript -e 'tell application \"Music\" to previous track'"

        case .rewind:
            return "osascript -e 'tell application \"Music\" to set player position to (player position - 10)'"

        case .play:
            return "osascript -e 'tell application \"Music\" to play'"

        case .pause:
            return "osascript -e 'tell application \"Music\" to pause'"

        case .stop:
            return "osascript -e 'tell application \"Music\" to stop'"

        case .fastForward:
            return "osascript -e 'tell application \"Music\" to set player position to (player position + 10)'"

        case .skipForward:
            return "osascript -e 'tell application \"Music\" to next track'"

        case .sleep:
            return "pmset sleepnow"

        case .wake:
            return "caffeinate -u -t 1"
        }
    }
}

