// ∅ 2024 super-metal-mons

import FirebaseCore
import FirebaseAuth

class BaseFirebase {
    
    static var userId: String?
    
    static func auth(competion: ((Bool) -> Void)? = nil) {
        Auth.auth().signInAnonymously { authResult, _ in
            if let user = authResult?.user {
                self.userId = user.uid
            }
        }
    }
    
    static func baseSetup() {
        FirebaseApp.configure()
        auth()
    }
    
}

#if !targetEnvironment(macCatalyst)
import FirebaseAppCheck
import FirebaseFirestore

class Firebase: BaseFirebase {
    
    static func setup() {
        AppCheck.setAppCheckProviderFactory(MonsAppCheckProviderFactory())
        baseSetup()
    }
    
    static func claim(completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // TODO: separate collections for separate drops
        
        db.collection("items").whereField("claimed", isEqualTo: false).limit(to: 1).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents, let documentToClaim = documents.first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let itemRef = documentToClaim.reference
                guard let itemDocument = try? transaction.getDocument(itemRef) else { return nil }
                guard let claimed = itemDocument.data()?["claimed"] as? Bool, !claimed else { return nil }
                transaction.updateData(["claimed": true], forDocument: itemRef)
                return itemDocument.data()?["code"] as? String
            }) { (result, _) in
                DispatchQueue.main.async {
                    completion(result as? String)
                }
            }
        }
    }
    
    static func createCodes(_ codes: [String]) {
        let db = Firestore.firestore()
        for code in codes {
            _ = db.collection("items").addDocument(data: [
                "claimed": false,
                "code": code
            ]) { err in
                if let _ = err {
                    print("🛑")
                } else {
                    print("✅")
                }
            }
        }
    }
    
}

private class MonsAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
    
}

#else

class Firebase: BaseFirebase {
    
    static func setup() {
        baseSetup()
    }
    
}

#endif
