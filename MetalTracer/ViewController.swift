//
//  ViewController.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/4/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit
import Metal
import QuartzCore
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate, RaytracerViewDelegate {
    
    @IBOutlet weak var raytracerView: RaytracerView!
    @IBOutlet weak var sampleLabel: UILabel!
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var mainEditView: UIView!
    @IBOutlet weak var sphereEditView: UIView!
    @IBOutlet weak var sceneEditView: UIView!
    @IBOutlet weak var lightEditView: UIView!
    @IBOutlet weak var infoEditView: UIView!
    @IBOutlet weak var currentColorView: UIView!
    
    @IBOutlet weak var sceneWallSegmentedControl: UISegmentedControl!
    @IBOutlet weak var sceneRedSlider: UISlider!
    @IBOutlet weak var sceneGreenSlider: UISlider!
    @IBOutlet weak var sceneBlueSlider: UISlider!
    
    @IBOutlet weak var sphereRedSlider: UISlider!
    @IBOutlet weak var sphereGreenSlider: UISlider!
    @IBOutlet weak var sphereBlueSlider: UISlider!
    @IBOutlet weak var sphereMaterialSegmentedControl: UISegmentedControl!
    @IBOutlet weak var sphereSizeSlider: UISlider!
    
    @IBOutlet weak var renderingProgressView: UIProgressView!
    
    @IBOutlet weak var lightIntensitySlider: UISlider!
    @IBOutlet weak var lightXSlider: UISlider!
    @IBOutlet weak var lightYSlider: UISlider!
    @IBOutlet weak var lightZSlider: UISlider!
    
    
    var currentPane:UIView?
    var currentButton:UIBarButtonItem?
    
    var panes:[UIView] = []
    
    var selectedSphere:Int = -1 {
        didSet {
            if (selectedSphere > -1){
                if (currentPane != sphereEditView){
                    currentPane?.isHidden = true
                }
                currentPane = sphereEditView
                updateSphereEditView()
                sphereEditView.isHidden = false
            } else if (!sphereEditView.isHidden){
                sphereEditView.isHidden = true
            }
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        panes = [mainEditView, lightEditView, sceneEditView, infoEditView]
    }
    
    func setupScene(_ sceneIndex: Int) {
        
        raytracerView.scene.clearSpheres()
        if (sceneIndex == 0){
            //Metal and Glass
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:-0.5, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.5, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.dielectric))
            raytracerView.scene.light = Sphere(position:Vector3D(x:0.0,y:0.8,z:0.0), radius:0.0, color:Vector3D(x: 3.0,y: 3.0,z: 3.0), material:Material.light)
            
            raytracerView.scene.wallColors[0] = Vector3D(x: 0.75, y: 0.0, z: 0.0)
            raytracerView.scene.wallColors[1] = Vector3D(x: 0.0, y: 0.0, z: 0.75)
            raytracerView.scene.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            raytracerView.scene.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            raytracerView.scene.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            raytracerView.scene.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            
            raytracerView.scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            raytracerView.scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 1){
            //Column of Balls
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.75, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.25, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.25, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.75, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            raytracerView.scene.light = Sphere(position:Vector3D(x:-0.3,y:0.25,z:0.95), radius:0.0, color:Vector3D(x: 1.5,y: 1.5,z: 1.5), material:Material.light)
            
            raytracerView.scene.wallColors[0] = Vector3D(x: 1.0, y: 1.0, z: 0.0);
            raytracerView.scene.wallColors[1] = Vector3D(x: 0.0, y: 0.0, z: 1.0);
            raytracerView.scene.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            raytracerView.scene.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            raytracerView.scene.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            raytracerView.scene.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            
            raytracerView.scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            raytracerView.scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 2){
            //Mirrored
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.7, z:0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:-0.3, y:-0.7, z:-0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.3, y:-0.7, z:-0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.2, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            raytracerView.scene.light = Sphere(position:Vector3D(x:0.0,y:0.9,z:0.0), radius:0.0, color:Vector3D(x: 3.0,y: 3.0,z: 3.0), material:Material.light)
            
            raytracerView.scene.wallColors[0] = Vector3D(x: 0.75, y: 0.00, z: 0.00);
            raytracerView.scene.wallColors[1] = Vector3D(x: 0.00, y: 0.75, z: 0.00);
            raytracerView.scene.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            raytracerView.scene.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            raytracerView.scene.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            raytracerView.scene.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            
            raytracerView.scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            raytracerView.scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 3){
            //Primary Colors
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x: 0.3, y:-0.7, z:-0.5),radius:0.3, color:Vector3D(x: 0.25, y: 0.25, z: 1.0), material: Material.diffuse))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x: 0.0, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 0.25, y: 1.0, z: 0.25), material: Material.diffuse))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x:-0.3, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 0.25, z:0.25), material: Material.diffuse))
            raytracerView.scene.light = Sphere(position:Vector3D(x:0.0,y:0.5,z:0.0), radius:0.0, color:Vector3D(x: 2.0,y: 2.0,z: 2.0), material:Material.light)
            
            raytracerView.scene.wallColors[0] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            raytracerView.scene.wallColors[1] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            raytracerView.scene.wallColors[2] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            raytracerView.scene.wallColors[3] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            raytracerView.scene.wallColors[4] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            raytracerView.scene.wallColors[5] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            
            raytracerView.scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            raytracerView.scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 4){
            //Escher
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x: 0.0, y: -0.3, z:-0.3), radius:0.7, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x: -0.5, y: 0.6, z:0.7), radius:0.2, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            raytracerView.scene.addSphere(Sphere(position: Vector3D(x: 0.4, y:-0.6, z:0.6), radius:0.2, color:Vector3D(x: 0.5, y: 0.5, z:0.5), material: Material.dielectric))
            raytracerView.scene.light = Sphere(position:Vector3D(x:0.0,y:0.0,z:0.95), radius:0.0, color:Vector3D(x: 1.5,y: 1.5,z: 1.5), material:Material.light)
            
            raytracerView.scene.wallColors[0] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            raytracerView.scene.wallColors[1] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            raytracerView.scene.wallColors[2] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            raytracerView.scene.wallColors[3] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            raytracerView.scene.wallColors[4] = Vector3D(x: 1.0, y: 1.0, z: 1.0);
            raytracerView.scene.wallColors[5] = Vector3D(x: 1.0, y: 1.0, z: 1.0);
            
            raytracerView.scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            raytracerView.scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        }
        resetDisplay(true)
    }
    
    @IBAction func loadScene(_ sender: UISegmentedControl) {
        setupScene(sender.selectedSegmentIndex)
    }
    
    @IBAction func selectWall(_ sender: AnyObject) {
        updateWallColorsView()
    }
    
    @IBAction func lightPositionSlider(_ sender: UISlider) {
        switch(sender){
        case lightIntensitySlider: raytracerView.scene.light.color = Vector3D(x: sender.value, y: sender.value, z: sender.value)
        case lightXSlider:raytracerView.scene.light.position.x = sender.value;
        case lightYSlider:raytracerView.scene.light.position.y = sender.value;
        case lightZSlider:raytracerView.scene.light.position.z = sender.value;
        default:raytracerView.scene.light.position.x = sender.value;
        }
        self.resetDisplay(false);
    }
    
    @IBAction func radiusSlider(_ sender: UISlider) {
        self.raytracerView.scene.spheres[selectedSphere].radius = sender.value;
        self.resetDisplay(false);
    }
    
    @IBAction func sphereColorSlider(_ sender: UISlider) {
        switch (sender){
        case sphereRedSlider:raytracerView.scene.spheres[selectedSphere].color.x = sender.value
        case sphereGreenSlider:raytracerView.scene.spheres[selectedSphere].color.y = sender.value
        case sphereBlueSlider:raytracerView.scene.spheres[selectedSphere].color.z = sender.value
        default:raytracerView.scene.spheres[selectedSphere].color.x = sender.value
        }
        currentColorView.backgroundColor = UIColor(red: CGFloat(sphereRedSlider.value), green: CGFloat(sphereGreenSlider.value), blue: CGFloat(sphereBlueSlider.value), alpha: 1.0)
        self.resetDisplay(false)
    }
    
    @IBAction func sceneWallColorSlider(_ sender: UISlider) {
        raytracerView.scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex] = Vector3D(x: sceneRedSlider.value, y: sceneGreenSlider.value, z: sceneBlueSlider.value)
        self.resetDisplay(false)
    }
    
    @IBAction func sphereMaterialSegmentedControl(_ sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex){
        case 0:self.raytracerView.scene.spheres[selectedSphere].material = Material.diffuse.rawValue;
        case 1:self.raytracerView.scene.spheres[selectedSphere].material = Material.specular.rawValue;
        case 2:self.raytracerView.scene.spheres[selectedSphere].material = Material.dielectric.rawValue;
        default:self.raytracerView.scene.spheres[selectedSphere].material = Material.diffuse.rawValue;
        }
        self.resetDisplay(true);
    }
    
    @IBAction func selectPane(_ sender: UIBarButtonItem) {
        selectedSphere = -1
        
        currentPane?.isHidden = true
        if (currentPane != panes[sender.tag]){
            currentPane = panes[sender.tag]
            currentPane?.isHidden = false
            currentButton = sender
        } else {
            currentPane = nil
        }
        
        switch (sender.tag){
        case 1:
            updateLightingEditView()
        case 2:
            updateWallColorsView()
        default: break
        }
    }
    
    /*func selectPane(index: Int){
     for i in 0...panes.count-1 {
     panes[i].hidden = (index != i);
     toolbarButtons[i].tintColor = (index == i) ? UIColor.darkGrayColor() : UIColor.lightGrayColor();
     }
     }*/
    
    @IBAction func deleteSphere(_ sender: AnyObject) {
        raytracerView.scene.deleteSphere(selectedSphere);
        selectedSphere = -1;
        resetDisplay(true);
    }
    
    @IBAction func saveImage(_ sender: AnyObject) {
        /*let image:UIImage = imageView.image!;
        UIGraphicsBeginImageContext(image.size);
        UIGraphicsGetCurrentContext()?.draw(image.cgImage!, in: CGRect(x: 0.0,y: 0.0, width: image.size.width, height: image.size.height));
        let flippedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        let sharingItems:[AnyObject] = [flippedImage]
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender as? UIView
        self.present(activityViewController, animated: true, completion: nil)*/
    }
    
    @IBAction func showInformation(_ sender: AnyObject) {
    }
    
    @IBAction func showFeedback(_ sender: AnyObject) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["drew@thinkpeopletech.com"])
        composeVC.setSubject("Real Time Path Tracer Feedback v1.05")
        
        self.present(composeVC, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        raytracerView.initialize()
        setupScene(0)
        raytracerView.startRendering()
    }
    

    
    func resetDisplay(_ activeReset:Bool) {
        self.raytracerView.reset()
        self.renderingProgressView.progress = 0.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var lastX:Float = 0.0
    var lastY:Float = 0.0
    
    func updateWallColorsView(){
        sceneRedSlider.value = raytracerView.scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex].x
        sceneGreenSlider.value = raytracerView.scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex].y
        sceneBlueSlider.value = raytracerView.scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex].z
    }
    
    func updateLightingEditView(){
        self.lightIntensitySlider.value = raytracerView.scene.light.color.x
        self.lightXSlider.value = raytracerView.scene.light.position.x
        self.lightYSlider.value = raytracerView.scene.light.position.y
        self.lightZSlider.value = raytracerView.scene.light.position.z
    }
    
    func updateSphereEditView(){
        lastX = raytracerView.scene.spheres[selectedSphere].position ⋅ raytracerView.scene.camera.cameraRight
        lastY = raytracerView.scene.spheres[selectedSphere].position ⋅ raytracerView.scene.camera.cameraUp
        
        //Configure editView
        let s:Sphere = raytracerView.scene.spheres[selectedSphere];
        sphereRedSlider.value = s.color.x
        sphereGreenSlider.value = s.color.y
        sphereBlueSlider.value = s.color.z
        currentColorView.backgroundColor = UIColor(red: CGFloat(s.color.x), green: CGFloat(s.color.y), blue: CGFloat(s.color.z), alpha: 1.0)
        sphereSizeSlider.value = s.radius
        sphereMaterialSegmentedControl.selectedSegmentIndex = Int(s.material)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func raytracerViewDidCreateImage(image: UIImage) {
        self.renderingProgressView.setProgress(Float(raytracerView.samples)/2000.0, animated: true)
    }
    
    func raytracerViewDidSelectSphere(index:Int) {
        selectedSphere = index;
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

