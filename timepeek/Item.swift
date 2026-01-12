//
//  Item.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
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
