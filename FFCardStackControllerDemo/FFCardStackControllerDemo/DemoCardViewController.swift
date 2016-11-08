//
//  DemoCardViewController.swift
//  FFCardStackControllerDemo
//
//  Created by Artem Kalmykov on 08.11.16.
//  Copyright © 2016 Faifly. All rights reserved.
//

import UIKit

class DemoCardViewController: UIViewController
{
    @IBOutlet weak var likingLabel: UILabel!
    @IBOutlet weak var dislikingLabel: UILabel!
    @IBOutlet weak var centerLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.layer.masksToBounds = true
        self.view.layer.cornerRadius = 10.0
        self.view.layer.borderColor = UIColor.black.cgColor
        self.view.layer.borderWidth = 2.0
    }
}
