// ∅ 2024 super-metal-mons

import Foundation

enum SecretAppRequest {
    
    case createSecretInvite
    case recoverSecretInvite(id: String)
    case acceptSecretInvite(id: String, password: String)
    case getSecretGameResult(id: String, signature: String)
    
    init?(dict: [String: String]) {
        switch dict["type"] {
        case "createSecretInvite":
            self = .createSecretInvite
        case "recoverSecretInvite":
            guard let id = dict["id"] else { return nil }
            self = .recoverSecretInvite(id: id)
        case "acceptSecretInvite":
            guard let id = dict["id"], let password = dict["password"] else { return nil }
            self = .acceptSecretInvite(id: id, password: password)
        case "getSecretGameResult":
            guard let id = dict["id"], let signature = dict["signature"] else { return nil }
            self = .getSecretGameResult(id: id, signature: signature)
        default:
            return nil
        }
    }
    
}
