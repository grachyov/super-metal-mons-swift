// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct PlayerMatch: Codable {
    
    enum Status: String, Codable {
        case waiting, playing, surrendered, victory, defeat
    }
    
    let avatarEmojiId: String
    let fen: String
    let moves: [String]?
    let status: Status
    
}
