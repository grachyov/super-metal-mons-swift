// ∅ 2024 super-metal-mons

import Foundation

struct Mon: Equatable, Codable, Hashable {
    
    enum Kind: String, Codable, Hashable {
        case demon, drainer, angel, spirit, mystic
    }
    
    let kind: Kind
    let color: Color
    
    private (set) var cooldown: Int
    
    var isFainted: Bool {
        return cooldown > 0
    }
    
    init(kind: Kind, color: Color, cooldown: Int = 0) {
        self.kind = kind
        self.color = color
        self.cooldown = cooldown
    }
    
    mutating func faint() {
        cooldown = 2
    }
    
    mutating func decreaseCooldown() {
        if cooldown > 0 {
            cooldown -= 1
        }
    }
    
}
