//
//  GamesHistory.swift
//  TicTacToe
//
//  Created by Amar Ramachandran on 6/17/16.
//  Copyright © 2016 amarjayr. All rights reserved.
//

import Foundation

struct GamesHistory {
    private static let maximumHistorySize = 5

    private static let userDefaultsKey = "ticTacToeGames"

    private var games: [TicTacToe]

    var count: Int {
        return games.count
    }

    subscript(index: Int) -> TicTacToe {
        return games[index]
    }

    private init(games: [TicTacToe]) {
        self.games = games
    }

    static func load(for uuid: String) -> GamesHistory {
        var games = [TicTacToe]()
        let defaults = UserDefaults.standard()

        if let savedGames = defaults.object(forKey: GamesHistory.userDefaultsKey) as? [String] {
            games = savedGames.flatMap { urlString in
                guard let url = URL(string: urlString) else { return nil }
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), queryItems = components.queryItems else { return nil }

                return TicTacToe(queryItems: queryItems, current: uuid)
            }
        }

        return GamesHistory(games: games)
    }

    /*static func load(for uuid: String, against opponent: String) -> GamesHistory {
        var games = [TicTacToe]()
        let defaults = UserDefaults.standard()

        if let savedGames = defaults.object(forKey: GamesHistory.userDefaultsKey) as? [String] {
            games = savedGames.flatMap { urlString in
                guard let url = URL(string: urlString) else { return nil }
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), queryItems = components.queryItems else { return nil }

                if let game = TicTacToe(queryItems: queryItems, current: uuid) where game.opponent.uuid == opponent {
                    return game
                } else {
                    return nil
                }

            }
        }

        return GamesHistory(games: games)
    }*/

    func save() {
        let gamesToSave = games.suffix(GamesHistory.maximumHistorySize)

        let gameURLStrings: [String] = gamesToSave.flatMap { game in
            var components = URLComponents()
            components.queryItems = game.queryItems

            return components.url?.absoluteString
        }

        let defaults = UserDefaults.standard()
        defaults.set(gameURLStrings as AnyObject, forKey: GamesHistory.userDefaultsKey)
    }

    mutating func append(_ game: TicTacToe) {
        var newGames = self.games.filter { $0 != game }
        newGames.append(game)

        games = newGames
    }

}
