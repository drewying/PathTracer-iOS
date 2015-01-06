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

class ViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var sampleLabel: UILabel!
    
    
    @IBOutlet weak var sphereRedSlider: UISlider!
    @IBOutlet weak var sphereGreenSlider: UISlider!
    @IBOutlet weak var sphereBlueSlider: UISlider!
    @IBOutlet weak var sphereMaterialSegmentedControl: UISegmentedControl!
    @IBOutlet weak var sphereSizeSlider: UISlider!
    
    @IBOutlet weak var sphereEditView: UIView!
    
    @IBOutlet weak var lightEditView: UIView!
 
    @IBOutlet weak var lightModeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var lightSizeSlider: UISlider!
    @IBOutlet weak var lightXSlider: UISlider!
    @IBOutlet weak var lightYSlider: UISlider!
    @IBOutlet weak var lightZSlider: UISlider!
    
    var device: MTLDevice! = nil;
    var defaultLibrary: MTLLibrary! = nil;
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLComputePipelineState! = nil
    var inputTexture: MTLTexture! = nil;
    var outputTexture: MTLTexture! = nil;
    var timer: CADisplayLink! = nil
    var start = NSDate();
    var sampleNumber = 1;
    var xResolution:Int = 0;
    var yResolution:Int = 0;
    
    var selectedSphere:Int = -1;
    var cameraToggle:Bool = false;
    
    var scene: Scene! = nil;
    var light:Sphere = Sphere(position:Vector3D(x:0.5,y:0.5,z:0.5), radius:0.0, color:Vector3D(x: 10.0,y: 10.0,z: 10.0), material:Material.LIGHT);

    
    
    
    @IBAction func lightPositionSlider(sender: UISlider) {
        switch(sender){
        case lightXSlider:light.position.x = sender.value;
        case lightYSlider:light.position.y = sender.value;
        case lightZSlider:light.position.z = sender.value;
        default:light.position.x = sender.value;
        }
        self.resetDisplay();
    }
    
    
    @IBAction func lightModeSegmentedControl(sender: UISegmentedControl) {
        self.resetDisplay();
    }
    
    @IBAction func lightSizeSlider(sender: UISlider) {
        self.light.radius = sender.value;
        self.resetDisplay();
    }
    
    @IBAction func radiusSlider(sender: UISlider) {
        self.scene.spheres[selectedSphere].radius = sender.value;
        self.resetDisplay();
    }
    
    @IBAction func colorSlider(sender: UISlider) {
        switch (sender){
        case sphereRedSlider:scene.spheres[selectedSphere].color.x = sender.value;
        case sphereGreenSlider:scene.spheres[selectedSphere].color.y = sender.value;
        case sphereBlueSlider:scene.spheres[selectedSphere].color.z = sender.value;
        default:scene.spheres[selectedSphere].color.x = sender.value;
        }
        self.resetDisplay();
    }
    
    @IBAction func sphereMaterialSegmentedControl(sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex){
        case 0:self.scene.spheres[selectedSphere].material = Material.DIFFUSE;
        case 1:self.scene.spheres[selectedSphere].material = Material.SPECULAR;
        case 2:self.scene.spheres[selectedSphere].material = Material.DIELECTRIC;
        default:self.scene.spheres[selectedSphere].material = Material.DIFFUSE;
        }
        self.resetDisplay();
    }
    
    @IBAction func editLighting(){
        self.lightXSlider.value = self.light.position.x;
        self.lightYSlider.value = self.light.position.y;
        self.lightZSlider.value = self.light.position.z;
        self.lightSizeSlider.value = self.light.radius;
        self.lightEditView.hidden = !self.lightEditView.hidden;
        
    }
    
    @IBAction func addSphere(){
        let yPosition:Float = 0.4 * Float(scene.spheres.count-2);
        scene.addSphere(Sphere(position: Vector3D(x:0.0, y:yPosition, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: Material.DIFFUSE))
        self.resetDisplay();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        let size:CGSize = self.imageView.frame.size;
        xResolution = Int(size.width);
        yResolution = Int(size.height);
        scene = Scene(camera: Camera(cameraUp:Vector3D(x:0.0, y:1.0, z:0.0), cameraPosition:Vector3D(x:0.0, y:0.0, z:3.0), aspectRatio:Float(size.width/size.height)));
        device = MTLCreateSystemDefaultDevice()
        defaultLibrary = device.newDefaultLibrary()
        commandQueue = device.newCommandQueue();
        let kernalProgram = defaultLibrary!.newFunctionWithName("pathtrace");
        pipelineState = self.device.newComputePipelineStateWithFunction(kernalProgram!, error: nil);
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        
        inputTexture = device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = device.newTextureWithDescriptor(textureDescriptor);
        
        scene.addSphere(Sphere(position: Vector3D(x:-0.5, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR));
        scene.addSphere(Sphere(position: Vector3D(x:0.5, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIELECTRIC));
    
        //scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.4, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: Material.DIFFUSE));
        //scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.8, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: Material.DIFFUSE));
        
        timer = CADisplayLink(target: self, selector: Selector("renderLoop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)

    }
    
    func render() {
        let threadgroupCounts = MTLSizeMake(16, 16, 1);
        let threadgroups = MTLSizeMake(xResolution / threadgroupCounts.width, yResolution / threadgroupCounts.height, 1);
        let commandBuffer = commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        commandEncoder.setComputePipelineState(pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        
        let cameraParams = self.scene.camera.getParameterArray();
        let intParams = [UInt32(sampleNumber), UInt32(NSDate().timeIntervalSince1970), UInt32(xResolution), UInt32(yResolution), UInt32(self.lightModeSegmentedControl.selectedSegmentIndex + 1)];
        
        let a = self.device.newBufferWithBytes(intParams, length: sizeof(UInt32) * intParams.count, options:nil);
        let b = self.device.newBufferWithBytes(cameraParams, length: sizeofValue(cameraParams[0])*cameraParams.count, options:nil);
        let c = self.device.newBufferWithBytes(&scene.spheres, length: (sizeof(Sphere) + 3) * 15, options:nil);
        let d = self.device.newBufferWithBytes(&light, length: (sizeof(Sphere) + 3), options:nil);
        
        
        commandEncoder.setBuffer(a, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(b, offset: 0, atIndex: 1);
        commandEncoder.setBuffer(c, offset: 0, atIndex: 2);
        commandEncoder.setBuffer(d, offset: 0, atIndex: 3);
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding();
        commandBuffer.commit();
        commandQueue.insertDebugCaptureBoundary();
        commandBuffer.waitUntilCompleted();
        self.inputTexture = self.outputTexture;
    }
    
    func renderLoop() {
        autoreleasepool {
            self.render();
            self.sampleNumber++;
            self.sampleLabel.text = NSString(format: "%i", self.sampleNumber);
            self.imageView.image = UIImage(MTLTexture: self.inputTexture)
        }
    }
    
    func resetDisplay() {
        self.sampleNumber = 1;
        self.start = NSDate();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var lastX:Float = 0.0;
    var lastY:Float = 0.0;
    
    
    var currentSelectionMaterial = Material.DIFFUSE;
    
    
    func selectSphere(sphereIndex:Int){
        self.lightEditView.hidden = true;
        if (selectedSphere > -1){
            if (scene.spheres[selectedSphere].material == Material.TRANSPARENT){
                scene.spheres[selectedSphere].material = currentSelectionMaterial;
            }
        }
        selectedSphere = sphereIndex;
        if (selectedSphere > -1){
            lastX = scene.spheres[selectedSphere].position ⋅ scene.camera.cameraRight;
            lastY = scene.spheres[selectedSphere].position ⋅ scene.camera.cameraUp;
            currentSelectionMaterial = scene.spheres[selectedSphere].material;
            
            
            
            //Configure editView
            var s:Sphere = scene.spheres[selectedSphere];
            sphereRedSlider.value = s.color.x;
            sphereGreenSlider.value = s.color.y;
            sphereBlueSlider.value = s.color.z;
            sphereSizeSlider.value = s.radius;
            switch (s.material){
            case Material.DIFFUSE:self.sphereMaterialSegmentedControl.selectedSegmentIndex = 0;
            case Material.SPECULAR:self.sphereMaterialSegmentedControl.selectedSegmentIndex = 1;
            case Material.DIELECTRIC:self.sphereMaterialSegmentedControl.selectedSegmentIndex = 2;
            default:self.sphereMaterialSegmentedControl.selectedSegmentIndex = 0;
            }
            
            scene.spheres[selectedSphere].material = Material.TRANSPARENT;
            
            self.sphereEditView.hidden = false;
            
        } else {
            self.sphereEditView.hidden = true;
        }
        
        self.resetDisplay();
    }
    
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        
        var point = sender.locationInView(self.imageView);
        let dx:Float = 1.0 / Float(xResolution);
        let dy:Float = 1.0 / Float(yResolution);
        let x:Float = Float(CGFloat(xResolution)-point.x)  * dx;
        let y:Float = Float(CGFloat(yResolution)-point.y)  * dy;
        var ray:Ray = scene.camera.getRay(x, y: y);
        
        selectSphere(scene.getClosestHit(ray));
        
    }
    
    
    
    @IBAction func dragAction(sender: UIPanGestureRecognizer) {
        
        var point = sender.locationInView(self.imageView);
        var x = Float((((CGFloat(xResolution)-point.x)/CGFloat(xResolution)) * 2.0) - 1.0);
        var y = Float((((CGFloat(yResolution)-point.y)/CGFloat(yResolution)) * 2.0) - 1.0);
        var xDelta:Float = x - lastX;
        var yDelta:Float = y - lastY;
        
        if (selectedSphere > -1){
            var currentPosition:Vector3D = scene.spheres[selectedSphere].position;
            var matrix:Matrix = Matrix.translate(scene.camera.cameraRight * xDelta) * Matrix.translate(scene.camera.cameraUp * yDelta);
            scene.spheres[selectedSphere].position = Matrix.transformPoint(matrix, right: currentPosition);
        } else{
            var velocity = sender.velocityInView(self.imageView);
            self.scene.camera.cameraPosition = self.scene.camera.cameraPosition * Matrix.rotateY(Float(velocity.x/(6.0*500)));
        }
        
        lastX = x;
        lastY = y;
        self.resetDisplay();
        
    }
    
}

