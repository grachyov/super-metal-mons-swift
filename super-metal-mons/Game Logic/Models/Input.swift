// ∅ 2024 super-metal-mons

import Foundation

enum Input: Equatable, Codable {
    
    case location(Location)
    case modifier(Modifier)
    
    enum Modifier: String, Codable {
        case selectPotion, selectBomb, cancel
    }
    
}
