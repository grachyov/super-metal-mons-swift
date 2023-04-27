// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

protocol GameView: AnyObject {
    func restartBoardForTest() // TODO: deprecate
    func updateGameInfo() // TODO: refactor
    func didWin(color: Color) // TODO: refactor
}

enum GameViewEffect {
    
}

// TODO: talk to view in view terms
// TODO: talk to game in game terms
// TODO: make sounds
// TODO: manage networking

// TODO: refactor
class GameController {
    
    // да вот полноценную модель доски было бы и для игровой логики удобно использовать
    // потому что разные результаты в зависимости от того, что за поле участвует в действии
    // и эту же модель доски использовать для отрисовки, и для того, чтобы показать, где база
    // TODO: изменить текущую реализацию базы (проверку через Location)
    let squares: [[Square]] = [
        [.p, .b, .w, .b, .w, .b, .w, .b, .w, .b, .p],
        [.b, .w, .b, .w, .b, .w, .b, .w, .b, .w, .b],
        [.w, .b, .w, .b, .w, .b, .w, .b, .w, .b, .w],
        [.b, .w, .b, .w, .m, .w, .m, .w, .b, .w, .b],
        [.w, .b, .w, .m, .w, .m, .w, .m, .w, .b, .w],
        [.c, .w, .b, .w, .b, .s, .b, .w, .b, .w, .c],
        [.w, .b, .w, .m, .w, .m, .w, .m, .w, .b, .w],
        [.b, .w, .b, .w, .m, .w, .m, .w, .b, .w, .b],
        [.w, .b, .w, .b, .w, .b, .w, .b, .w, .b, .w],
        [.b, .w, .b, .w, .b, .w, .b, .w, .b, .w, .b],
        [.p, .b, .w, .b, .w, .b, .w, .b, .w, .b, .p]
    ]
    
    var board: [[Piece]] {
        return game.board
    }
    
    var winnerColor: Color? {
        return game.winnerColor
    }
    
    var activeColor: Color {
        return game.activeColor
    }
    
    var availableMoves: [MonsGame.Move: Int] {
        return game.availableMoves
    }
    
    var blackScore: Int {
        return game.blackScore
    }
    
    var whiteScore: Int {
        return game.whiteScore
    }
    
    let boardSize = 11
    let boardStyle = BoardStyle.pixel
    
    private unowned var gameView: GameView!
    private var gameDataSource: GameDataSource
    
    init() {
        gameDataSource = LocalGameDataSource()
    }
    
    init(gameId: String) {
        gameDataSource = RemoteGameDataSource(gameId: gameId)
    }
    
    // idk about this one
    private lazy var game: MonsGame = {
        return MonsGame()
    }()
    
    func setGameView(_ gameView: GameView) {
        self.gameView = gameView
        
        gameDataSource.observe { [weak self] fen in
            DispatchQueue.main.async {
                self?.game = MonsGame(fen: fen)! // TODO: do not force unwrap
                self?.gameView.restartBoardForTest()
                self?.gameView.updateGameInfo()
                if let winner = self?.game.winnerColor {
                    self?.gameView.didWin(color: winner)
                }
            }
        }
    }
    
    // TODO: deprecate. should not be called from gameviewcontroller. should happen internally here.
    func shareGameState() {
        sendFen(game.fen)
    }
    
    private func sendFen(_ fen: String) {
        gameDataSource.update(fen: fen)
    }
    
    func endGame() {
        game = MonsGame()
        sendFen(game.fen)
    }
    
    // TODO: deprecate
    func didTapSpace(_ index: (Int, Int)) -> [Effect] {
        // TODO: act differently when i click spaces while opponent makes his turns
        return game.didTapSpace(index)
    }
    
    func didTapSquare() -> [GameViewEffect] {
        return []
    }
    
}
