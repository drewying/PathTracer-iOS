//
//  LightEditViewController.swift
//  MetalTracer
//
//  Created by Ingebretsen, Andrew (HBO) on 3/27/18.
//  Copyright © 2018 Drew Ingebretsen. All rights reserved.
//

import UIKit

class LightEditViewController: UIViewController {
    
    @IBOutlet weak var lightIntensitySlider: UISlider!
    @IBOutlet weak var lightXSlider: UISlider!
    @IBOutlet weak var lightYSlider: UISlider!
    @IBOutlet weak var lightZSlider: UISlider!
    
    weak var raytracerView: RaytracerView!
        
    @IBAction func lightPositionSlider(_ sender: UISlider) {
        switch(sender){
        case lightIntensitySlider: raytracerView.scene.light.color = Vector3D(x: sender.value, y: sender.value, z: sender.value)
        case lightXSlider:raytracerView.scene.light.position.x = sender.value
        case lightYSlider:raytracerView.scene.light.position.y = sender.value
        case lightZSlider:raytracerView.scene.light.position.z = sender.value
        default: break
        }
        raytracerView.clearSamples()
    }
    
    func update() {
        lightIntensitySlider.value = raytracerView.scene.light.color.x
        lightXSlider.value = raytracerView.scene.light.position.x
        lightYSlider.value = raytracerView.scene.light.position.y
        lightZSlider.value = raytracerView.scene.light.position.z
    }
    
}
