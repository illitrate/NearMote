//
//  Item.swift
//  MacRemote
//
//  Created by jai nelson on 17/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
