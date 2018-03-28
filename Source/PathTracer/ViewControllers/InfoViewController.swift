//
//  InfoViewController.swift
//  MetalTracer
//
//  Created by Andrew Ingebretsen on 3/6/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    @IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
