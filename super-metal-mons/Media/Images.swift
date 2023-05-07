// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

struct Images {
    
    static func monsBase(mon: Mon, style: BoardStyle) -> UIImage {
        return named(style.namespace + "base-" + mon.kind.rawValue)
    }

    static func consumable(_ consumable: Consumable, style: BoardStyle) -> UIImage {
        switch consumable {
        case .potion:
            return named(style.namespace + "potion")
        case .bomb:
            return named(style.namespace + "bomb")
        case .bombOrPotion:
            return named(style.namespace + "bag")
        }
    }
    
    static func mon(_ mon: Mon, style: BoardStyle) -> UIImage {
        return named(style.namespace + mon.kind.rawValue + mon.color.imageNameSuffix)
    }
    
    static func mana(_ mana: Mana, picked: Bool = false, style: BoardStyle) -> UIImage {
        switch mana {
        case .regular(let color):
            return named(style.namespace + "mana" + color.imageNameSuffix)
        case .supermana:
            return named(style.namespace + "supermana" + (picked ? "-simple" : ""))
        }
    }
    
    static var randomEmoji: UIImage {
        let index = Int.random(in: 1...156)
        return emoji(index)
    }
    
    static func emoji(_ index: Int) -> UIImage {
        return named("emoji-\(index)")
    }
    
    static func moveEmoji(_ move: AvailableMoveKind) -> UIImage {
        return named("move-\(move.rawValue)")
    }
    
    static var soundEnabled: UIImage { systemName("speaker") }
    static var soundDisabled: UIImage { systemName("speaker.slash") }
    
    private static func named(_ name: String) -> UIImage {
        return UIImage(named: name)!
    }
    
    private static func systemName(_ systemName: String, configuration: UIImage.Configuration? = nil) -> UIImage {
        return UIImage(systemName: systemName, withConfiguration: configuration)!
    }
    
}

private extension Color {
    
    var imageNameSuffix: String {
        switch self {
        case .black: return "-black"
        case .white: return ""
        }
    }
    
}
