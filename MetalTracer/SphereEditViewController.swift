//
//  SphereEditViewController.swift
//  MetalTracer
//
//  Created by Ingebretsen, Andrew (HBO) on 3/27/18.
//  Copyright © 2018 Drew Ingebretsen. All rights reserved.
//

import UIKit

class SphereEditViewController: UIViewController {
    
    @IBOutlet weak var sphereRedSlider: UISlider!
    @IBOutlet weak var sphereGreenSlider: UISlider!
    @IBOutlet weak var sphereBlueSlider: UISlider!
    @IBOutlet weak var sphereSizeSlider: UISlider!
    @IBOutlet weak var sphereMaterialSegmentedControl: UISegmentedControl!
    
    weak var raytracerView: RaytracerView!
    
    var selectedSphere:Int = -1
    
    @IBAction func radiusSlider(_ sender: UISlider) {
        self.raytracerView.scene.spheres[selectedSphere].radius = sender.value
        raytracerView.clearSamples()
    }
    
    @IBAction func sphereColorSlider(_ sender: UISlider) {
        switch (sender){
        case sphereRedSlider:raytracerView.scene.spheres[selectedSphere].color.x = sender.value
        case sphereGreenSlider:raytracerView.scene.spheres[selectedSphere].color.y = sender.value
        case sphereBlueSlider:raytracerView.scene.spheres[selectedSphere].color.z = sender.value
        default:raytracerView.scene.spheres[selectedSphere].color.x = sender.value
        }
        raytracerView.clearSamples()
    }
    
    @IBAction func sphereMaterialSegmentedControl(_ sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex){
        case 0:self.raytracerView.scene.spheres[selectedSphere].material = Material.diffuse.rawValue
        case 1:self.raytracerView.scene.spheres[selectedSphere].material = Material.specular.rawValue
        case 2:self.raytracerView.scene.spheres[selectedSphere].material = Material.dielectric.rawValue
        default:self.raytracerView.scene.spheres[selectedSphere].material = Material.diffuse.rawValue
        }
        raytracerView.reset()
    }

    @IBAction func deleteSphere(_ sender: AnyObject) {
        raytracerView.scene.deleteSphere(selectedSphere)
        selectedSphere = -1
        raytracerView.reset()
    }
    
    func update(){
        //Configure editView
        selectedSphere = raytracerView.selectedSphere
        let s:Sphere = raytracerView.scene.spheres[selectedSphere]
        sphereRedSlider.value = s.color.x
        sphereGreenSlider.value = s.color.y
        sphereBlueSlider.value = s.color.z
        sphereSizeSlider.value = s.radius
        sphereMaterialSegmentedControl.selectedSegmentIndex = Int(s.material)
    }
    
}
