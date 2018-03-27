//
//  MainViewController.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/4/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit
import Metal
import QuartzCore

class MainViewController: UIViewController, RaytracerViewDelegate {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var raytracerView: RaytracerView!
    @IBOutlet weak var renderingProgressView: UIProgressView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var helpViewController:UIViewController!
    var lightEditViewController:LightEditViewController!
    var moreViewController:MoreViewController!
    var sceneSelecViewController:SceneSelectViewController!
    var sphereEditViewController:SphereEditViewController!
    var wallEditViewController:WallEditViewController!
    
    @IBAction func selectPane(_ sender: UIBarButtonItem) {
        switch (sender.tag) {
        case 0:
            switchViewController(viewController: sceneSelecViewController)
            break
        case 1:
            switchViewController(viewController: lightEditViewController)
            lightEditViewController.update()
            break
        case 2:
            switchViewController(viewController: wallEditViewController)
            wallEditViewController.update()
            break
        case 3:
            switchViewController(viewController: moreViewController)
            break
        default: break
        }
        
        raytracerView.selectedSphere = -1
        toolbar.items?.forEach({ $0.tintColor = ($0 == sender ? UIColor.darkGray : UIColor.lightGray) })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if raytracerView.rendering == false {
            PresetScenes.scene = raytracerView.scene
            PresetScenes.selectPresetScene(sceneIndex: 0)
            raytracerView.startRendering()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewControllers()
        raytracerView.delegate = self
    }
    
    func setupChildViewControllers() {
        helpViewController = (storyboard?.instantiateViewController(withIdentifier: "HelpViewController"))!
        lightEditViewController = (storyboard?.instantiateViewController(withIdentifier: "LightEditViewController"))! as! LightEditViewController
        moreViewController = (storyboard?.instantiateViewController(withIdentifier: "MoreViewController"))! as! MoreViewController
        sceneSelecViewController = (storyboard?.instantiateViewController(withIdentifier: "SceneSelectViewController"))! as! SceneSelectViewController
        sphereEditViewController = (storyboard?.instantiateViewController(withIdentifier: "SphereEditViewController"))! as! SphereEditViewController
        wallEditViewController = (storyboard?.instantiateViewController(withIdentifier: "WallEditViewController"))! as! WallEditViewController
        
        addChildViewController(helpViewController)
        addChildViewController(lightEditViewController)
        addChildViewController(moreViewController)
        addChildViewController(sceneSelecViewController)
        addChildViewController(sphereEditViewController)
        addChildViewController(wallEditViewController)
        
        lightEditViewController.raytracerView = raytracerView
        moreViewController.raytracerView = raytracerView
        sceneSelecViewController.raytracerView = raytracerView
        sphereEditViewController.raytracerView = raytracerView
        wallEditViewController.raytracerView = raytracerView
    }
    
    func switchViewController(viewController:UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        containerView.addSubview(viewController.view)
        
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
            ])
        
        viewController.didMove(toParentViewController: self)
    }
    
    func raytracerViewDidCreateImage(image: UIImage) {
        self.renderingProgressView.setProgress(Float(raytracerView.samples)/2000.0, animated: true)
    }
    
    func raytracerViewDidSelectSphere(index:Int) {
        if (index > -1){
            switchViewController(viewController: sphereEditViewController)
            sphereEditViewController.update()
        } else {
            switchViewController(viewController: helpViewController)
        }
        toolbar.items?.forEach({ $0.tintColor = UIColor.lightGray })
    }
}

