// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MainMenuViewController: UIViewController {
    
    private var didAppear = false
    
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(wasOpenedWithLink), name: Notification.Name.wasOpenedWithLink, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didAppear, let url = launchURL {
            launchURL = nil
            connectToURL(url)
        }
        
        didAppear = true
    }
    
    @objc private func wasOpenedWithLink() {
        if let url = launchURL, presentedViewController == nil {
            launchURL = nil
            connectToURL(url)
        }
    }
    
    private func connectToURL(_ url: URL) {
        if let id = url.gameId {
            let dataSource = RemoteGameDataSource(gameId: id)
            presentGameViewController(dataSource: dataSource)
        } else {
            // TODO: communicate failed connection
        }
    }
    
    @discardableResult private func presentGameViewController(dataSource: GameDataSource) -> UIViewController {
        let gameViewController = MonsboardViewController.with(gameDataSource: dataSource)
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
        return gameViewController
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        let id = String.newGameId
        let dataSource = RemoteGameDataSource(gameId: id)
        let gameViewController = presentGameViewController(dataSource: dataSource)
        
        let link = URL.forGame(id: id)
        let alert = UIAlertController(title: Strings.inviteWith, message: link, preferredStyle: .alert)
        let copyAction = UIAlertAction(title: Strings.copy, style: .default) { _ in
            UIPasteboard.general.string = link
        }
        alert.addAction(copyAction)
        gameViewController.present(alert, animated: true)
    }
    
    @IBAction func localGameButtonTapped(_ sender: Any) {
        let dataSource = LocalGameDataSource()
        presentGameViewController(dataSource: dataSource)
    }
    
    @IBAction func joinButtonTapped(_ sender: Any) {
        if let input = UIPasteboard.general.string, let url = URL(string: input) {
            connectToURL(url)
            UIPasteboard.general.string = ""
        } else {
            let alert = UIAlertController(title: Strings.thereIsNoLink, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: Strings.ok, style: .default) { _ in }
            alert.addAction(okAction)
            present(alert, animated: true)
        }
    }
    
}
