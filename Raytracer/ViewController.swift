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
    
    var cameraEye:Vector3D = Vector3D(x:3.0, y:0.0, z:0.0);
    
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
        
        //self.cameraEye.x = cos(0.5);
        //self.cameraEye.z = sin(0.5);
        
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
        let intParams = [UInt32(self.sampleNumber), UInt32(NSDate().timeIntervalSince1970)];
        
        let a = self.device.newBufferWithBytes(intParams, length: sizeofValue(intParams[0])*intParams.count+4, options:nil);
        let b = self.device.newBufferWithBytes(floatParams, length: sizeofValue(floatParams[0])*floatParams.count+4, options:nil);
        
        
        //commandEncoder.setBuffer(seedBuffer, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(a, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(b, offset: 0, atIndex: 1);
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding();
        commandBuffer.commit();
        commandBuffer.waitUntilCompleted();
        
        self.inputTexture = self.outputTexture;
        self.sampleLabel.text = NSString(format: "%u", self.sampleNumber++);
        
        /*var jitterIndex:UInt32 = UInt32(self.sampleNumber%100);
        var xJitterPosition: UInt32 = UInt32(jitterIndex%10);
        var yJitterPosition: UInt32 = UInt32(floor(CGFloat(jitterIndex)/10.0));
        
        var rand1 = CGFloat(Float(arc4random()) / Float(UINT32_MAX));
        var rand2 = CGFloat(Float(arc4random()) / Float(UINT32_MAX));
        
        
        var incX:CGFloat = 1.0/500;
        var xOffset:CGFloat = (rand1 * CGFloat(incX)) + (CGFloat(xJitterPosition) * incX);
        
        var incY:CGFloat = 1.0/500;
        var yOffset = (rand2 * CGFloat(incY)) + (CGFloat(yJitterPosition) * incY);*/
        
        //NSLog("Break");
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
        
        //let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: 500, height: 500, mipmapped: true);
        //inputTexture = device.newTextureWithDescriptor(textureDescriptor);
        self.sampleNumber = 1;
        
        var point = sender.velocityInView(self.imageView);
        self.cameraEye = Matrix.transformPoint(Matrix.rotateY(Float(point.x/(6.0*500.0))) * Matrix.rotateX(Float(point.y/(6.0*500.0))), right: self.cameraEye);
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

