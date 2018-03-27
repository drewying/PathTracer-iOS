//
//  SceneSelectViewController.swift
//  MetalTracer
//
//  Created by Ingebretsen, Andrew (HBO) on 3/27/18.
//  Copyright © 2018 Drew Ingebretsen. All rights reserved.
//

import UIKit

class SceneSelectViewController: UIViewController {
    
    weak var raytracerView: RaytracerView!
    
    @IBAction func loadScene(_ sender: UISegmentedControl) {
        PresetScenes.selectPresetScene(sceneIndex: sender.selectedSegmentIndex)
        raytracerView.reset()
    }
}
