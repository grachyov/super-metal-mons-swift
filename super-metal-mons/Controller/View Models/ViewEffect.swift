// ∅ 2024 super-metal-mons

import Foundation

enum ViewEffect {
    case updateGameStatus
    case selectBombOrPotion
    case updateCells([Location])
    case addHighlights([Highlight])
    case showTraces([Trace])
    case nextTurn
}
