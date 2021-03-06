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
    func cardStackController(_ cardStackController: FFCardStackController, didTapOnCard card: FFCardStackCard)
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
    fileprivate var horizontalOffset: CGFloat = 0.0
    fileprivate var topOffset: CGFloat = 0.0
    fileprivate var bottomOffset: CGFloat = 0.0
    
    fileprivate func createExternalConstraints(horizontalOffset: CGFloat, topOffset: CGFloat, bottomOffset: CGFloat)
    {
        self.horizontalOffset = horizontalOffset
        self.topOffset = topOffset
        self.bottomOffset = bottomOffset
        
        self.externalConstraints.removeAll()
        
        let verticalLayout = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(topOffset)-[card]-\(bottomOffset)-|", options: [], metrics: nil, views: ["card": self.view])
        let horizontalLayout = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(horizontalOffset)-[card]-\(horizontalOffset)-|", options: [], metrics: nil, views: ["card": self.view])
        
        self.externalConstraints.append(contentsOf: verticalLayout)
        self.externalConstraints.append(contentsOf: horizontalLayout)
        
        NSLayoutConstraint.activate(self.externalConstraints)
    }
    
    fileprivate func updateConstraints()
    {
        for constraint in self.externalConstraints
        {
            if constraint.firstAttribute == .top
            {
                constraint.constant = self.topOffset
            }
            else if constraint.firstAttribute == .trailing || constraint.firstAttribute == .leading
            {
                constraint.constant = self.horizontalOffset
            }
            else if constraint.firstAttribute == .bottom
            {
                constraint.constant = self.bottomOffset
            }
        }
    }
    
    fileprivate func removeExternalConstraints()
    {
        NSLayoutConstraint.deactivate(self.externalConstraints)
    }
    
    // MARK: Recognizers
    private var panRecognizer: UIPanGestureRecognizer?
    
    fileprivate func setupPanRecognizer(target: AnyObject, selector: Selector)
    {
        if self.panRecognizer != nil
        {
            self.view.removeGestureRecognizer(self.panRecognizer!)
        }
        self.panRecognizer = UIPanGestureRecognizer(target: target, action: selector)
        self.view.addGestureRecognizer(self.panRecognizer!)
    }
    
    private var tapRecognizer: UITapGestureRecognizer?
    
    fileprivate func setupTapRecognizer(target: AnyObject, selector: Selector)
    {
        if self.tapRecognizer != nil
        {
            self.view.removeGestureRecognizer(self.tapRecognizer!)
        }
        self.tapRecognizer = UITapGestureRecognizer(target: target, action: selector)
        self.view.addGestureRecognizer(self.tapRecognizer!)
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
    private var isAnimationInProgress = false
    
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
        
        guard !self.isAnimationInProgress else
        {
            return
        }
        
        let card = self.cards.first!
        
        var y: CGFloat = 0.0
        if self.originalCenter != nil
        {
            y = -(self.originalCenter.y - card.view.center.y)
        }
        
        self.originalCenter = card.view.center
        self.moveCard(card, byX: card.view.bounds.size.width * 1.33, byY: y, animated: animated) { [unowned self] in
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
        
        guard !self.isAnimationInProgress else
        {
            return
        }
        
        let card = self.cards.first!
        
        var y: CGFloat = 0.0
        if self.originalCenter != nil
        {
            y = -(self.originalCenter.y - card.view.center.y)
        }
        
        self.originalCenter = card.view.center
        self.moveCard(card, byX: -card.view.bounds.size.width * 1.33, byY: y, animated: animated) { [unowned self] in
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
                
                let minorOffset = self.defaultOffset + self.indexOffset * CGFloat(i)
                let majorOffset = self.defaultOffset - self.indexOffset * CGFloat(i)
                card.createExternalConstraints(horizontalOffset: minorOffset, topOffset: minorOffset, bottomOffset: majorOffset)
                
                card.setupPanRecognizer(target: self, selector: #selector(onPanGesture))
                card.setupTapRecognizer(target: self, selector: #selector(onTap))
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
            card.horizontalOffset -= self.indexOffset
            card.topOffset -= self.indexOffset
            card.bottomOffset += self.indexOffset
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
        self.moveCard(card, byX: self.originalCenter.x - card.view.center.x, byY: self.originalCenter.y - card.view.center.y, animated: animated)
    }
    
    private func moveCard(_ card: FFCardStackCard, byX x: CGFloat, byY y: CGFloat, animated: Bool = false, completion: (() -> ())? = nil)
    {
        let alphaAmplificationFactor: CGFloat = 2.5
        
        let modifiedCenter = CGPoint(x: card.view.center.x + x, y: card.view.center.y + y)
        var likeAlpha: CGFloat = 0.0
        var dislikeAlpha: CGFloat = 0.0
        let angle: CGFloat = ((modifiedCenter.x - self.originalCenter.x) / card.view.bounds.size.width) * 0.35
        let transform = CGAffineTransform(rotationAngle: angle)
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
            self.isAnimationInProgress = true
            UIView.animate(withDuration: 0.5, animations: { [unowned card] in
                card.view.center = modifiedCenter
                card.likeView?.alpha = likeAlpha
                card.dislikeView?.alpha = dislikeAlpha
                card.view.transform = transform
                }, completion: { [weak self] completed in
                    if let handler = completion
                    {
                        handler()
                    }
                    self?.isAnimationInProgress = false
            })
        }
        else
        {
            card.view.center = modifiedCenter
            card.likeView?.alpha = likeAlpha
            card.dislikeView?.alpha = dislikeAlpha
            card.view.transform = transform
            if let handler = completion
            {
                handler()
            }
        }
    }
    
    private var dragStartPoint: CGPoint!
    private var originalCenter: CGPoint!
    @objc private func onPanGesture(sender: UIPanGestureRecognizer)
    {
        let locInView = sender.location(in: sender.view)
        let locInSuperview = sender.location(in: sender.view?.superview)
        if sender.state == .began
        {
            self.originalCenter = sender.view!.center
            self.dragStartPoint = locInSuperview
        }
        else if sender.state == .changed
        {
            self.moveCard(self.cards.first!, byX: locInView.x - self.dragStartPoint.x + self.defaultOffset, byY: locInView.y - self.dragStartPoint.y + self.defaultOffset)
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
                if self.originalCenter.x - locInSuperview.x < 0 // Moving to Right
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
    
    @objc private func onTap()
    {
        self.delegate.cardStackController(self, didTapOnCard: self.cards.first!)
    }
}
