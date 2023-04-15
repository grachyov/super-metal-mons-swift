// Copyright © 2023 super metal mons. All rights reserved.

import UIKit
import FirebaseDatabase

class SpaceView: UIView {
    var row = 0
    var col = 0
}

class MonsboardViewController: UIViewController {
    
    let database = Database.database().reference()
    private var lastSharedFen = ""
    
    private var effectsViews = [UIView]()
    private lazy var monsOnBoard: [[UIImageView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
    
    private var didSetupBoard = false
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var boardContainerView: UIView!
    
    private let boardSize = 11
    private lazy var squares: [[SpaceView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

    lazy var game: MonsGame = {
        return MonsGame() // TODO: load the last game if there is one
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMonsboard()
        statusLabel.text = game.prettyGameStatus
        runFirebase()
    }
    
    let sessionId = "fen101"
    
    func runFirebase() {
        database.child(sessionId).observe(.value) { [weak self] (snapshot) in
            guard let data = snapshot.value as? [String: AnyObject], let fen = data["fen"] as? String else {
                print("No fen found")
                return
            }
            self?.receivedFenFromNetwork(fen: fen)
        }
    }
    
    func receivedFenFromNetwork(fen: String) {
        guard lastSharedFen != fen, !fen.isEmpty else { return }
        DispatchQueue.main.async {
            self.game = MonsGame(fen: fen)!
            self.restartBoardForTest()
            self.statusLabel.text = self.game.prettyGameStatus
            if let winner = self.game.winnerColor {
                self.didWin(color: winner)
            }
        }
    }
    
    func didWin(color: Color) {
        let alert = UIAlertController(title: color == .red ? "🔴" : "🔵", message: "all done", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .default) { [weak self] _ in
            // TODO: do not restart the game if the opponent has done so already
            // or i guess in these case there should be a new game id exchage
            self?.endGame(openMenu: true)
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func sendFen(_ fen: String) {
        guard lastSharedFen != fen else { return }
        database.child(sessionId).setValue(["fen": fen])
        lastSharedFen = fen
    }
    
    func endGame(openMenu: Bool = true) {
        game = MonsGame()
        sendFen(game.fen)
        if openMenu {
            dismiss(animated: false)
        } else {
            statusLabel.text = game.prettyGameStatus
            restartBoardForTest()
        }
    }
    
    @IBAction func ggButtonTapped(_ sender: Any) {
        endGame(openMenu: true)
    }
    
    // TODO: remove this one, this is for development only
    func restartBoardForTest() {
        monsOnBoard.forEach { $0.forEach { $0?.removeFromSuperview() } }
        monsOnBoard = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        setupMonsboard()
    }
    
    private var squareSize = CGFloat.zero
    
    private func setupMonsboard() {
        #if targetEnvironment(macCatalyst)
        let screenWidth: CGFloat = 800
        let screenHeight: CGFloat = 1200
        #else
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        #endif
        squareSize = screenWidth / CGFloat(boardSize)
        let totalBoardSize = screenWidth
        let yOffset = (screenHeight - totalBoardSize) / 2

        if !didSetupBoard {
            for row in 0..<boardSize {
                for col in 0..<boardSize {
                    let x = CGFloat(col) * squareSize
                    let y = CGFloat(row) * squareSize + yOffset

                    let square = SpaceView(frame: CGRect(x: x, y: y, width: squareSize, height: squareSize))
                    square.backgroundColor = (row + col) % 2 == 0 ? Colors.squareLight : Colors.squareDark
                    boardContainerView.addSubview(square)
                    squares[row][col] = square
                    
                    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSquare))
                    square.addGestureRecognizer(tapGestureRecognizer)
                    square.col = col
                    square.row = row
                }
            }
            
            for (i, j) in [(0, 0), (5, 5), (10, 10), (0, 10), (10, 0)] {
                squares[i][j]?.backgroundColor = Colors.squareSpecial
            }
        }
        
        // TODO: move to board class
        for i in game.board.indices {
            for j in game.board[i].indices {
                updateCell(i, j)
            }
        }
        didSetupBoard = true
    }
    
    private func updateCell(_ i: Int, _ j: Int) {
        
        // TODO: look at the data and do nothing when nothing changed
        
        let space = game.board[i][j]
        switch space {
        case .consumable:
            if !didSetupBoard {
                // TODO: this would brake when we start with the ongoing game
                squares[i][j]?.backgroundColor = Colors.squareConsumable
            }
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.8, height: squareSize * 0.8))
            imageView.image = UIImage(named: "potion") // TODO: get name from consumable enum
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            monsOnBoard[i][j] = imageView
        case let .mon(mon: mon):
            
            // TODO: move it from here
            let specifier = mon.color == .blue ? "-black" : ""
            let name: String
            switch mon.kind {
            case .mystic: name = "mystic" + specifier
            case .demon: name = "demon" + specifier
            case .drainer: name = "drainer" + specifier
            case .angel: name = "angel" + specifier
            case .spirit: name = "spirit" + specifier
            }
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.9, height: squareSize * 0.9))
            imageView.image = UIImage(named: name)
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            monsOnBoard[i][j] = imageView
            
        case let .monWithMana(mon: mon, mana: mana):
            // TODO: refactor. there is the same code in mon and mana case
            // TODO: move it from here
            let specifier = mon.color == .blue ? "-black" : ""
            let name: String
            switch mon.kind {
            case .mystic: name = "mystic" + specifier
            case .demon: name = "demon" + specifier
            case .drainer: name = "drainer" + specifier
            case .angel: name = "angel" + specifier
            case .spirit: name = "spirit" + specifier
            }
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.9, height: squareSize * 0.9))
            imageView.image = UIImage(named: name)
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            switch mana {
            case let .regular(color: color):
                let manaView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.6, height: squareSize * 0.6))
                let specifier = color == .blue ? "-black" : ""
                manaView.image = UIImage(named: "mana" + specifier)
                
                manaView.contentMode = .scaleAspectFit
                imageView.addSubview(manaView)
            case .superMana:
                let manaView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                manaView.image = UIImage(named: "super-mana")
                manaView.contentMode = .scaleAspectFit
                imageView.addSubview(manaView)
                monsOnBoard[i][j] = imageView
            }
            
            monsOnBoard[i][j] = imageView
            
        case let .mana(mana: mana):
            switch mana {
            case let .regular(color: color):
                if !didSetupBoard {
                    squares[i][j]?.backgroundColor = Colors.squareMana
                }
                
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.6, height: squareSize * 0.6))
                let specifier = color == .blue ? "-black" : ""
                imageView.image = UIImage(named: "mana" + specifier)
                imageView.contentMode = .scaleAspectFit
                imageView.center = squares[i][j]?.center ?? CGPoint.zero
                boardContainerView.addSubview(imageView)
                monsOnBoard[i][j] = imageView
            case .superMana:
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                imageView.image = UIImage(named: "super-mana")
                imageView.contentMode = .scaleAspectFit
                imageView.center = squares[i][j]?.center ?? CGPoint.zero
                boardContainerView.addSubview(imageView)
                monsOnBoard[i][j] = imageView
            }
        case .empty:
            break
        }
    }
    
    // TODO: act differently when i click spaces while opponent makes his turns
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let spaceView = sender.view as? SpaceView else { return }
        
        let i = spaceView.row // TODO: use location model here as well
        let j = spaceView.col
        
        let effects = game.didTapSpace((i, j))
        applyEffects(effects)
    }
    
    private func applyEffects(_ effects: [Effect]) {
        for effectView in effectsViews {
            effectView.removeFromSuperview()
        }
        effectsViews = []
        
        for effect in effects {
            switch effect {
            case .updateCell(let index):
                monsOnBoard[index.0][index.1]?.removeFromSuperview()
                monsOnBoard[index.0][index.1] = nil
                updateCell(index.0, index.1)
            case .setSelected(let index):
                let effectView = UIView()
                effectView.backgroundColor = .clear
                effectView.layer.borderWidth = 3
                effectView.layer.borderColor = UIColor.green.cgColor
                effectView.frame = CGRect(origin: .zero, size: CGSize(width: squareSize, height: squareSize))
                squares[index.0][index.1]?.addSubview(effectView)
                effectsViews.append(effectView)
            case .updateGameStatus:
                statusLabel.text = game.prettyGameStatus
                sendFen(game.fen)
                
                if let winner = game.winnerColor {
                    didWin(color: winner)
                }
            case .availableForStep(let index):
                // TODO: use dot for an empty field
//                let effectView = UIView()
//                effectView.backgroundColor = .green
//                let side = squareSize / 3
//                effectView.layer.cornerRadius = side / 2
//                effectView.alpha = 0.5
//                effectView.clipsToBounds = true
//                effectView.frame = CGRect(origin: CGPoint(x: side, y: side), size: CGSize(width: side, height: side))
//                squares[index.0][index.1]?.addSubview(effectView)
//                effectsViews.append(effectView)
                
                let effectView = UIView()
                effectView.backgroundColor = .clear
                effectView.layer.borderWidth = 5
                effectView.layer.borderColor = UIColor.yellow.cgColor
                effectView.frame = CGRect(origin: .zero, size: CGSize(width: squareSize, height: squareSize))
                squares[index.0][index.1]?.addSubview(effectView)
                effectsViews.append(effectView)
            }
        }
    }
    
}
