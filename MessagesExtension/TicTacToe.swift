//
//  TicTacToe.swift
//  TicTacToe
//
//  Created by Amar Ramachandran on 6/15/16.
//  Copyright © 2016 amarjayr. All rights reserved.
//

import Foundation
import Messages

enum TTTCellState: CustomStringConvertible {
    case empty
    case occupied(Player)

    var description: String {
        switch self {
        case empty:
            return "empty"
        case occupied(let player):
            return player.description
        }
    }
}

enum TTTError: ErrorProtocol, CustomStringConvertible {
    case positionOccupied
    case notPlayerTurn
    case gameDone

    var description: String {
        switch self {
        case positionOccupied:
            return "The current position is occupied."
        case .notPlayerTurn:
            return "Not current player's turn."
        case .gameDone:
            return "The game is over."
        }
    }
}

struct Player: CustomStringConvertible {
    var uuid: String!
    var color: UIColor!

    var description: String {
        return uuid! + ":/:" + color.hexString(includeAlpha: false)
    }
}

extension Player: Hashable {
    var hashValue: Int {
        return self.uuid.hashValue
    }
}

extension Player: Equatable {}

func == (lhs: Player, rhs: Player) -> Bool {
    return lhs.uuid == rhs.uuid
}

class TicTacToe {
    private var grid: [[TTTCellState]]!

    let player: Player!
    let opponents: [Player]!
    var players: [Player] {
        var mPlayers = opponents
        mPlayers!.append(player)
        return mPlayers!
    }

    var size: Int {
        return grid.count
    }

    private var requiredInRowCustom: Int?
    var requiredInARow: Int {
        get {
            return requiredInRowCustom ?? size
        }
        set(value) {
            requiredInRowCustom = value
        }
    }

    var winner: Player? {
        if let w = checkWinner() {
            return w
        } else if isDraw() {
            return Player()
        } else {
            return nil
        }
    }

    subscript(row: Int, column: Int) -> TTTCellState {
        get {
            return grid[row][column]
        }
        set(value) {
            grid[row][column] = value
        }
    }

    // MARK: Initializers
    
    init(player currentPlayer: Player, opponents opponentPlayers: [Player], size: Int = 3) {
        player = currentPlayer
        opponents = opponentPlayers

        grid = Array(repeatElement(Array(repeatElement(TTTCellState.empty, count: size)), count: size))
    }

    private init(player currentPlayer: Player, opponents opponentPlayers: [Player], board predefinedBoard: [[TTTCellState]]) {
        player = currentPlayer
        opponents = opponentPlayers

        grid = predefinedBoard
    }

    // MARK: Board manipulation

    
    func selectCell(row: Int, column: Int) throws {
        guard row < size && column < size && row >= 0 && column >= 0 else {
            fatalError("Coordinates not on grid")
        }

        guard winner == nil else {
            throw TTTError.gameDone
        }

        var round = 0
        for p in opponents {
            let r = moveCount(for: p)
            if r > round {
                round = r
            }
        }

        guard round >= moveCount(for: player) else {
            throw TTTError.notPlayerTurn
        }

        if case .empty = self[row, column] {
            self[row, column] = TTTCellState.occupied(player!)
        } else {
            throw TTTError.positionOccupied
        }
    }

    // MARK: Winning/Gameover checks

    func checkWinner() -> Player? {
        return checkColumns(for: grid) ?? checkRows() ?? checkAntiDiagonals() ?? checkDiagonals()
    }
    
    private func checkAntiDiagonals() -> Player? {
        var newGrid: [[TTTCellState]] = grid
        for i in 0..<grid.count {
            newGrid[i].insert(contentsOf: Array(repeatElement(TTTCellState.empty, count: i)), at: 0)
            let length = newGrid[i].count
            newGrid[i] += Array(repeatElement(TTTCellState.empty, count: ((2*size - 1) - length)))
        }
        
        return checkColumns(for: newGrid)
    }
    
    private func checkDiagonals() -> Player? {
        var newGrid: [[TTTCellState]] = grid
        for i in 0..<grid.count {
            newGrid[i].insert(contentsOf: Array(repeatElement(TTTCellState.empty, count: ((size-1)-i))), at: 0)
            let length = newGrid[i].count
            newGrid[i] += Array(repeatElement(TTTCellState.empty, count: ((2*size - 1) - length)))
        }
        
        return checkColumns(for: newGrid)
    }
    
    private func checkRows() -> Player? {
        var owned = [Player: [Int]]()
        
        for player in players {
            owned[player] =  Array(repeating: 0, count: size)
        }
        
        for j in 0..<size {
            for i in 0..<size {
                var occupiedBy: Player?
                if case .occupied(let user) = self[i, j] {
                    owned[user]![i] += 1
                    occupiedBy = user
                }
                
                for (player, array) in owned {
                    for numberOwned in array {
                        if numberOwned == requiredInARow {
                            return player
                        }
                    }
                    
                    if occupiedBy == nil {
                        owned[player]![i] = 0
                    } else if player != occupiedBy {
                        owned[player]![i] = 0
                    }
                }
                
            }
        }
        
        return nil
    }
    
    private func checkColumns(for grid: [[TTTCellState]]) -> Player? {
        var owned = [Player: [Int]]()
        
        for player in players {
            owned[player] =  Array(repeating: 0, count: grid[0].count)
        }
        
        for i in 0..<grid.count {
            for j in 0..<grid[0].count {
                var occupiedBy: Player?
                if case .occupied(let user) = grid[i][j] {
                    owned[user]![j] += 1
                    occupiedBy = user
                }
                
                for (player, array) in owned {
                    for numberOwned in array {
                        if numberOwned == requiredInARow {
                            return player
                        }
                    }
                    
                    if occupiedBy == nil {
                        owned[player]![j] = 0
                    } else if player != occupiedBy {
                        owned[player]![j] = 0
                    }
                }
                
            }
        }
        
        return nil
    }

    private func isDraw() -> Bool {
        return moveCount(for: player!) == Int(pow(Decimal(size), 2) - 1)
    }
    
    // MARK: Utility

    func moveCount(for player: Player?) -> Int {
        guard player == self.player || opponents.contains(player!) else {
            fatalError("Player not part of game.")
        }

        return grid.flatMap { $0 }.filter { (element) -> Bool in
            if case .occupied(let user) = element {
                return user == player
            }
            return false
        }.count
    }

    func containsUserWith(uuid user: String) -> Bool {
        if player.uuid == user {
            return true
        }

        for opponent in opponents {
            if opponent.uuid == user {
                return true
            }
        }

        return false
    }
}

extension TicTacToe {
    func boardToJSON() -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: grid.map({ (value: [TTTCellState]) -> [String] in
                var array = [String]()
                for i in 0..<value.count {
                    array.append(String(value[i]))
                }

                return array
            }), options: .prettyPrinted)
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        } catch {
            return nil
        }
    }

    func opponentsToJSON() -> String? {
        var playersArray: [Player] = opponents
        playersArray.append(player)

        do {
            let data = try JSONSerialization.data(withJSONObject: playersArray.map({ (value: Player) -> String in
                return String(value)
            }), options: .prettyPrinted)
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        } catch {
            return nil
        }
    }

    static func boardFrom(json string: String) -> [[TTTCellState]]? {
        if let data = string.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String]]
                let grid = json!

                var returnGrid = Array(repeatElement(Array(repeatElement(TTTCellState.empty, count: grid.count)), count: grid.count))

                for i in 0..<grid.count {
                    for j in 0..<grid.count {
                        if grid[i][j] != "empty" {
                            var elComponents = grid[i][j].components(separatedBy: ":/:")

                            returnGrid[i][j] = TTTCellState.occupied( Player(uuid: elComponents[0], color: UIColor(hex: elComponents[1])))
                        } else {
                            returnGrid[i][j] = TTTCellState.empty
                        }
                    }
                }

                return returnGrid
            } catch let error as NSError {
                fatalError("JSON PARSING ERROR: " + error.description)
            }
        } else {
            fatalError("boardFrom, unkown error")
        }
    }

    static func opponentsFromJSON(json string: String) -> [Player]? {
        if let data = string.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String]

                var returnGrid = [Player]()

                for playerStr in json! {
                    returnGrid.append(Player(uuid: playerStr.components(separatedBy: ":/:")[0], color: UIColor(hex: playerStr.components(separatedBy: ":/:")[1])))
                }

                return returnGrid
            } catch let error as NSError {
                fatalError("JSON PARSING ERROR: " + error.description)
            }
        } else {
            fatalError("opponentsFrom, unkown error")
        }
    }
}

extension TicTacToe {
    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem]()
        items.append(URLQueryItem(name: "Opponent", value: opponentsToJSON()))
        items.append(URLQueryItem(name: "Board", value: boardToJSON()))

        return items
    }

    convenience init?(queryItems: [URLQueryItem], current uuid: String) {
        var opponents = TicTacToe.opponentsFromJSON(json: queryItems[0].value!)
        var current: Player?

        opponents = opponents?.filter({ (value: Player) -> Bool in
            if value.uuid != uuid {
                return true
            } else {
                current = value
                return false
            }
        })

        self.init(player: current!, opponents: opponents!, board: TicTacToe.boardFrom(json: queryItems[1].value!)!)
    }
}

extension TicTacToe {
    convenience init?(message: MSMessage?, current uuid: String) {
        guard let messageURL = message?.url else { return nil }
        guard let urlComponents = NSURLComponents(url: messageURL, resolvingAgainstBaseURL: false), let queryItems = urlComponents.queryItems else { return nil }

        self.init(queryItems: queryItems, current: uuid)
    }
}


extension TicTacToe: Equatable {}

func == (lhs: TicTacToe, rhs: TicTacToe) -> Bool {
    return lhs.player == rhs.player && lhs.opponents == rhs.opponents && lhs.boardToJSON() == rhs.boardToJSON()
}
