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
    
    // TODO: refactor, move somewhere
    enum AssistedInputKind {
        case keepSelectionAfterMove
        case findStartLocationsAfterInvalidInput
        case reselectLastInvalidInput
    }
    
    var winnerColor: Color? {
        return game.winnerColor
    }
    
    var activeColor: Color {
        return game.activeColor
    }
    
    var availableMoves: [AvailableMoveKind: Int] {
        return game.availableMoveKinds
    }
    
    var blackScore: Int {
        return game.blackScore
    }
    
    var whiteScore: Int {
        return game.whiteScore
    }
    
    let boardStyle = BoardStyle.pixel
    
    // idk about this one
    // yeah i feel like we should keep it private
    var board: Board {
        return game.board
    }
    
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
    
    private var inputs = [MonsGame.Input]()
    private var cachedOutput: MonsGame.Output?
    
    // TODO: refactor
    func processInput(_ input: MonsGame.Input?, assistedInputKind: AssistedInputKind? = nil) -> [ViewEffect] {
        // TODO: act differently when i click spaces while opponent makes his turns
        // TODO: should play sounds / moves when opponent moves, but should not show his highlights
        
        var viewEffects = [ViewEffect]() // TODO: tmp
        
        if let input = input {
            inputs.append(input)
        }
        
        let output: MonsGame.Output
        if inputs.isEmpty, let cachedOutput = cachedOutput {
            output = cachedOutput
        } else {
            output = game.processInput(inputs)
        }
        
        switch output {
        case let .events(events):
            cachedOutput = nil
            inputs = []
            var locationsToUpdate = Set<Location>()
            
            var mightKeepHighlightOnLocation: Location?
            var mustReleaseHighlight = false
            
            var sounds = [Sound]()
            
            for event in events {
                switch event {
                case .monMove(_, let from, let to):
                    sounds.append(.move)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    mightKeepHighlightOnLocation = to
                case .manaMove(_, let from, let to):
                    sounds.append(.moveMana)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case let .manaScored(mana, at, _):
                    switch mana {
                    case .regular:
                        sounds.append(.scoreMana)
                    case .supermana:
                        sounds.append(.scoreSupermana)
                    }
                    locationsToUpdate.insert(at)
                    mustReleaseHighlight = true
                case .mysticAction(_, let from, let to):
                    sounds.append(.mysticAbility)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .demonAction(_, let from, let to):
                    sounds.append(.demonAbility)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .demonAdditionalStep(_, let from, let to):
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .spiritTargetMove(_, let from, let to):
                    sounds.append(.spiritAbility)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .pickupBomb(_, let at):
                    sounds.append(.pickUpPotion)
                    locationsToUpdate.insert(at)
                    mustReleaseHighlight = true
                case .pickupPotion(_, let at):
                    sounds.append(.pickUpPotion)
                    locationsToUpdate.insert(at)
                    mustReleaseHighlight = true
                case .pickupMana(_, _, let at):
                    sounds.append(.manaPickUp)
                    locationsToUpdate.insert(at)
                case .monFainted(_, let from, let to):
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .manaDropped(_, let at):
                    locationsToUpdate.insert(at)
                case .supermanaBackToBase(let from, let to):
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .bombAttack(_, let from, let to):
                    sounds.append(.bomb)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .monAwake(_, let at):
                    locationsToUpdate.insert(at)
                case .bombExplosion(let at):
                    sounds.append(.bomb)
                    locationsToUpdate.insert(at)
                case .nextTurn(_):
                    break
                case .gameOver(_):
                    break
                }
            }
            
            let maxSoundPriority = sounds.max(by: { $0.priority < $1.priority })?.priority
            sounds = sounds.filter { $0.priority == maxSoundPriority }
            Audio.play(sounds: sounds)
            
            if let to = mightKeepHighlightOnLocation, !mustReleaseHighlight {
                let nextMoveHighlights = processInput(.location(to), assistedInputKind: .keepSelectionAfterMove)
                if !nextMoveHighlights.isEmpty {
                    viewEffects.append(contentsOf: nextMoveHighlights)
                }
            }
            
            viewEffects.append(contentsOf: locationsToUpdate.map { ViewEffect.updateCell($0) })
            viewEffects.append(.updateGameStatus)
        case let .nextInputOptions(nextInputOptions):
            for (index, input) in inputs.enumerated() {
                if case let .location(location) = input {
                    let color: Highlight.Color
                    
                    if index > 0 {
                        switch nextInputOptions.last?.kind {
                        case .demonAdditionalStep:
                            color = .attackTarget
                        case .spiritTargetMove:
                            color = .spiritTarget
                        default:
                            color = .selectedStartItem
                        }
                    } else {
                        color = .selectedStartItem
                    }
                    
                    viewEffects.append(.highlight(Highlight(location: location, kind: .selected, color: color, isBlink: false)))
                }
            }
            
            for nextInputOption in nextInputOptions {
                if nextInputOption.kind == .selectConsumable {
                    viewEffects.append(.selectBombOrPotion)
                }
                
                switch nextInputOption.input {
                case .location(let location):
                    let locationIsEmpty = board.item(at: location) == nil
                    
                    let highlightKind: Highlight.Kind
                    let highlightColor: Highlight.Color
                    let isBase = Config.monsBases.contains(location)
                    let emptySquareHighlight: Highlight.Kind = isBase ? .targetSuggestion : .emptySquare
                    
                    switch nextInputOption.kind {
                    case .monMove, .manaMove, .selectConsumable:
                        highlightKind = locationIsEmpty ? emptySquareHighlight : .targetSuggestion
                        highlightColor = locationIsEmpty ? .emptyStepDestination : .destinationItem
                    case .mysticAction, .demonAction, .bombAttack:
                        highlightKind = .targetSuggestion
                        highlightColor = .attackTarget
                    case .demonAdditionalStep:
                        highlightKind = locationIsEmpty ? emptySquareHighlight : .targetSuggestion
                        highlightColor = .attackTarget
                    case .spiritTargetCapture:
                        highlightKind = .targetSuggestion
                        highlightColor = .spiritTarget
                    case .spiritTargetMove:
                        highlightKind = locationIsEmpty ? emptySquareHighlight : .targetSuggestion
                        highlightColor = .spiritTarget
                    }
                    
                    viewEffects.append(.highlight(Highlight(location: location, kind: highlightKind, color: highlightColor, isBlink: false)))
                case .modifier:
                    break
                }
            }
            
        case .invalidInput:
            let shouldTryToReselect = assistedInputKind == nil && inputs.count > 1 && inputs.first != input
            let shouldHelpFindOptions = assistedInputKind == nil && inputs.count == 1
            
            inputs = []
            
            if shouldTryToReselect {
                let reselectHighlights = processInput(input, assistedInputKind: .reselectLastInvalidInput)
                if !reselectHighlights.isEmpty {
                    viewEffects.append(contentsOf: reselectHighlights)
                }
            } else if shouldHelpFindOptions {
                let startLocationHighlights = processInput(nil, assistedInputKind: .findStartLocationsAfterInvalidInput)
                viewEffects.append(contentsOf: startLocationHighlights)
            }
        case let .locationsToStartFrom(locations):
            cachedOutput = output
            inputs = []
            let effects = locations.map { return ViewEffect.highlight(Highlight(location: $0, kind: .targetSuggestion, color: .startFrom, isBlink: true)) }
            viewEffects.append(contentsOf: effects)
        }
        
        return viewEffects
    }
    
}
