//
//  ViewController.swift
//  AASwipeableCards
//
//  Created by engrahsanali on 05/13/2020.
//  Copyright (c) 2020 engrahsanali. All rights reserved.
//

import UIKit
import AASwipeableCards

class ViewController: UIViewController {

    @IBOutlet weak var cardView: AASwipeableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let colors: [UIColor] = [.red, .orange, .blue, .brown, .darkGray, .magenta, .purple]
    var moreCards = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cardView.deltaVisibleWidth = 20
        cardView.repeatCards = false
        
        cardView.onCardSwipe = { index, isLast in
            print("Swiped card at ", index)
            
            if isLast {
                guard self.moreCards else {
                    return
                }
                print("Last card")
                self.activityIndicator.startAnimating()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    
                    self.activityIndicator.stopAnimating()
                    self.cardView.insertCards(withCount: 2)
                    self.cardView.repeatCards = true
                    self.moreCards = false
                }
            }
        }
        
        
        cardView.didTap = {
            print($0)
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cardView.insertCards(withCount: 30) { (index, reusingView) -> UIView in
            var label: UILabel? = reusingView as? UILabel
            if label == nil {
                label = UILabel(frame: self.cardView.frame)
                label!.textAlignment = .center
                label!.layer.cornerRadius = 10
            }
            label!.text = "Card # \(index + 1)"
            label!.layer.backgroundColor = self.colors.randomElement()?.cgColor
            return label!
        }
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func reloadAtIndexAction(_ sender: Any) {
        cardView.currentIndex = 2
        cardView.reloadData()
        
    }
    
}

