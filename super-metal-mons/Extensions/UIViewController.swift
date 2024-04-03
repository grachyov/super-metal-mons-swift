// ∅ 2024 super-metal-mons

import UIKit

extension UIViewController {
    
    var inNavigationController: UINavigationController {
        let navigationController = UINavigationController()
        navigationController.viewControllers = [self]
        return navigationController
    }
    
    var topmost: UIViewController {
        var current = self
        while let next = current.presentedViewController {
            current = next
        }
        return current
    }
    
    @objc func dismissAnimated() {
        dismiss(animated: true)
    }
    
}
