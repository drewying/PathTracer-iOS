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
    var imageTexture: MTLTexture! = nil;
    
    var timer: CADisplayLink! = nil
    var start = NSDate();
    var sampleNumber = 1;
    var xResolution:Int = 0;
    var yResolution:Int = 0;
    
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
    var light:Sphere = Sphere(position:Vector3D(x:0.5,y:0.5,z:0.5), radius:0.0, color:Vector3D(x: 10.0,y: 10.0,z: 10.0), material:Material.LIGHT);

    
    
    @IBAction func pinchAction(sender: UIPinchGestureRecognizer) {
        self.scene.camera.cameraPosition = Matrix.transformPoint(Matrix.translate( self.scene.camera.cameraPosition * (Float(sender.velocity) * -0.1)), right: self.scene.camera.cameraPosition);
        sender.scale = 1.0;
        self.resetDisplay();
    }
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        
        var point = sender.locationInView(self.imageView);
        let dx:Float = 1.0 / Float(xResolution);
        let dy:Float = 1.0 / Float(yResolution);
        let x:Float = Float(CGFloat(xResolution)-point.x)  * dx;
        let y:Float = Float(CGFloat(yResolution)-point.y)  * dy;
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
            
            /*if (abs(xDelta) < abs(yDelta)){
                let yMatrix:Matrix = Matrix.rotate(self.scene.camera.cameraUp, angle: yDelta);
                self.scene.camera.cameraPosition = self.scene.camera.cameraPosition * yMatrix;
                self.scene.camera.cameraUp = self.scene.camera.cameraUp * yMatrix;
            } else{*/
                let xMatrix:Matrix = Matrix.rotateY(xVelocity);
                self.scene.camera.cameraPosition = self.scene.camera.cameraPosition * xMatrix;
            //}
            
        }
        
        lastX = x;
        lastY = y;
        self.resetDisplay();
        
    }
    
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
    
    @IBAction func deleteSphere(sender: AnyObject) {
        self.scene.spheres.removeAtIndex(self.selectedSphere);
        self.selectedSphere = -1;
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
        let kernalProgram = defaultLibrary!.newFunctionWithName("mainProgram");
        pipelineState = self.device.newComputePipelineStateWithFunction(kernalProgram!, error: nil);
  
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        inputTexture = device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = device.newTextureWithDescriptor(textureDescriptor);
        
        scene.addSphere(Sphere(position: Vector3D(x:-0.5, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.SPECULAR));
        scene.addSphere(Sphere(position: Vector3D(x:0.5, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.DIELECTRIC));
   
        
        
        
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
        
        let context = CGBitmapContextCreate(&rawData, imageWidth, imageHeight, bitsPerComponent, bytesPerRow, rgbColorSpace, bitmapInfo)
        
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight)), imageRef)
        
        let imageTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(imageWidth), height: Int(imageHeight), mipmapped: true)
        
        imageTexture = device.newTextureWithDescriptor(imageTextureDescriptor)
        let region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
        imageTexture.replaceRegion(region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: Int(bytesPerRow))

        timer = CADisplayLink(target: self, selector: Selector("renderLoop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func render() {
        commandQueue.insertDebugCaptureBoundary();
        let threadgroupCounts = MTLSizeMake(16,16, 1);
        let threadgroups = MTLSizeMake(xResolution / threadgroupCounts.width, yResolution / threadgroupCounts.height, 1);
        let commandBuffer = commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        
        commandEncoder.setComputePipelineState(pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        //commandEncoder.setTexture(imageTexture, atIndex:2);
        
        let cameraParams = self.scene.camera.getParameterArray();
        let intParams = [UInt32(sampleNumber), UInt32(NSDate().timeIntervalSince1970), UInt32(xResolution), UInt32(yResolution), UInt32(self.lightModeSegmentedControl.selectedSegmentIndex + 1), 2];
        
        let a = self.device.newBufferWithBytes(intParams, length: sizeof(UInt32) * intParams.count, options:nil);
        let b = self.device.newBufferWithBytes(cameraParams, length: sizeofValue(cameraParams[0])*cameraParams.count, options:nil);
        
        
        var s:[Sphere] = [];
        s.append(light);
        for sphere:Sphere in scene.spheres{
            s.append(sphere);
        }
        
        let c = self.device.newBufferWithBytes(&s, length: (sizeof(Sphere) + 3) * (scene.spheres.count + 1), options:nil);
        
        commandEncoder.setBuffer(a, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(b, offset: 0, atIndex: 1);
        commandEncoder.setBuffer(c, offset: 0, atIndex: 2);
        //commandEncoder.setBuffer(d, offset: 0, atIndex: 3);
        
        
        
        
        
        
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

