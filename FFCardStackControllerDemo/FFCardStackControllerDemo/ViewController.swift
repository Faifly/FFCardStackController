//
//  ViewController.swift
//  FFCardStackControllerDemo
//
//  Created by Artem Kalmykov on 9/24/16.
//  Copyright © 2016 Faifly. All rights reserved.
//

import UIKit
import FFCardStackController

class ViewController: UIViewController, FFCardStackControllerDelegate
{
    weak var cardStackController: FFCardStackController!
    fileprivate var cardsSource = [5, 4, 3, 2, 1]
    
// MARK: View controller
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupCardStackController()
    }

// MARK: Setup
    
    fileprivate func setupCardStackController()
    {
        for vc in self.childViewControllers
        {
            if vc is FFCardStackController
            {
                self.cardStackController = vc as! FFCardStackController
                break
            }
        }
        assert(self.cardStackController != nil)
        
        self.cardStackController.delegate = self
        self.cardStackController.reloadCards()
    }
    
// MARK: Card Stack controller
    
    func cardStackController(_ cardStackController: FFCardStackController, cardForIndex index: Int) -> FFCardStackCard?
    {
        guard index < self.cardsSource.count else
        {
            return nil
        }
        
        let cardSource = self.cardsSource[index]
        let cardViewController = self.storyboard!.instantiateViewController(withIdentifier: "DemoCardViewController") as! DemoCardViewController
        cardViewController.loadViewIfNeeded()
        cardViewController.centerLabel.text = "Card #\(cardSource)"
        
        let card = FFCardStackCard(view: cardViewController.view, likeView: cardViewController.likingLabel, dislikeView: cardViewController.dislikingLabel)
        
        return card
    }
    
    func cardStackController(_ cardStackController: FFCardStackController, didDismissCard card: FFCardStackCard, withResult result: FFCardStackResult)
    {
        self.cardsSource.remove(at: card.index)
    }
}

