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
    
    var device: MTLDevice! = nil;
    var defaultLibrary: MTLLibrary! = nil;
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLComputePipelineState! = nil
    var inputTexture: MTLTexture! = nil;
    var outputTexture: MTLTexture! = nil;
    var timer: CADisplayLink! = nil
    var now = NSDate();
    var sampleNumber = 1;
    
    var selectedSphere:Int = -1;
    var cameraToggle:Bool = false;
    
    var scene: Scene! = Scene(camera: Camera(cameraUp:Vector3D(x:0.0, y:1.0, z:0.0), cameraPosition:Vector3D(x:0.0, y:0.0, z:3.0)));
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        defaultLibrary = device.newDefaultLibrary()
        commandQueue = device.newCommandQueue();
        let kernalProgram = defaultLibrary!.newFunctionWithName("pathtrace");
        pipelineState = self.device.newComputePipelineStateWithFunction(kernalProgram!, error: nil);
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: 500, height: 500, mipmapped: false);
        
        inputTexture = device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = device.newTextureWithDescriptor(textureDescriptor);
        
        timer = CADisplayLink(target: self, selector: Selector("gameloop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        scene.addSphere(Sphere(position: Vector3D(x:-0.5, y:-0.8, z:0.5),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0));
        scene.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.4, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0));
        scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.0, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0));
        scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.4, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0));
        scene.addSphere(Sphere(position: Vector3D(x:0.0, y:0.8, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0));
    }
    
    func render() {
        let threadgroupCounts = MTLSizeMake(16, 16, 1);
        let threadgroups = MTLSizeMake(500 / threadgroupCounts.width, 500 / threadgroupCounts.height, 1);
        let commandBuffer = commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        commandEncoder.setComputePipelineState(pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        
        let cameraParams = self.scene.camera.getParameterArray();
        let intParams = [UInt32(self.sampleNumber), UInt32(NSDate().timeIntervalSince1970)];
        
        let a = self.device.newBufferWithBytes(intParams, length: sizeofValue(intParams[0])*intParams.count+4, options:nil);
        let b = self.device.newBufferWithBytes(cameraParams, length: sizeofValue(cameraParams[0])*cameraParams.count, options:nil);
        let c = self.device.newBufferWithBytes(scene.spheres, length: sizeofValue(scene.spheres[0]) * scene.spheres.count, options:nil);
        
        commandEncoder.setBuffer(a, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(b, offset: 0, atIndex: 1);
        commandEncoder.setBuffer(c, offset: 0, atIndex: 2);
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding();
        commandBuffer.commit();
        commandBuffer.waitUntilCompleted();
        
        self.inputTexture = self.outputTexture;
        self.sampleLabel.text = NSString(format: "%u", self.sampleNumber++);
        
    }
    
    func gameloop() {
        autoreleasepool {
            self.render()
            self.imageView.image = UIImage(MTLTexture: self.inputTexture)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func button(sender: AnyObject) {
        self.cameraToggle = !cameraToggle;
    }
    
    var lastX:Float = -0.5;

    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        
        var point = sender.locationInView(self.imageView);
        let dx:Float = 1.0 / 500.0;
        let dy:Float = 1.0 / 500.0;
        let x:Float = Float(500.0-point.x)  * dx;
        let y:Float = Float(500.0-point.y)  * dy;
        var ray:Ray = scene.camera.getRay(x, y: y);
        selectedSphere = scene.getClosestHit(ray);
        if (selectedSphere > -1){
            lastX = scene.spheres[selectedSphere].position ⋅ scene.camera.cameraRight;
            scene.spheres[selectedSphere].color = Vector3D(x:1.0, y:0.0, z:0.0);
        }
        
        for i in (0...scene.spheres.count-1){
            if (i != selectedSphere){
                scene.spheres[i].color = Vector3D(x:0.75, y:0.75, z:0.75);
            }
        }
        
        self.sampleNumber = 1;
    }
    
    @IBAction func dragAction(sender: UIPanGestureRecognizer) {
        
        self.sampleNumber = 1;
        
        //var point = sender.velocityInView(self.imageView);
        //self.cameraEye = Matrix.transformVector(Matrix.rotateY(Float(point.x/(6.0*500.0))) * Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraEye);
        //self.cameraUp = Matrix.transformVector(Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraUp);
        
        //Vertical
        //self.cameraEye = Matrix.transformVector(Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraEye);
        //self.cameraUp = Matrix.transformVector(Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraUp);
        
        //Horizontal
        
        var point = sender.locationInView(self.imageView);
        var velocity = sender.velocityInView(self.imageView);
        var x = Float((((500-point.x)/500.0) * 2.0) - 1.0);
        var y = Float((((500-point.y)/500.0) * 2.0) - 1.0) * -1.0;
        var xDelta = x - lastX; // Float(((point.x+lastPoint.x)/500.0) * 2.0);// - (1.0/500)); //point.x - lastPoint.x;
    
        if (selectedSphere > -1){
            var currentPosition:Vector3D = scene.spheres[selectedSphere].position;
            scene.spheres[selectedSphere].position = Matrix.transformPoint(Matrix.translate(scene.camera.cameraRight * xDelta), right: currentPosition);
        } else{
            self.scene.camera.cameraPosition = self.scene.camera.cameraPosition * Matrix.rotateY(Float(velocity.x/(6.0*500.0)));
        }
        lastX = x;
        
    }
    
    @IBOutlet weak var button: UIButton!
}

