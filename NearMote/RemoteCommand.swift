//
//  RemoteCommand.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import Foundation

enum RemoteCommand: String, CaseIterable, Identifiable {
    case volumeUp
    case volumeDown
    case skipBack
    case rewind
    case play
    case pause
    case stop
    case fastForward
    case skipForward
    case wake
    case sleep

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .volumeUp:
            return "Volume Up"
        case .volumeDown:
            return "Volume Down"
        case .skipBack:
            return "Previous Track"
        case .rewind:
            return "Rewind"
        case .play:
            return "Play"
        case .pause:
            return "Pause"
        case .stop:
            return "Stop"
        case .fastForward:
            return "Fast Forward"
        case .skipForward:
            return "Next Track"
        case .wake:
            return "Wake"
        case .sleep:
            return "Sleep"
        }
    }

    var iconName: String {
        switch self {
        case .volumeUp:
            return "speaker.wave.3.fill"
        case .volumeDown:
            return "speaker.wave.1.fill"
        case .skipBack:
            return "backward.end.fill"
        case .rewind:
            return "backward.fill"
        case .play:
            return "play.fill"
        case .pause:
            return "pause.fill"
        case .stop:
            return "stop.fill"
        case .fastForward:
            return "forward.fill"
        case .skipForward:
            return "forward.end.fill"
        case .wake:
            return "sun.max.fill"
        case .sleep:
            return "moon.fill"
        }
    }

    var category: CommandCategory {
        switch self {
        case .volumeUp, .volumeDown:
            return .volume
        case .skipBack, .rewind, .play, .pause, .stop, .fastForward, .skipForward:
            return .media
        case .wake, .sleep:
            return .system
        }
    }
}

enum CommandCategory {
    case volume
    case media
    case system

    var displayName: String {
        switch self {
        case .volume:
            return "Volume"
        case .media:
            return "Media Controls"
        case .system:
            return "System"
        }
    }
}

