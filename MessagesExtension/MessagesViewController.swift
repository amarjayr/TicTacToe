//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Amar Ramachandran on 6/14/16.
//  Copyright © 2016 amarjayr. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    //var boardView : UIView?
    var game: TicTacToe?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Properties

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)

        // Present the view controller appropriate for the conversation and presentation style.
        presentViewController(for: conversation, with: presentationStyle)
    }

    // MARK: MSMessagesAppViewController

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        guard let conversation = activeConversation else { fatalError("Expected an active converstation") }

        // Present the view controller appropriate for the conversation and presentation style.
        presentViewController(for: conversation, with: presentationStyle)
    }

    // MARK: Child view controller presentation

    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        // Determine the controller to present.
        let controller: UIViewController
        if presentationStyle == .compact {
            //controller = instantiateGameHistoryViewController()            
            let game = TicTacToe(message: conversation.selectedMessage) ?? TicTacToe(player: conversation.localParticipantIdentifier.uuidString, opponent: conversation.remoteParticipantIdentifiers[0].uuidString)

            controller = instantiateGameViewController(with: game)
        } else {
            let game = TicTacToe(message: conversation.selectedMessage) ?? TicTacToe(player: conversation.localParticipantIdentifier.uuidString, opponent: conversation.remoteParticipantIdentifiers[0].uuidString)

            controller = instantiateGameViewController(with: game)
        }

        // Remove any existing child controllers.
        for child in childViewControllers {
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }

        // Embed the new controller.
        addChildViewController(controller)

        controller.view.frame = view.bounds
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)

        controller.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        controller.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        controller.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        controller.didMove(toParentViewController: self)
    }

    /*private func instantiateGameHistoryViewController() -> UIViewController {
        // Instantiate a `IceCreamsViewController` and present it.
        guard let controller = storyboard?.instantiateViewController(withIdentifier: GameHistoryViewController.storyboardIdentifier) as? GameHistoryViewController else { fatalError("Unable to instantiate an IceCreamsViewController from the storyboard") }

        controller.delegate = self

        return controller
    }*/

    private func instantiateGameViewController(with game: TicTacToe) -> UIViewController {
        // Instantiate a `BuildIceCreamViewController` and present it.
        guard let controller = storyboard?.instantiateViewController(withIdentifier: GameViewController.storyboardIdentifier) as? GameViewController else { fatalError("Unable to instantiate a GameViewController from the storyboard") }

        controller.game = game
        controller.delegate = self

        return controller
    }

    // MARK: Convenience

    private func composeMessage(with game: TicTacToe, caption: String, image: UIImage, session: MSSession? = nil) -> MSMessage {
        var components = URLComponents()
        components.queryItems = game.queryItems

        let layout = MSMessageTemplateLayout()
        layout.image = image
        layout.caption = caption

        let message = MSMessage(session: session ?? MSSession())
        message.url = components.url!
        message.layout = layout

        return message
    }
}

extension MessagesViewController: GameViewControllerDelegate {
    func gameViewController(_ controller: GameViewController, renderedImage: UIImage) {
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        guard let game = controller.game else { fatalError("Expected the controller to be displaying a game") }

        let message = composeMessage(with: game, caption: NSLocalizedString("", comment: ""), image: renderedImage, session: conversation.selectedMessage?.session)

        conversation.insert(message, localizedChangeDescription: NSLocalizedString("", comment: "")) { error in
            if let error = error {
                print(error)
            }
        }

        if game.winner != nil {
            var history = GamesHistory.load()
            history.append(game)
            history.save()
        }

        dismiss()
    }
}
