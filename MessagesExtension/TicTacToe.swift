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
    case occupied(String)
    
    var description: String {
        switch self {
        case empty:
            return "empty"
        case occupied(let uuid):
            return uuid
        }
    }
}

enum TTTError: ErrorProtocol {
    case PositionOccupied
    case NotPlayerTurn
    case GameDone
}

class TicTacToe {
    private var grid: [[TTTCellState]]
    private var cacheWinner: String?
    
    var player: String?
    var opponent: String?
    
    var size: Int {
        return grid.count
    }
    
    var requiredInARow: Int  {
        return size
    }
    
    var winner: String? {
        if let w = cacheWinner {
            return w
        } else if let w = checkWinner() {
            return w
        } else if isDraw() {
            return ""
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
    
    init(player currentUUID: String, opponent opponentUUID:String, size: Int = 3) {
        player = currentUUID
        opponent = opponentUUID
        
        grid = Array(repeatElement(Array(repeatElement(TTTCellState.empty, count: size)), count: size))
    }
    
    private init(player uuid: String, opponent player2: String, board predefinedBoard: [[TTTCellState]]) {
        player = uuid
        opponent = player2
        
        grid = predefinedBoard
    }
    
    // MARK: Square manipulation
    
    func selectCell(row x: Int, column y: Int) throws  {
        if winner != nil {
            throw TTTError.GameDone
        }
        
        if (moveCount(for: opponent) < moveCount(for: player)) {
            throw TTTError.NotPlayerTurn
        }
        
        if case .empty = getCell(row: x, column: y)  {
            self[x, y] = TTTCellState.occupied(player!)
        } else {
            throw TTTError.PositionOccupied
        }
        
        cacheWinner = checkWinnerAfterMove(row: x, column: y)
    }
    
    func getCell(row x: Int, column y: Int) -> TTTCellState {
        return self[x, y]
    }
    
    // MARK: Winning/Game over cases
    
    private func checkWinnerAfterMove(row x: Int, column y: Int) -> String? {
        var numberOwnedInColumn = 0
        for i in 0..<size {
            if case .occupied(let user) = self[x, i] where user == player {
                numberOwnedInColumn += 1
            }
            if numberOwnedInColumn == requiredInARow {
                return player
            }
        }
        
        var numberOwnedInRow = 0
        for i in 0..<size {
            if case .occupied(let user) = self[i, y] where user == player {
                numberOwnedInRow += 1
            }
            if numberOwnedInRow == requiredInARow {
                return player
            }
        }
        
        var numberOwnedInDiagonal = 0
        if x == y {
            for i in 0..<size {
                if case .occupied(let user) = self[i, i] where user == player {
                    numberOwnedInDiagonal += 1
                }
                if numberOwnedInDiagonal == requiredInARow {
                    return player
                }
            }
        }
        
        var numberOwnedInAntiDiagonal = 0
        for i in 0..<size {
            if case .occupied(let user) = self[i, (size-1)-i] where user == player {
                numberOwnedInAntiDiagonal += 1
            }
            if numberOwnedInAntiDiagonal == requiredInARow {
                return player
            }
        }
        
        return nil
    }
    
    private func isDraw() -> Bool {
        return moveCount(for: player!) == Int(pow(Decimal(size), 2) - 1)
    }
    
    private func checkWinner() -> String? {
        var userOwned = Array(repeating: 0, count: size*2)
        var opponentOwned = Array(repeating: 0, count: size*2)
        
        for i in 0..<size {
            for j in 0..<size {
                if case .occupied(let user) = self[i, j] where user == player {
                    userOwned[j] += 1
                } else if case .occupied(let user) = self[i, j] where user == opponent {
                    opponentOwned[j] += 1
                }
            }
        }
        
        for j in 0..<size {
            for i in 0..<size {
                if case .occupied(let user) = self[i, j] where user == player {
                    userOwned[i+size] += 1
                } else if case .occupied(let user) = self[i, j] where user == opponent {
                    opponentOwned[i+size] += 1
                }
            }
        }
        for numberOwned in userOwned {
            if (numberOwned == requiredInARow) {
                cacheWinner = player
                return player
            }
        }
        
        for numberOwned in opponentOwned {
            if (numberOwned == requiredInARow) {
                cacheWinner = opponent
                return opponent
            }
        }
        
        
        var numberOwnedInDiagonalForUser = 0
        var numberOwnedInDiagonalForOpponent = 0
        for i in 0..<size {
            if case .occupied(let user) = self[i, i] where user == player {
                numberOwnedInDiagonalForUser += 1
            }
            if case .occupied(let user) = self[i, i] where user == opponent {
                numberOwnedInDiagonalForOpponent += 1
            }
            if numberOwnedInDiagonalForUser == requiredInARow {
                cacheWinner = player
                return player
            }
            if numberOwnedInDiagonalForOpponent == requiredInARow {
                cacheWinner = opponent
                return opponent
            }
        }
        
        
        var numberOwnedInAntiDiagonalForUser = 0
        var numberOwnedInAntiDiagonalForOpponent = 0
        for i in 0..<size {
            if case .occupied(let user) = self[i, (size-1)-i] where user == player {
                numberOwnedInAntiDiagonalForUser += 1
            }
            if case .occupied(let user) = self[i, (size-1)-i] where user == opponent {
                numberOwnedInAntiDiagonalForOpponent += 1
            }
            if numberOwnedInAntiDiagonalForUser == requiredInARow {
                cacheWinner = player
                return player
            }
            if numberOwnedInAntiDiagonalForOpponent == requiredInARow {
                cacheWinner = opponent
                return opponent
            }
        }
        
        
        
        
        return nil
    }
    
    // MARK: Utility
    
    func moveCount(for player: String?) -> Int {
        return grid.flatMap { $0 }.filter { (element) -> Bool in
            switch element {
            case .occupied(let uuid):
                return uuid == player
            default:
                break
            }
            return false
            }.count
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
    
    static func boardFrom(json string: String) -> [[TTTCellState]]? {
        var returnGrid = Array(repeatElement(Array(repeatElement(TTTCellState.empty, count: 3)), count: 3))
        
        if let data = string.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [[String]]
                let grid = json 
                
                for i in 0..<grid.count {
                    for j in 0..<grid.count {
                        if (grid[i][j] != "empty") {
                            returnGrid[i][j] = TTTCellState.occupied(grid[i][j])
                        }
                    }
                }
                
            } catch let error as NSError {
                fatalError("JSON PARSING ERROR: " + error.description)
            }
        } else {
            fatalError("boardFrom, unkown error")
        }
        
        return returnGrid
    }
}

extension TicTacToe {
    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem]()
        items.append(URLQueryItem(name: "Player", value: player))
        items.append(URLQueryItem(name: "Opponent", value: opponent))
        items.append(URLQueryItem(name: "Board", value: boardToJSON()))
        
        return items
    }
    
    convenience init?(queryItems: [URLQueryItem]) {
        self.init(player: queryItems[1].value!, opponent: queryItems[0].value!, board: TicTacToe.boardFrom(json: queryItems[2].value!)!)
    }
}

extension TicTacToe {
    convenience init?(message: MSMessage?) {
        guard let messageURL = message?.url else { return nil }
        guard let urlComponents = NSURLComponents(url: messageURL, resolvingAgainstBaseURL: false), queryItems = urlComponents.queryItems else { return nil }
        
        self.init(queryItems: queryItems)
    }
}


extension TicTacToe: Equatable {}

func ==(lhs: TicTacToe, rhs: TicTacToe) -> Bool {
    return lhs.player == rhs.player && lhs.opponent == rhs.opponent && lhs.boardToJSON() == rhs.boardToJSON()
}
