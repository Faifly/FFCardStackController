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
    case like
    case dislike
}

public protocol FFCardStackControllerDelegate: class
{
    func cardStackController(_ cardStackController: FFCardStackController, cardForIndex index: Int) -> FFCardStackCard?
    func cardStackController(_ cardStackController: FFCardStackController, didDismissCard card: FFCardStackCard, withResult result: FFCardStackResult)
}

open class FFCardStackCard: NSObject
{
    // MARK: Public properties
    public var view: UIView!
    public weak var likeView: UIView?
    public weak var dislikeView: UIView?
    
    public fileprivate(set) var index: Int!
    
    override init()
    {
        super.init()
    }
    
    public convenience init(view: UIView, likeView: UIView?, dislikeView: UIView?)
    {
        self.init()
        
        self.view = view
        self.likeView = likeView
        self.dislikeView = dislikeView
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - Private
    // MARK: Constraints
    fileprivate var externalConstraints = [NSLayoutConstraint]()
    fileprivate var leadingOffset: CGFloat = 0.0
    fileprivate var trailingOffset: CGFloat = 0.0
    
    fileprivate func createExternalConstraints(leadingOffset: CGFloat, trailingOffset: CGFloat)
    {
        self.leadingOffset = leadingOffset
        self.trailingOffset = trailingOffset
        
        self.externalConstraints.removeAll()
        
        let verticalLayout = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(leadingOffset)-[card]-\(trailingOffset)-|", options: [], metrics: nil, views: ["card": self.view])
        let horizontalLayout = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(leadingOffset)-[card]-\(trailingOffset)-|", options: [], metrics: nil, views: ["card": self.view])
        
        self.externalConstraints.append(contentsOf: verticalLayout)
        self.externalConstraints.append(contentsOf: horizontalLayout)
        
        NSLayoutConstraint.activate(self.externalConstraints)
    }
    
    fileprivate func updateConstraints()
    {
        for constraint in self.externalConstraints
        {
            if constraint.firstAttribute == .top || constraint.firstAttribute == .leading
            {
                constraint.constant = self.leadingOffset
            }
            else if constraint.firstAttribute == .bottom || constraint.firstAttribute == .trailing
            {
                constraint.constant = self.trailingOffset
            }
        }
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
    open var defaultOffset: CGFloat = 15.0
    open var indexOffset: CGFloat = 5.0
    open var actionTriggerThreshold: CGFloat = 0.25
    
    // MARK: Private properties
    fileprivate var cards = [FFCardStackCard]()
    
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
        guard self.cards.count > 0 else
        {
            return
        }
        
        let card = self.cards.first!
        self.originalCenter = card.view.center
        self.moveCard(card, by: card.view.bounds.size.width, animated: animated) { [unowned self] in
            self.delegate.cardStackController(self, didDismissCard: card, withResult: .like)
            self.removeTopCard()
        }
    }
    
    open func dislikeTopCard(animated: Bool = true)
    {
        guard self.cards.count > 0 else
        {
            return
        }
        
        let card = self.cards.first!
        self.originalCenter = card.view.center
        self.moveCard(card, by: -card.view.bounds.size.width, animated: animated) { [unowned self] in
            self.delegate.cardStackController(self, didDismissCard: card, withResult: .dislike)
            self.removeTopCard()
        }
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
                card.view.isUserInteractionEnabled = i == 0
                card.index = i
                card.likeView?.alpha = 0.0
                card.dislikeView?.alpha = 0.0
                
                self.cards.append(card)
                
                self.view.insertSubview(card.view, at: 0)
                
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
    
    private func removeTopCard(animated: Bool = true)
    {
        self.cards.first!.view.removeFromSuperview()
        self.cards.removeFirst()
        
        for card in self.cards
        {
            card.index = card.index - 1
            card.leadingOffset -= self.indexOffset
            card.trailingOffset += self.indexOffset
            card.updateConstraints()
        }
        
        self.cards.first?.view.isUserInteractionEnabled = true
        
        if animated
        {
            UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                self.view.layoutIfNeeded()
            })
        }
        else
        {
            self.view.layoutIfNeeded()
        }
        
        self.continueLoadingCards()
    }
    
    private func returnTopCardToInitialPosition(animated: Bool = true)
    {
        let card = self.cards.first!
        self.moveCard(card, by: self.originalCenter.x - card.view.center.x, animated: animated)
    }
    
    private func moveCard(_ card: FFCardStackCard, by x: CGFloat, animated: Bool = false, completion: (() -> ())? = nil)
    {
        let alphaAmplificationFactor: CGFloat = 2.5
        
        let modifiedCenter = CGPoint(x: card.view.center.x + x, y: card.view.center.y)
        var likeAlpha: CGFloat = 0.0
        var dislikeAlpha: CGFloat = 0.0
        if modifiedCenter.x - self.originalCenter.x > 0.0
        {
            likeAlpha = ((modifiedCenter.x - self.originalCenter.x) / card.view.bounds.size.width) * alphaAmplificationFactor
        }
        else
        {
            dislikeAlpha = ((self.originalCenter.x - modifiedCenter.x) / card.view.bounds.size.width) * alphaAmplificationFactor
        }
        if animated
        {
            UIView.animate(withDuration: 0.5, animations: { [unowned card] in
                card.view.center = modifiedCenter
                card.likeView?.alpha = likeAlpha
                card.dislikeView?.alpha = dislikeAlpha
                }, completion: { completed in
                    if let handler = completion
                    {
                        handler()
                    }
            })
        }
        else
        {
            card.view.center = modifiedCenter
            card.likeView?.alpha = likeAlpha
            card.dislikeView?.alpha = dislikeAlpha
            if let handler = completion
            {
                handler()
            }
        }
    }
    
    private var dragStartPoint: CGPoint!
    private var originalCenter: CGPoint!
    @objc fileprivate func onPanGesture(sender: UIPanGestureRecognizer)
    {
        let locInView = sender.location(in: sender.view)
        if sender.state == .began
        {
            self.originalCenter = sender.view!.center
            self.dragStartPoint = locInView
        }
        else if sender.state == .changed
        {
            self.moveCard(self.cards.first!, by: locInView.x - self.dragStartPoint.x)
        }
        else if sender.state == .cancelled || sender.state == .failed
        {
            self.returnTopCardToInitialPosition()
            self.dragStartPoint = nil
        }
        else if sender.state == .ended
        {
            if fabs(self.originalCenter.x - sender.view!.center.x) < sender.view!.bounds.size.width * self.actionTriggerThreshold
            {
                self.returnTopCardToInitialPosition()
            }
            else
            {
                if self.originalCenter.x - locInView.x > 0 // Moving to Right
                {
                    self.likeTopCard()
                }
                else
                {
                    self.dislikeTopCard()
                }
            }
            
            self.dragStartPoint = nil
        }
    }
}
