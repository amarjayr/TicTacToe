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
    private var grid: [[TTTCellState]]
    private var cacheWinner: Player?

    let player: Player!
    let opponents: [Player]!

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
        if let w = cacheWinner {
            return w
        } else if let w = checkWinner() {
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

    // MARK: Square manipulation

    func selectCell(row x: Int, column y: Int) throws {
        guard x < size && y < size && x >= 0 && y >= 0 else {
            fatalError("Coordinates not on grid")
        }

        guard winner == nil else {
            throw TTTError.gameDone
        }
        
        var round = 0
        for p in opponents {
            let r = moveCount(for: p)
            if (r > round) {
                round = r
            }
        }

        guard round >= moveCount(for: player) else {
            throw TTTError.notPlayerTurn
        }

        if case .empty = getCell(row: x, column: y) {
            self[x, y] = TTTCellState.occupied(player!)
        } else {
            throw TTTError.positionOccupied
        }

        cacheWinner = checkWinnerAfterMove(row: x, column: y)
    }

    func getCell(row x: Int, column y: Int) -> TTTCellState {
        return self[x, y]
    }

    // MARK: Winning/Gameover checks

    private func checkWinnerAfterMove(row x: Int, column y: Int) -> Player? {
        guard x < size && y < size && x >= 0 && y >= 0 else {
            fatalError("Coordinates not on grid")
        }

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
        
        // TODO: implement efficient diagonal/antidiagonal traversing base on certain diagonal
        return checkDiagonal() ?? checkAntidiagonal()
    }

    private func isDraw() -> Bool {
        return moveCount(for: player!) == Int(pow(Decimal(size), 2) - 1)
    }

    private func checkWinner() -> Player? {
        var userOwned = Array(repeating: 0, count: size*2)
        var opponentsOwned = [Player: [Int]]()
        
        for opponent in opponents {
            opponentsOwned[opponent] = Array(repeating: 0, count: size*2)
        }
        
        for i in 0..<size {
            for j in 0..<size {
                if case .occupied(let user) = self[i, j] where user == player {
                    userOwned[j] += 1
                } else if case .occupied(let user) = self[i, j] {
                    if opponentsOwned[user]?[j] == nil {
                        opponentsOwned[user]![j] = 0
                    }
                    
                    opponentsOwned[user]![j] += 1
                }
            }
        }

        for j in 0..<size {
            for i in 0..<size {
                if case .occupied(let user) = self[i, j] where user == player {
                    userOwned[i+size] += 1
                } else if case .occupied(let user) = self[i, j] {
                    if opponentsOwned[user]?[i+size] == nil {
                        opponentsOwned[user]?[i+size] = 0
                    }
                    
                    opponentsOwned[user]![i+size] += 1
                }
            }
        }
        for numberOwned in userOwned {
            if numberOwned == requiredInARow {
                cacheWinner = player
                return player
            }
        }

        for (opponentP, array) in opponentsOwned {
            for numberOwned in array {
                if numberOwned == requiredInARow {
                    cacheWinner = opponentP
                    return opponentP
                }
            }
        }

        return checkDiagonal() ?? checkAntidiagonal()
    }
    
    private func checkDiagonal() -> Player? {
        var rowsCurrent = [Int:Int]()
        
        var rowsOpponents = [Player: [Int]]()
        
        for opponent in opponents {
            rowsOpponents[opponent] = Array(repeating: 0, count: (2*size-1))
        }
        
        for slice in 0..<(2*size-1) {
            let z = slice < size ? 0 : slice - size + 1
            let j = z
            
            for j in j..<(slice-z)+1 {                
                if case .occupied(let user) = self[j, slice - j] where user == player  {
                    if rowsCurrent[slice] == nil {
                        rowsCurrent[slice] = 0
                    }
                    
                    rowsCurrent[slice]! += 1
                } else if case .occupied(let user) = self[j, slice - j]   {
                    if rowsOpponents[user]?[slice] == nil {
                        rowsOpponents[user]![slice] = 0
                    }
                    
                    rowsOpponents[user]![slice] += 1
                }
            }
        }
        
        for (_, len) in rowsCurrent {
            if len >= requiredInARow {
                return player
            }
        }
        
        for (opponentP, array) in rowsOpponents {
            for numberOwned in array {
                if numberOwned >= requiredInARow {
                    return opponentP
                }
            }
        }
        
        return nil
    }
    
    private func checkAntidiagonal() -> Player? {
        var rowsCurrent = [Int:Int]()
        var rowsOpponents = [Player: [Int]]()
        
        for opponent in opponents {
            rowsOpponents[opponent] = Array(repeating: 0, count: (2*size-1))
        }
        
        
        for slice in 0..<(2*size-1) {
            let z = slice < size ? 0 : slice - size + 1
            let j = z
            
            for j in j..<(slice-z)+1 {
                
                if case .occupied(let user) = self[j, (size-1)-(slice-j)] where user == player  {
                    if rowsCurrent[slice] == nil {
                        rowsCurrent[slice] = 0
                    }
                    
                    rowsCurrent[slice]! += 1
                } else if case .occupied(let user) = self[j, (size-1)-(slice-j)] {
                    if rowsOpponents[user]?[slice] == nil {
                        rowsOpponents[user]?[slice] = 0
                    }
                    
                    rowsOpponents[user]![slice] += 1
                }
            }
        }
        
        for (_, len) in rowsCurrent {
            if len >= requiredInARow {
                return player
            }
        }
        
        for (opponentP, array) in rowsOpponents {
            for numberOwned in array {
                if numberOwned >= requiredInARow {
                    return opponentP
                }
            }
        }
        
        return nil
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
        
        #if (arch(i386) || arch(x86_64))
            current = Player(uuid: opponents?[0].uuid, color: opponents?[0].color)
            opponents?.remove(at: 0)
        #endif
        
        opponents = opponents?.filter({ (value: Player) -> Bool in
            if value.uuid != uuid {
                return true
            } else {
                #if !(arch(i386) || arch(x86_64))
                    current = value
                #endif
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

extension UIColor {
    public func hexString(includeAlpha: Bool) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        } else {
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }

    public convenience init(hex: String, alpha: CGFloat? = 1.0) {
        var hexInt: UInt32 = 0
        let scanner: Scanner = Scanner(string: hex)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        scanner.scanHexInt32(&hexInt)

        let hexint = Int(hexInt)
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
        let alpha = alpha!

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
