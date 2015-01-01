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
    
    var cameraToggle:Bool = false;
    
    var cameraEye:Vector3D = Vector3D(x:0.0, y:0.0, z:3.0);
    var cameraUp:Vector3D = Vector3D(x:0.0, y:1.0, z:0.0);
    //var cameraRight:Vector3D = Vector3D(x: 1.0, y:0.0, z:0.0);
    
    var spheres:[Sphere] = [
        Sphere(position:Vector3D(x:0.0, y:-0.8, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0),
        Sphere(position:Vector3D(x:0.0, y:-0.4, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0),
        Sphere(position:Vector3D(x:0.0, y:0.0, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0),
        Sphere(position:Vector3D(x:0.0, y:0.4, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0),
        Sphere(position:Vector3D(x:0.0, y:0.8, z:0.0),radius:0.2, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: 1.0)
    ];
    
    var seed: Array<UInt32>! = nil; //[11111];
    var seedBuffer: MTLBuffer! = nil;
    
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
    }
    
    func render() {
        let threadgroupCounts = MTLSizeMake(16, 16, 1);
        let threadgroups = MTLSizeMake(500 / threadgroupCounts.width, 500 / threadgroupCounts.height, 1);
        let commandBuffer = commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        commandEncoder.setComputePipelineState(pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        
        let cameraParams = [self.cameraEye, self.cameraUp];
        let intParams = [UInt32(self.sampleNumber), UInt32(NSDate().timeIntervalSince1970)];
        
        let a = self.device.newBufferWithBytes(intParams, length: sizeofValue(intParams[0])*intParams.count+4, options:nil);
        let b = self.device.newBufferWithBytes(cameraParams, length: sizeofValue(cameraParams[0])*cameraParams.count, options:nil);
        let c = self.device.newBufferWithBytes(spheres, length: sizeofValue(spheres[0]) * spheres.count, options:nil);
        
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
    
    var lastPoint:CGPoint = CGPointMake(0, 0);
    
    @IBAction func dragAction(sender: UIPanGestureRecognizer) {
        
        self.sampleNumber = 1;
        
        //var point = sender.velocityInView(self.imageView);
        //self.cameraEye = Matrix.transformVector(Matrix.rotateY(Float(point.x/(6.0*500.0))) * Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraEye);
        //self.cameraUp = Matrix.transformVector(Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraUp);
        
        //Vertical
        //self.cameraEye = Matrix.transformVector(Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraEye);
        //self.cameraUp = Matrix.transformVector(Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraUp);
        
        //Horizontal
        
        
        //Adjust Sphere
        //var s:Sphere = spheres[0];
        //s.position.x = 0.5;
        
        var point = sender.locationInView(self.imageView);
        var velocity = sender.velocityInView(self.imageView);
        var x = Float(((point.x/500.0) * 2.0) - 1.0) * -1.0;
        var y = Float(((point.y/500.0) * 2.0) - 1.0) * -1.0;
        var xDelta = Float((((point.x-lastPoint.x)/500.0) * 2.0) - 1.0) * -1.0;
        lastPoint = point;
        if (!cameraToggle){
            let currentPosition:Vector3D = spheres[2].position;
            let cameraRight = cameraEye.normalized() × cameraUp
            let xPos:Vector3D = cameraRight * x
            spheres[2].position = xPos; //Matrix.transformPoint(Matrix.translate(cameraRight * xDelta), right: currentPosition);
        } else{
            self.cameraEye = self.cameraEye * Matrix.rotateY(Float(velocity.x/(6.0*500.0)));
        }
        
    }
    
    @IBOutlet weak var button: UIButton!
}

