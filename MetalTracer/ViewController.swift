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

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    
    @IBOutlet weak var imageView: UIImageView!
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
    
    var context:MetalContext! = nil
    
    var imageTexture: MTLTexture! = nil

    var rayTracer:Raytracer! = nil
    
    var timer: CADisplayLink! = nil
    
    var xResolution:Int = 0
    var yResolution:Int = 0
    
    var selectedSphere:Int = -1 {
        didSet {
            if (selectedSphere > -1){
                if (currentPane != sphereEditView){
                    currentPane?.hidden = true
                }
                currentPane = sphereEditView
                updateSphereEditView()
                sphereEditView.hidden = false
            } else if (!sphereEditView.hidden){
                sphereEditView.hidden = true
            }
            
        }
    }
    
    var cameraToggle:Bool = false;
    
    var scene: Scene! = nil;
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if ((scene == nil)){
            panes = [mainEditView, lightEditView, sceneEditView, infoEditView];
            
            let size:CGSize = self.imageView.frame.size
            xResolution = Int(size.width)
            yResolution = Int(size.height)
            
            let camera = Camera(cameraUp:Vector3D(x:0.0, y:1.0, z:0.0), cameraPosition:Vector3D(x:0.0, y:0.0, z:3.0), aspectRatio:Float(size.width/size.height))
            scene = Scene(camera:camera, context:self.context)
            
            self.imageTexture = UIImage.textureFromImage(UIImage(named: "texture.jpg")!, context: context)
            self.rayTracer = Raytracer(renderContext: context, xResolution: xResolution, yResolution: yResolution)
            rayTracer.imageTexture = imageTexture
            
            timer = CADisplayLink(target: self, selector: #selector(ViewController.renderLoop))
            timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            setupScene(0)
        }
        
    }
    
    func setupScene(sceneIndex: Int) {
        scene.clearSpheres()
        if (sceneIndex == 0){
            //Metal and Glass
            scene.addSphere(Sphere(position: Vector3D(x:-0.5, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR))
            scene.addSphere(Sphere(position: Vector3D(x:0.5, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIELECTRIC))
            scene.light = Sphere(position:Vector3D(x:0.0,y:0.8,z:0.0), radius:0.0, color:Vector3D(x: 3.0,y: 3.0,z: 3.0), material:Material.LIGHT)
            
            scene.wallColors[0] = Vector3D(x: 0.75, y: 0.0, z: 0.0)
            scene.wallColors[1] = Vector3D(x: 0.0, y: 0.0, z: 0.75)
            scene.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            scene.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            scene.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            scene.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            
            scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 1){
            //Column of Balls
            scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.75, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIFFUSE))
            scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.25, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIFFUSE))
            scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.25, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIFFUSE))
            scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.75, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIFFUSE))
            scene.light = Sphere(position:Vector3D(x:-0.3,y:0.25,z:0.95), radius:0.0, color:Vector3D(x: 1.5,y: 1.5,z: 1.5), material:Material.LIGHT)
            
            scene.wallColors[0] = Vector3D(x: 1.0, y: 1.0, z: 0.0);
            scene.wallColors[1] = Vector3D(x: 0.0, y: 0.0, z: 1.0);
            scene.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            
            scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 2){
            //Mirrored
            scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.7, z:0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR))
            scene.addSphere(Sphere(position: Vector3D(x:-0.3, y:-0.7, z:-0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR))
            scene.addSphere(Sphere(position: Vector3D(x:0.3, y:-0.7, z:-0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR))
            scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.2, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR))
            scene.light = Sphere(position:Vector3D(x:0.0,y:0.9,z:0.0), radius:0.0, color:Vector3D(x: 3.0,y: 3.0,z: 3.0), material:Material.LIGHT)
            
            scene.wallColors[0] = Vector3D(x: 0.75, y: 0.00, z: 0.00);
            scene.wallColors[1] = Vector3D(x: 0.00, y: 0.75, z: 0.00);
            scene.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            
            scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 3){
            //Primary Colors
            scene.addSphere(Sphere(position: Vector3D(x: 0.3, y:-0.7, z:-0.5),radius:0.3, color:Vector3D(x: 0.25, y: 0.25, z: 1.0), material: Material.DIFFUSE))
            scene.addSphere(Sphere(position: Vector3D(x: 0.0, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 0.25, y: 1.0, z: 0.25), material: Material.DIFFUSE))
            scene.addSphere(Sphere(position: Vector3D(x:-0.3, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 0.25, z:0.25), material: Material.DIFFUSE))
            scene.light = Sphere(position:Vector3D(x:0.0,y:0.5,z:0.0), radius:0.0, color:Vector3D(x: 2.0,y: 2.0,z: 2.0), material:Material.LIGHT)
            
            scene.wallColors[0] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene.wallColors[1] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene.wallColors[2] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene.wallColors[3] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene.wallColors[4] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene.wallColors[5] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            
            scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 4){
            //Escher
            scene.addSphere(Sphere(position: Vector3D(x: 0.0, y: -0.3, z:-0.3), radius:0.7, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR))
            scene.addSphere(Sphere(position: Vector3D(x: -0.5, y: 0.6, z:0.7), radius:0.2, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIFFUSE))
            scene.addSphere(Sphere(position: Vector3D(x: 0.4, y:-0.6, z:0.6), radius:0.2, color:Vector3D(x: 0.5, y: 0.5, z:0.5), material: Material.DIELECTRIC))
            scene.light = Sphere(position:Vector3D(x:0.0,y:0.0,z:0.95), radius:0.0, color:Vector3D(x: 1.5,y: 1.5,z: 1.5), material:Material.LIGHT)
            
            scene.wallColors[0] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene.wallColors[1] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene.wallColors[2] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene.wallColors[3] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene.wallColors[4] = Vector3D(x: 1.0, y: 1.0, z: 1.0);
            scene.wallColors[5] = Vector3D(x: 1.0, y: 1.0, z: 1.0);
            
            scene.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        }
        resetDisplay(true)
    }
    
    @IBAction func loadScene(sender: UISegmentedControl) {
        setupScene(sender.selectedSegmentIndex)
    }
    
    @IBAction func pinchAction(sender: UIPinchGestureRecognizer) {
        self.scene.camera.cameraPosition = Matrix.transformPoint(Matrix.translate( self.scene.camera.cameraPosition * (Float(sender.velocity) * -0.1)), right: self.scene.camera.cameraPosition);
        sender.scale = 1.0;
        self.resetDisplay(false);
    }
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        
        let point = sender.locationInView(self.imageView);
        let dx:Float = 1.0 / Float(xResolution);
        let dy:Float = 1.0 / Float(yResolution);
        let x:Float = -0.5 + Float(CGFloat(xResolution)-point.x)  * dx;
        let y:Float = -0.5 + Float(point.y)  * dy;
        let ray:Ray = scene.camera.getRay(x, y: y);
        selectedSphere = scene.getClosestHit(ray);
    }
    
    @IBAction func selectWall(sender: AnyObject) {
        updateWallColorsView()
    }
    
    @IBAction func doubleTapAction(sender: UITapGestureRecognizer) {
        if (scene.sphereCount >= 5){
            return;
        }
        
        let point = sender.locationInView(self.imageView)
        let x = Float((((CGFloat(xResolution)-point.x)/CGFloat(xResolution)) * 2.0) - 1.0)
        let y = Float((((CGFloat(yResolution)-point.y)/CGFloat(yResolution)) * 2.0) - 1.0)
        
        /*let cosy = scene.camera.cameraUp ⋅ Vector3D.up()
        let cosx = scene.camera.cameraRight ⋅ Vector3D.right()
        let position:Vector3D = Matrix.transformPoint(matrix, right: Vector3D(x: x, y: y, z: 0));*/
        
        let angleX = acos(scene.camera.cameraRight ⋅ Vector3D.right()) / (scene.camera.cameraRight.length() * Vector3D.right().length())
        let angleY = acos(scene.camera.cameraUp ⋅ Vector3D.up()) / (scene.camera.cameraUp.length() * Vector3D.up().length())
        
        let matrix = Matrix.rotateY(angleX) * Matrix.rotateX(angleY)
        let position:Vector3D = Matrix.transformPoint(matrix, right: Vector3D(x: x, y: y, z: 0))
        scene.addSphere(Sphere(position: position, radius:0.25, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: Material.DIFFUSE))
        resetDisplay(true)
    }
   
    @IBAction func dragAction(sender: UIPanGestureRecognizer) {
        
        let point = sender.locationInView(self.imageView);
        let x = Float((((CGFloat(xResolution)-point.x)/CGFloat(xResolution)) * 2.0) - 1.0);
        let y = Float((((CGFloat(yResolution)-point.y)/CGFloat(yResolution)) * 2.0) - 1.0);
        let xDelta:Float = x - lastX;
        let yDelta:Float = y - lastY;
        
        if (selectedSphere > -1){
            let currentPosition:Vector3D = scene.spheres[selectedSphere].position;
            let matrix:Matrix = Matrix.translate(scene.camera.cameraRight * xDelta) * Matrix.translate(scene.camera.cameraUp * yDelta);
            scene.spheres[selectedSphere].position = Matrix.transformPoint(matrix, right: currentPosition);
        } else{
            let velocity = sender.velocityInView(self.imageView);
            let xVelocity = Float(velocity.x/(CGFloat(M_PI) * CGFloat(xResolution)));
            let yVelocity = Float(velocity.y/(CGFloat(M_PI) * CGFloat(yResolution)));
            
            /*let matrix:Matrix = Matrix.rotateY(xVelocity) * Matrix.rotate(self.scene.camera.cameraRight, angle:-yVelocity)
            self.scene.camera.cameraUp = Matrix.transformVector(matrix, right: self.scene.camera.cameraUp);
            self.scene.camera.cameraPosition = Matrix.transformPoint(matrix, right: self.scene.camera.cameraPosition)*/
            
            let yMatrix:Matrix = Matrix.rotate(self.scene.camera.cameraRight, angle:-yVelocity)
            self.scene.camera.cameraUp = Matrix.transformVector(yMatrix, right: self.scene.camera.cameraUp);
            self.scene.camera.cameraPosition = Matrix.transformPoint(yMatrix, right: self.scene.camera.cameraPosition)
            
            let xMatrix:Matrix = Matrix.rotateY(xVelocity);
            self.scene.camera.cameraUp = Matrix.transformVector(xMatrix, right: self.scene.camera.cameraUp);
            self.scene.camera.cameraPosition = Matrix.transformPoint(xMatrix, right: self.scene.camera.cameraPosition)

            
        }
        
        lastX = x;
        lastY = y;
        self.resetDisplay(false);
    }
    
    @IBAction func lightPositionSlider(sender: UISlider) {
        switch(sender){
        case lightIntensitySlider: scene.light.color = Vector3D(x: sender.value, y: sender.value, z: sender.value)
        case lightXSlider:scene.light.position.x = sender.value;
        case lightYSlider:scene.light.position.y = sender.value;
        case lightZSlider:scene.light.position.z = sender.value;
        default:scene.light.position.x = sender.value;
        }
        self.resetDisplay(false);
    }
    
    @IBAction func radiusSlider(sender: UISlider) {
        self.scene.spheres[selectedSphere].radius = sender.value;
        self.resetDisplay(false);
    }
    
    @IBAction func sphereColorSlider(sender: UISlider) {
        switch (sender){
        case sphereRedSlider:scene.spheres[selectedSphere].color.x = sender.value
        case sphereGreenSlider:scene.spheres[selectedSphere].color.y = sender.value
        case sphereBlueSlider:scene.spheres[selectedSphere].color.z = sender.value
        default:scene.spheres[selectedSphere].color.x = sender.value
        }
        currentColorView.backgroundColor = UIColor(red: CGFloat(sphereRedSlider.value), green: CGFloat(sphereGreenSlider.value), blue: CGFloat(sphereBlueSlider.value), alpha: 1.0)
        self.resetDisplay(false)
    }
    
    @IBAction func sceneWallColorSlider(sender: UISlider) {
        scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex] = Vector3D(x: sceneRedSlider.value, y: sceneGreenSlider.value, z: sceneBlueSlider.value)
        self.resetDisplay(false)
    }
    
    @IBAction func sphereMaterialSegmentedControl(sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex){
        case 0:self.scene.spheres[selectedSphere].material = Material.DIFFUSE.rawValue;
        case 1:self.scene.spheres[selectedSphere].material = Material.SPECULAR.rawValue;
        case 2:self.scene.spheres[selectedSphere].material = Material.DIELECTRIC.rawValue;
        default:self.scene.spheres[selectedSphere].material = Material.DIFFUSE.rawValue;
        }
        self.resetDisplay(true);
    }
    
    @IBAction func selectPane(sender: UIBarButtonItem) {
        selectedSphere = -1
        
        currentPane?.hidden = true
        if (currentPane != panes[sender.tag]){
            currentPane = panes[sender.tag]
            currentPane?.hidden = false
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
    
    @IBAction func deleteSphere(sender: AnyObject) {
        scene.deleteSphere(selectedSphere);
        selectedSphere = -1;
        resetDisplay(true);
    }
    
    @IBAction func saveImage(sender: AnyObject) {
        let image:UIImage = imageView.image!;
        UIGraphicsBeginImageContext(image.size);
        CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(0.0,0.0, image.size.width, image.size.height),image.CGImage);
        let flippedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        let sharingItems:[AnyObject] = [flippedImage]
    
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender as! UIView
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func showInformation(sender: AnyObject) {
    }

    @IBAction func showFeedback(sender: AnyObject) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["drew@thinkpeopletech.com"])
        composeVC.setSubject("Real Time Path Tracer Feedback v1.0")
        
        self.presentViewController(composeVC, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var device = MTLCreateSystemDefaultDevice()
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            imageView = UIImageView(frame: self.view.frame)
            return
        }
        context = MetalContext(device: device!)
    }
    
    var que:dispatch_queue_t = dispatch_queue_create("Rendering", DISPATCH_QUEUE_SERIAL);

    func renderLoop() {
        autoreleasepool {
            dispatch_async(self.que, {
                let image:UIImage = self.rayTracer.renderScene(self.scene);
                dispatch_async(dispatch_get_main_queue(), {
                    self.imageView.image = image
                    self.renderingProgressView.setProgress(Float(self.rayTracer.sampleNumber)/2000.0, animated: true)
                    //self.sampleLabel.text = "Pass:\(self.rayTracer.sampleNumber)"
                });
            });
            
            
        }
    }
    
    func resetDisplay(activeReset:Bool) {
        self.rayTracer.sampleNumber = 1
        scene.resetBuffer()
        self.renderingProgressView.progress = 0.0
        if (activeReset){
            self.rayTracer.reset()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var lastX:Float = 0.0
    var lastY:Float = 0.0
    
    func updateWallColorsView(){
        sceneRedSlider.value = scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex].x
        sceneGreenSlider.value = scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex].y
        sceneBlueSlider.value = scene.wallColors[sceneWallSegmentedControl.selectedSegmentIndex].z
    }
    
    func updateLightingEditView(){
        self.lightIntensitySlider.value = scene.light.color.x
        self.lightXSlider.value = scene.light.position.x
        self.lightYSlider.value = scene.light.position.y
        self.lightZSlider.value = scene.light.position.z
    }
    
    func updateSphereEditView(){
        lastX = scene.spheres[selectedSphere].position ⋅ scene.camera.cameraRight
        lastY = scene.spheres[selectedSphere].position ⋅ scene.camera.cameraUp
        
        //Configure editView
        let s:Sphere = scene.spheres[selectedSphere];
        sphereRedSlider.value = s.color.x
        sphereGreenSlider.value = s.color.y
        sphereBlueSlider.value = s.color.z
        currentColorView.backgroundColor = UIColor(red: CGFloat(s.color.x), green: CGFloat(s.color.y), blue: CGFloat(s.color.z), alpha: 1.0)
        sphereSizeSlider.value = s.radius
        sphereMaterialSegmentedControl.selectedSegmentIndex = Int(s.material)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

