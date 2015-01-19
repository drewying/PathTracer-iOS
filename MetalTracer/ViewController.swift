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
    
    var context:MetalContext = MetalContext(device: MTLCreateSystemDefaultDevice());
    var inputTexture: MTLTexture! = nil;
    var outputTexture: MTLTexture! = nil;
    var imageTexture: MTLTexture! = nil;

    
    var timer: CADisplayLink! = nil
    var start = NSDate();
    var sampleNumber = 1;
    var xResolution:Int = 0;
    var yResolution:Int = 0;
    var boxes:[Box] = [];
    
    var selectedSphere:Int = -1 {
        didSet {
            if (selectedSphere > -1){
                showSphereEditView();
            } else{
                hideSphereEditView();
            }
        }
    }
    
    var cameraToggle:Bool = false;
    
    var scene: Scene! = nil;
    
    override func viewDidAppear(animated: Bool) {
        let size:CGSize = self.imageView.frame.size;
        xResolution = Int(size.width);
        yResolution = Int(size.height);
        
        let light = Sphere(position:Vector3D(x:0.5,y:0.5,z:0.5), radius:0.0, color:Vector3D(x: 10.0,y: 10.0,z: 10.0), material:Material.LIGHT);
        
        let camera = Camera(cameraUp:Vector3D(x:0.0, y:1.0, z:0.0), cameraPosition:Vector3D(x:0.0, y:0.0, z:3.0), aspectRatio:Float(size.width/size.height));
        
        scene = Scene(camera:camera, light:light, context:self.context);
        
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        inputTexture = context.device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = context.device.newTextureWithDescriptor(textureDescriptor);
        
        scene.addSphere(Sphere(position: Vector3D(x:-0.5, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR));
        scene.addSphere(Sphere(position: Vector3D(x:0.5, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIELECTRIC));
        
        boxes.append(Box(min:Vector3D(x: -1.0, y: 1.0, z: -1.0), max:Vector3D(x: -1.0, y: -1.0, z: 1.0), normal:Vector3D(x:1.0, y:0.0, z:0.0), color:Vector3D(x: 0.75,y: 0.0,z: 0.0), material:Material.DIFFUSE));
        boxes.append(Box(min:Vector3D(x: 1.0, y: 1.0, z: -1.0), max:Vector3D(x: 1.0, y: -1.0, z: 1.0), normal:Vector3D(x:-1.0, y:0.0, z:0.0), color:Vector3D(x: 0.0,y: 0.0,z: 0.75), material:Material.DIFFUSE));
        boxes.append(Box(min:Vector3D(x: 1.0, y: 1.0, z: -1.0), max:Vector3D(x: -1.0, y: -1.0, z: -1.0), normal:Vector3D(x:0.0, y:0.0, z:1.0), color:Vector3D(x: 0.75,y: 0.75,z: 0.75), material:Material.DIFFUSE));
        boxes.append(Box(min:Vector3D(x: 1.0, y: 1.0, z: 1.0), max:Vector3D(x: -1.0, y: -1.0, z: 1.0), normal:Vector3D(x:0.0, y:0.0, z:-1.0), color:Vector3D(x: 0.75,y: 0.75,z: 0.75), material:Material.DIFFUSE));
        boxes.append(Box(min:Vector3D(x: 1.0, y: 1.0, z: 1.0), max:Vector3D(x: -1.0, y: 1.0, z: -1.0), normal:Vector3D(x:0.0, y:-1.0, z:0.0), color:Vector3D(x: 0.75,y: 0.75,z: 0.75), material:Material.DIFFUSE));
        boxes.append(Box(min:Vector3D(x: 1.0, y: -1.0, z: 1.0), max:Vector3D(x: -1.0, y: -1.0, z: -1.0), normal:Vector3D(x:0.0, y:1.0, z:0.0), color:Vector3D(x: 0.75,y: 0.75,z: 0.75), material:Material.DIFFUSE));
        
        scene.wallColors.append(Vector3D(x: 0.75, y: 0.0, z: 0.0));
        scene.wallColors.append(Vector3D(x: 0.0, y: 0.0, z: 0.75));
        scene.wallColors.append(Vector3D(x: 0.75, y: 0.75, z: 0.75));
        scene.wallColors.append(Vector3D(x: 0.75, y: 0.75, z: 0.75));
        scene.wallColors.append(Vector3D(x: 0.75, y: 0.75, z: 0.75));
        scene.wallColors.append(Vector3D(x: 0.75, y: 0.75, z: 0.75));
        
        
        let bytesPerPixel = UInt(4)
        let bitsPerComponent = UInt(8)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let image = UIImage(named: "texture.jpg")
        let imageRef = image?.CGImage
        let imageWidth = CGImageGetWidth(imageRef)
        let imageHeight = CGImageGetHeight(imageRef)
        let bytesPerRow = bytesPerPixel * imageWidth
        
        var rawData = [UInt8](count: Int(imageWidth * imageHeight * 4), repeatedValue: 0)
        
        let bitmapInfo = CGBitmapInfo(CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        let graphicsContext = CGBitmapContextCreate(&rawData, imageWidth, imageHeight, bitsPerComponent, bytesPerRow, rgbColorSpace, bitmapInfo)
        
        CGContextDrawImage(graphicsContext, CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight)), imageRef)
        
        let imageTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(imageWidth), height: Int(imageHeight), mipmapped: true)
        
        imageTexture = context.device.newTextureWithDescriptor(imageTextureDescriptor)
        let region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
        imageTexture.replaceRegion(region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: Int(bytesPerRow))
        
        timer = CADisplayLink(target: self, selector: Selector("renderLoop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        resetDisplay();
    }
    
    @IBAction func pinchAction(sender: UIPinchGestureRecognizer) {
        self.scene.camera.cameraPosition = Matrix.transformPoint(Matrix.translate( self.scene.camera.cameraPosition * (Float(sender.velocity) * -0.1)), right: self.scene.camera.cameraPosition);
        sender.scale = 1.0;
        self.resetDisplay();
    }
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        
        var point = sender.locationInView(self.imageView);
        let dx:Float = 1.0 / Float(xResolution);
        let dy:Float = 1.0 / Float(yResolution);
        let x:Float = -0.5 + Float(CGFloat(xResolution)-point.x)  * dx;
        let y:Float = -0.5 + Float(point.y)  * dy;
        var ray:Ray = scene.camera.getRay(x, y: y);
        selectedSphere = scene.getClosestHit(ray);
        lightEditView.hidden = true;
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
            
            //if (abs(xDelta) < abs(yDelta)){
                let yMatrix:Matrix = Matrix.rotate(self.scene.camera.cameraRight, angle:-yVelocity)
                self.scene.camera.cameraUp = Matrix.transformVector(yMatrix, right: self.scene.camera.cameraUp);
                self.scene.camera.cameraPosition = Matrix.transformPoint(yMatrix, right: self.scene.camera.cameraPosition)
                
            //} else{
                let xMatrix:Matrix = Matrix.rotateY(xVelocity);
                self.scene.camera.cameraUp = Matrix.transformVector(xMatrix, right: self.scene.camera.cameraUp);
                self.scene.camera.cameraPosition = Matrix.transformPoint(xMatrix, right: self.scene.camera.cameraPosition)
                
            //}
            
        }
        
        lastX = x;
        lastY = y;
        self.resetDisplay();
        
    }
    
    @IBAction func lightPositionSlider(sender: UISlider) {
        switch(sender){
        case lightXSlider:scene.light.position.x = sender.value;
        case lightYSlider:scene.light.position.y = sender.value;
        case lightZSlider:scene.light.position.z = sender.value;
        default:scene.light.position.x = sender.value;
        }
        self.resetDisplay();
    }
    
    
    @IBAction func lightModeSegmentedControl(sender: UISegmentedControl) {
        self.resetDisplay();
    }
    
    @IBAction func lightSizeSlider(sender: UISlider) {
        scene.light.radius = sender.value;
        resetDisplay();
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
        self.lightXSlider.value = scene.light.position.x;
        self.lightYSlider.value = scene.light.position.y;
        self.lightZSlider.value = scene.light.position.z;
        self.lightSizeSlider.value = scene.light.radius;
        self.lightEditView.hidden = !lightEditView.hidden;
        
    }
    
    @IBAction func addSphere(){
        let yPosition:Float = 0.4 * Float(scene.spheres.count-2);
        scene.addSphere(Sphere(position: Vector3D(x:0.0, y:yPosition, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: Material.DIFFUSE))
        resetDisplay();
    }
    
    @IBAction func deleteSphere(sender: AnyObject) {
        scene.deleteSphere(selectedSphere);
        selectedSphere = -1;
        resetDisplay();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    
    
    
    func render() {
        context.commandQueue.insertDebugCaptureBoundary();
        let threadgroupCounts = MTLSizeMake(16,16, 1);
        let threadgroups = MTLSizeMake(xResolution / threadgroupCounts.width, yResolution / threadgroupCounts.height, 1);
        let commandBuffer = context.commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        
        commandEncoder.setComputePipelineState(context.pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        

        let intParams = [UInt32(sampleNumber), UInt32(NSDate().timeIntervalSince1970), UInt32(xResolution), UInt32(yResolution), UInt32(self.lightModeSegmentedControl.selectedSegmentIndex + 1), 2];
        
        let a = context.device.newBufferWithBytes(intParams, length: sizeof(UInt32) * intParams.count, options:nil);
        
        
        
        commandEncoder.setBuffer(a, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(scene.cameraBuffer, offset: 0, atIndex: 1);
        commandEncoder.setBuffer(scene.sphereBuffer, offset: 0, atIndex: 2);
        commandEncoder.setBuffer(scene.wallColorBuffer, offset: 0, atIndex: 3);
    
    
        
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding();
        commandBuffer.commit();
        //commandBuffer.waitUntilScheduled();
        commandBuffer.waitUntilCompleted();
        //self.inputTexture.replaceRegion(MTLRegionMake2D(0, 0, self.xResolution, self.yResolution), mipmapLevel: 0, withBytes: &self.outputTexture, bytesPerRow: 4*self.xResolution);
        self.inputTexture = self.outputTexture;
    }
    
    func renderLoop() {
        autoreleasepool {
            self.render();
            self.sampleNumber++;
            self.sampleLabel.text = NSString(format: "Pass:%i", self.sampleNumber);
            self.imageView.image = UIImage(MTLTexture: self.inputTexture)
        }
    }
    
    func resetDisplay() {
        self.sampleNumber = 1;
        self.start = NSDate();
        scene.resetBuffer();
        //self.renderLoop();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var lastX:Float = 0.0;
    var lastY:Float = 0.0;
    
        
    func hideSphereEditView(){
        self.sphereEditView.hidden = true;
    }
        
    func showSphereEditView(){
        lastX = scene.spheres[selectedSphere].position ⋅ scene.camera.cameraRight;
        lastY = scene.spheres[selectedSphere].position ⋅ scene.camera.cameraUp;
        
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
        self.sphereEditView.hidden = false;
    }
}

