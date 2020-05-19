//
//  AASwipeableView.swift
//  AASwipeableCards
//
//  Created by Muhammad Ahsan Ali on 2020/05/14.
//

import Foundation

public class AASwipeableView: UIView {
    
    public typealias AACardReusable = ((Int, UIView?) -> UIView)
    
    public var currentIndex = 0
    var reusingView: UIView? = nil
    var visibleCards = [UIView]()
    var swipeEnded = true
    var xFromCenter: CGFloat = 0
    var yFromCenter: CGFloat = 0
    var originalPoint: CGPoint = .zero
    var onCardChange: AACardReusable?
    
    let rotationStrength: CGFloat = 320
    let rotationMax: CGFloat      = 0.7
    let rotationAngle: CGFloat    = .pi * 0.125
    let scaleStrength: CGFloat    = 4.0
    let scaleMax: CGFloat         = 0.6
    let actionMargin: CGFloat     = 120
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(handleCardDrag))
    }()
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
    }()

    public var totalItems: Int = 0
    
    public var repeatCards = true
    
    public var deltaVisibleWidth: CGFloat? = 20
    
    public var offset: (h: CGFloat, v: CGFloat) = (0, 10)
    
    public var onCardSwipe: ((Int, Bool) -> ())?
    
    public var didTap: ((Int) -> ())?
    
    public var visibleItems = 3
    
    public var swipEnabled = true {
        didSet {
            panGestureRecognizer.isEnabled = swipEnabled
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
}

public extension AASwipeableView {
    
    func insertCards(withCount total: Int, onCardChange: AACardReusable? = nil) {
        if let onCardChange = onCardChange {
            self.onCardChange = onCardChange
            totalItems = 0
            reusingView = nil
            visibleCards.removeAll()
        }
        precondition(self.onCardChange != nil, "AASwipeableView:- AACardReusable is not initialized")
        
        var prevItemCount = totalItems - 1

        if totalItems == 0 {
            currentIndex = 0
            prevItemCount = 0
        }
        
        totalItems += total
        currentIndex = prevItemCount
        
        reloadData()
    }
    
    func reloadData() {
        reusingView = nil
        visibleCards.removeAll()
        let visibleNumber = visibleItems > totalItems ? totalItems : visibleItems
        for i in currentIndex..<visibleNumber+currentIndex {
            if let card = onCardChange?(i, reusingView) {
                visibleCards.append(card)
            }
        }
        
        layoutCards()
    }
    
}
extension AASwipeableView {
    
    func setUp() {
        self.addGestureRecognizer(panGestureRecognizer)
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func layoutCards() {
        let count = visibleCards.count
        guard count > 0 else {
            return
        }
        
        subviews.forEach { $0.removeFromSuperview() }
        layoutIfNeeded()
        
        let width = frame.size.width
        let height = frame.size.height
        if let lastCard = visibleCards.last {
            let cardWidth = lastCard.frame.size.width
            let cardHeight = lastCard.frame.size.height
            
            let visibleNumber = visibleItems > totalItems ? totalItems : visibleItems
            var firstCardX = (width - cardWidth - CGFloat(visibleNumber - 1) * abs(offset.h)) * 0.5
            if offset.h < 0 {
                firstCardX += CGFloat(visibleNumber - 1) * abs(offset.h)
            }
            var firstCardY = (height - cardHeight - CGFloat(visibleNumber - 1) * abs(offset.v)) * 0.5
            if offset.v < 0 {
                firstCardY += CGFloat(visibleNumber - 1) * abs(offset.v)
            }
            
            for i in 0..<count {
                let index = count - 1 - i
                let card = self.visibleCards[index]
                let size = card.frame.size
                card.frame = CGRect(x: firstCardX + CGFloat(index) * self.offset.h, y: firstCardY + CGFloat(index) * self.offset.v, width: size.width, height: size.height)
                self.addSubview(card)
                
            }
            
            changeVisibleCardWidths(false)
            
            visibleCards.last?.shakeY()
            
            
        }
    }
    
    func changeVisibleCardWidths(_ reset: Bool) {
        guard let delta = deltaVisibleWidth, delta > 0, visibleCards.count > 0 else {
            return
        }
        
        if reset {
            visibleCards.enumerated().forEach {
                $1.frame.size.width = self.visibleCards.first!.frame.size.width
            }
        }
        else {
            visibleCards.enumerated().forEach {
                $1.frame.size.width -= (CGFloat($0) * CGFloat(20))
                $1.center.x = self.visibleCards[0].center.x
            }
        }
        
    }
    
    @objc func handleCardDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard visibleCards.count > 0 else {
            return
        }
        if currentIndex > totalItems - 1 {
            currentIndex = 0
        }
        if swipeEnded {
            swipeEnded = false
        }
        if let firstCard = visibleCards.first {
            xFromCenter = gestureRecognizer.translation(in: firstCard).x
            yFromCenter = gestureRecognizer.translation(in: firstCard).y
            switch gestureRecognizer.state {
            case .began:
                originalPoint = firstCard.center
            case .changed:
                let rotationStrength: CGFloat = min(xFromCenter / self.rotationStrength, rotationMax)
                let rotationAngel = rotationAngle * rotationStrength
                let scale = max(1.0 - abs(rotationStrength) / scaleStrength, scaleMax)
                firstCard.center = CGPoint(x: originalPoint.x + xFromCenter, y: originalPoint.y + yFromCenter)
                let transform = CGAffineTransform(rotationAngle: rotationAngel)
                let scaleTransform = transform.scaledBy(x: scale, y: scale)
                firstCard.transform = scaleTransform
            case .ended:
                swipeDidEnd(firstCard)
            default:
                break
            }
        }
    }
    
    @objc func handleCardTap(sender: UIGestureRecognizer) {
        visibleCards.first?.shakeX()
        didTap?(currentIndex)
    }
    
    func swipeDidEnd(_ card: UIView) {
        if xFromCenter > actionMargin {
            rightSwipeAction(card)
        } else if xFromCenter < -actionMargin {
            leftSwipeAction(card)
        } else {
            self.swipeEnded = true
            UIView.animate(withDuration: 0.3) {
                card.center = self.originalPoint
                card.transform = CGAffineTransform(rotationAngle: 0)
            }
        }
        
    }
    func rightSwipeAction(_ card: UIView) {
        let finishPoint = CGPoint(x: 500, y: 2.0 * yFromCenter + originalPoint.y)
        UIView.animate(withDuration: 0.3, animations: {
            card.center = finishPoint
        }) { (Bool) in
            self.cardDidSwiped(card)
        }
    }
    func leftSwipeAction(_ card: UIView) {
        let finishPoint = CGPoint(x: -500, y: 2.0 * yFromCenter + originalPoint.y)
        UIView.animate(withDuration: 0.3, animations: {
            card.center = finishPoint
        }) { (Bool) in
            self.cardDidSwiped(card)
        }
    }
    func cardDidSwiped(_ card: UIView) {
        swipeEnded = true
        card.transform = CGAffineTransform(rotationAngle: 0)
        card.center = originalPoint
        let cardFrame = card.frame
        reusingView = card
        
        changeVisibleCardWidths(true)
        
        visibleCards.removeFirst()
        card.removeFromSuperview()
        var newCard: UIView?
        
        var newIndex = currentIndex + visibleItems
        
        if newIndex < totalItems {
            newCard = onCardChange?(newIndex, reusingView)
        } else {
            
            if repeatCards {
                if totalItems==1 {
                    newIndex = 0
                } else {
                    newIndex %= totalItems
                }
                newCard = onCardChange?(newIndex, reusingView)
            }
            

        }
        if let card = newCard {
            card.frame = cardFrame
            visibleCards.append(card)
        }
                
        let foundLast = currentIndex == totalItems - 2
        onCardSwipe?(currentIndex, foundLast)

        currentIndex += 1

        layoutCards()
    }
    
}


fileprivate extension UIView {
    func shakeX() {
        self.transform = CGAffineTransform(translationX: 10, y: 1)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }
    
    func shakeY() {
        self.transform = CGAffineTransform(translationX: 1, y: 20)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .transitionCrossDissolve, animations: {
            self.transform = .identity
        }, completion: nil)
    }
}
