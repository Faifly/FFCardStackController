//
//  FFCardStackController.swift
//  FFCardStackController
//
//  Created by Artem Kalmykov on 9/24/16.
//  Copyright © 2016 Faifly. All rights reserved.
//

import UIKit

public enum FFCardStackResult
{
    case Liked
    case Disliked
}

public protocol FFCardStackControllerDelegate: class
{
    func cardStackController(_ cardStackController: FFCardStackController, cardForIndex index: Int) -> FFCardStackCard?
    func cardStackController(_ cardStackController: FFCardStackController, didDismissCardWithResult: FFCardStackResult)
}

open class FFCardStackCard: NSObject
{
    // MARK: Public properties
    open var view: UIView!
    open weak var likeView: UIView?
    open weak var dislikeView: UIView?
    
    // MARK: - Private
    // MARK: Constraints
    fileprivate var externalConstraints = [NSLayoutConstraint]()
    
    fileprivate func createExternalConstraints(leadingOffset: CGFloat, trailingOffset: CGFloat)
    {
        self.externalConstraints.removeAll()
        
        let verticalLayout = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(leadingOffset)-[card]-\(trailingOffset)-|", options: [], metrics: nil, views: ["card": self])
        let horizontalLayout = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(leadingOffset)-[card]-\(trailingOffset)-|", options: [], metrics: nil, views: ["card": self])
        
        self.externalConstraints.append(contentsOf: verticalLayout)
        self.externalConstraints.append(contentsOf: horizontalLayout)
        
        NSLayoutConstraint.activate(self.externalConstraints)
    }
    
    fileprivate func removeExternalConstraints()
    {
        NSLayoutConstraint.deactivate(self.externalConstraints)
    }
    
    // MARK: Recognizers
    fileprivate var panRecognizer: UIPanGestureRecognizer?
    
    fileprivate func setupPanRecognizer(target: AnyObject, selector: Selector)
    {
        if self.panRecognizer != nil
        {
            self.view.removeGestureRecognizer(self.panRecognizer!)
        }
        self.panRecognizer = UIPanGestureRecognizer(target: target, action: selector)
        self.view.addGestureRecognizer(panRecognizer!)
    }
}

open class FFCardStackController: UIViewController
{
    // MARK: Public properties
    open weak var delegate: FFCardStackControllerDelegate!
    open var maxSimultaneousCards = 3
    open var defaultOffset: CGFloat = 30.0
    open var indexOffset: CGFloat = 5.0
    
    // MARK: Private properties
    fileprivate var cards = [FFCardStackCard]()
    
    // MARK: View controller
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.delegate != nil)
        
        self.reloadCards()
    }
    
    // MARK: Public methods
    open func reloadCards()
    {
        self.clearFromCards()
        self.loadCards(startIndex: 0, endIndex: self.maxSimultaneousCards)
    }
    
    open func continueLoadingCards()
    {
        self.loadCards(startIndex: self.cards.count, endIndex: self.maxSimultaneousCards)
    }
    
    open func likeTopCard(animated: Bool = true)
    {
        // TODO: Implement
    }
    
    open func dislikeTopCard(animated: Bool = true)
    {
        // TODO: Implement
    }
    
    // MARK: Logic
    fileprivate func clearFromCards()
    {
        self.cards.forEach({$0.view.removeFromSuperview(); $0.removeExternalConstraints()})
        self.cards.removeAll()
    }
    
    fileprivate func loadCards(startIndex: Int, endIndex: Int)
    {
        guard startIndex < endIndex else
        {
            return
        }
        
        for i in startIndex..<endIndex
        {
            if let card = self.delegate.cardStackController(self, cardForIndex: i)
            {
                self.cards.append(card)
                
                self.view.addSubview(card.view)
                
                let leadingOffset = self.defaultOffset + self.indexOffset * CGFloat(i)
                let trailingOffset = self.defaultOffset - self.indexOffset * CGFloat(i)
                card.createExternalConstraints(leadingOffset: leadingOffset, trailingOffset: trailingOffset)
                
                card.setupPanRecognizer(target: self, selector: #selector(onPanGesture))
            }
            else
            {
                break
            }
        }
    }
    
    fileprivate func removeTopCard(animated: Bool = true)
    {
        /* TODO: Implement it
            1. Remove top card from superview and cards array.
            2. Update existing cards - update their constraints
            3. Load the next card (continue loading cards)
        */
    }
    
    @objc fileprivate func onPanGesture(sender: UIPanGestureRecognizer)
    {
        // TODO: Should change card's position here. If some threshold is reached, should proceed with either like or dislike
    }
}
