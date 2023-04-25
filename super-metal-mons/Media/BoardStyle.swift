// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum BoardStyle: String {
    case basic, pixel, plastic
    
    var namespace: String {
        return rawValue + "/"
    }
    
}
