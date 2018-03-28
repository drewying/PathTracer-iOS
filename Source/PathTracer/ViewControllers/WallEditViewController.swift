//
//  WallEditViewController.swift
//  MetalTracer
//
//  Created by Ingebretsen, Andrew (HBO) on 3/27/18.
//  Copyright © 2018 Drew Ingebretsen. All rights reserved.
//

import UIKit

class WallEditViewController: UIViewController {

    @IBOutlet weak var wallSelectionSegmentedControl: UISegmentedControl!
    @IBOutlet weak var wallColorRedSlider: UISlider!
    @IBOutlet weak var wallColorGreenSlider: UISlider!
    @IBOutlet weak var wallColorBlueSlider: UISlider!
    
    weak var raytracerView: RaytracerView!
    
    @IBAction func sceneWallColorSlider(_ sender: UISlider) {
        let selectedWallIndex = wallSelectionSegmentedControl.selectedSegmentIndex
        let selecteedColor = Vector3D(x: wallColorRedSlider.value, y: wallColorGreenSlider.value, z: wallColorBlueSlider.value)
        raytracerView.scene.wallColors[selectedWallIndex] = selecteedColor
        raytracerView.clearSamples()
    }
    
    @IBAction func selectWall(_ sender: AnyObject) {
        update()
    }
    
    func update(){
        let selectedWallIndex = wallSelectionSegmentedControl.selectedSegmentIndex
        wallColorRedSlider.value = raytracerView.scene.wallColors[selectedWallIndex].x
        wallColorGreenSlider.value = raytracerView.scene.wallColors[selectedWallIndex].y
        wallColorBlueSlider.value = raytracerView.scene.wallColors[selectedWallIndex].z
    }
    
}
