//
//  GameView.swift
//  TicTacToe
//
//  Created by Amar Ramachandran on 6/17/16.
//  Copyright © 2016 amarjayr. All rights reserved.
//

import UIKit

class GameView: UICollectionView {
    var game: TicTacToe?

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
