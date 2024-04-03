// ∅ 2024 super-metal-mons

import Foundation

extension URL {
    
    static let baseMonsLink = "mons.link"
    
    static func forGame(id: String) -> String {
        return baseMonsLink + "/" + id
    }
    
    var gameId: String? {
        let link: String
        
        if let scheme = scheme {
            link = absoluteString.replacingOccurrences(of: scheme + "://", with: "")
        } else {
            link = absoluteString
        }
        
        let prefix = URL.baseMonsLink + "/"
        
        if link.hasPrefix(prefix), link.count > prefix.count {
            let id = String(link.dropFirst(prefix.count))
            return id
        } else {
            return nil
        }
    }
    
    var secretAppRequest: SecretAppRequest? {
        guard host == "mons.rehab" && lastPathComponent == "app-request",
              let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        var dict = [String: String]()
        for item in queryItems {
            dict[item.name] = item.value
        }
        return SecretAppRequest(dict: dict)
    }
    
}
