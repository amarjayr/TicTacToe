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
    @IBOutlet weak var gameViewHeightConstraint: NSLayoutConstraint!

    private var gameDoneView: UIVisualEffectView?

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
            if gameDoneView == nil {
                let blurEffect = UIBlurEffect(style: .light)

                gameDoneView = UIVisualEffectView(effect: blurEffect)
                gameDoneView?.clipsToBounds = true
                gameDoneView?.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
                gameDoneView?.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin]
                gameDoneView?.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
                gameDoneView?.layer.borderWidth = 2.0
                gameDoneView?.layer.cornerRadius = 6.0
                gameDoneView?.layer.borderColor = #colorLiteral(red: 0.1431525946, green: 0.4145618975, blue: 0.7041897774, alpha: 0.7).cgColor
                gameDoneView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.6)

                let winnerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: (gameDoneView?.frame.size.width)!, height: (gameDoneView?.frame.size.height)!))
                winnerLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7)
                winnerLabel.textAlignment = .center
                winnerLabel.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin]
                winnerLabel.center = CGPoint(x: (gameDoneView?.bounds.midX)!, y: (gameDoneView?.bounds.midY)!)
                winnerLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightSemibold)

                if winner == game!.player {
                    winnerLabel.text = "You won!"
                } else if winner == game!.opponent {
                    winnerLabel.text = "You lost."
                } else if winner.uuid == nil {
                    winnerLabel.text = "Draw!"
                }

                view.addSubview(gameDoneView!)
                gameDoneView?.contentView.addSubview(winnerLabel)
            }
        }

    }

}

protocol GameViewControllerDelegate: class {
    func gameViewController(_ controller: GameViewController, renderedImage: UIImage)
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
