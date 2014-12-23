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
    var sampleCount = 1;
    
    var cameraEye:Vector3D = Vector3D(x:0.0, y:0.0, z:-3.0);
    
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
        
        self.generateRandom();
        
        seedBuffer = self.device.newBufferWithBytes(seed, length: sizeofValue(seed[0])*seed.count, options: nil);
        //seedBuffer = self.device.newBufferWithLength(sizeofValue(UInt32(0.0))*500*500, options: nil);
    }
    
    func render() {
        let threadgroupCounts = MTLSizeMake(16, 16, 1);
        let threadgroups = MTLSizeMake(500 / threadgroupCounts.width, 500 / threadgroupCounts.height, 1);
        let commandBuffer = commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        commandEncoder.setComputePipelineState(pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        
        let floatParams = [self.cameraEye];
        let intParams = [UInt32(self.sampleCount)];
        
        let a = self.device.newBufferWithBytes(intParams, length: sizeofValue(intParams[0])*intParams.count, options:nil);
        let b = self.device.newBufferWithBytes(floatParams, length: sizeofValue(floatParams[0])*floatParams.count+4, options:nil);
        
        
        commandEncoder.setBuffer(seedBuffer, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(a, offset: 0, atIndex: 1);
        commandEncoder.setBuffer(b, offset: 0, atIndex: 2);
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding();
        commandBuffer.commit();
        commandBuffer.waitUntilCompleted();
        
        self.inputTexture = self.outputTexture;
        self.sampleLabel.text = NSString(format: "%u", self.sampleCount++);
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
        self.render();
        self.imageView.image = UIImage(MTLTexture: self.inputTexture)
    }

    var tempX:Float = 0;
    
    @IBAction func dragAction(sender: UIPanGestureRecognizer) {
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: 500, height: 500, mipmapped: true);
        inputTexture = device.newTextureWithDescriptor(textureDescriptor);
        self.sampleCount = 1;
        
        
        
        var point = sender.velocityInView(self.imageView);
        tempX = tempX + (Float(point.x-250.0));
        NSLog("%f", tempX);
        self.cameraEye = Matrix.transformPoint(Matrix.rotateX(Float(point.x/(6.0*500.0))), right: self.cameraEye);
        //self.cameraEye.y = sinCalc*(x) + cosCalc*(y);
            
        
    }
    
    func generateRandom(){
        self.seed = Array<UInt32>();
        for i in 0..<(500*500){
            self.seed.append(UInt32(arc4random()));
        }
    }
    
    @IBOutlet weak var button: UIButton!
}

