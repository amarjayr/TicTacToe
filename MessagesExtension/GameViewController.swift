//
//  BoardViewController.swift
//  TicTacToe
//
//  Created by Amar Ramachandran on 6/17/16.
//  Copyright © 2016 amarjayr. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    static let storyboardIdentifier = "GameViewController"

    weak var delegate: GameViewControllerDelegate?

    var game: TicTacToe?

    @IBOutlet weak var gameView: GameView?
    @IBOutlet weak var gameViewWithConstraint: NSLayoutConstraint!

    @IBOutlet var gameOverView: UIView!
    @IBOutlet weak var gameDoneViewTitle: UILabel!
    @IBOutlet weak var gameDoneViewPlayAgain: UIButton!
    
    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        gameView!.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)
        self.view.addSubview(gameView!)

        gameView?.game = game!

        gameView?.delegate = self
        gameView?.dataSource = self

        let layout = gameView?.collectionViewLayout as? UICollectionViewFlowLayout
        layout!.minimumInteritemSpacing = 10.0
        layout!.minimumLineSpacing = 17.0

        self.view.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)
        self.gameView?.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)
    }

    override func viewDidLayoutSubviews() {
        if let winner = game?.winner {
            gameOverView.frame = self.view.frame
            gameDoneViewPlayAgain.layer.cornerRadius = 25
            gameDoneViewPlayAgain.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
            gameDoneViewPlayAgain.layer.shadowOpacity = 0.2
            gameDoneViewPlayAgain.layer.shadowOffset = CGSize(width: 0, height: 2)
            gameDoneViewPlayAgain.layer.shadowRadius = 4
            gameOverView.backgroundColor = #colorLiteral(red: 0.8470588235, green: 0.8470588235, blue: 0.8470588235, alpha: 0.6)

            if winner == game!.player {
                gameDoneViewTitle.text = "You Win!"
            } else if game!.opponents.contains(game!.winner!) {
                gameDoneViewTitle.text = "You Lose."
            } else if winner.uuid == nil {
                gameDoneViewTitle.text = "Draw."
            }

            self.view.addSubview(gameOverView)
            
            gameDoneViewPlayAgain.addTarget(self, action: #selector(newGameTapped), for: .touchUpInside)
        }

    }
    func newGameTapped() {
        delegate?.requestNewGame()
    }
}

protocol GameViewControllerDelegate: class {
    func gameViewController(_ controller: GameViewController, renderedImage: UIImage)
    func requestNewGame()
}

extension GameViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(pow(Double(game!.size), 2.0))
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = gameView!.dequeueReusableCell(withReuseIdentifier: "TicTacToeCell", for: indexPath)

        if case .occupied(let user) = game![indexPath.row%(game?.size)!, Int(floor(Double(indexPath.row/(game?.size)!)))] {
            cell.contentView.backgroundColor = user.color
        } else {
            cell.contentView.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)

            cell.layer.borderColor = #colorLiteral(red: 0.9607843137, green: 0.6980392157, blue: 0.3607843137, alpha: 1).cgColor
            cell.layer.borderWidth = 3
        }

        cell.layer.cornerRadius = cell.frame.height/2

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as? UICollectionViewFlowLayout

        return CGSize(width: floor(gameView!.bounds.size.width / CGFloat(game!.size))-layout!.minimumInteritemSpacing, height: floor(gameView!.bounds.size.width / CGFloat(game!.size))-layout!.minimumInteritemSpacing)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = Int(indexPath.row%(game?.size)!)
        let column = Int(floor(Double(indexPath.row/(game?.size)!)))

        do {
            try game!.selectCell(row: row, column: column)
            collectionView.reloadItems(at: [indexPath])

            delegate!.gameViewController(self, renderedImage: self.gameView!.createImage())
        } catch TTTError.positionOccupied {
            print("POSITION OCCUPIED")
        } catch TTTError.notPlayerTurn {
            print("NOT PLAYER TURN")
        } catch TTTError.gameDone {
            print("GAME IS DONE")
        } catch {
            print("unkown error")
        }
    }
}

extension UIView {
    func createImage() -> UIImage {
        let rect: CGRect = self.frame

        UIGraphicsBeginImageContextWithOptions(rect.size, self.isOpaque, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        self.layer.render(in: context)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return img!
    }

}
