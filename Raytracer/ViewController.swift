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
    var device: MTLDevice! = nil;
    var defaultLibrary: MTLLibrary! = nil;
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLComputePipelineState! = nil
    var inputTexture: MTLTexture! = nil;
    var outputTexture: MTLTexture! = nil;
    var timer: CADisplayLink! = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        defaultLibrary = device.newDefaultLibrary()
        commandQueue = device.newCommandQueue();
        let kernalProgram = defaultLibrary!.newFunctionWithName("pathtrace");
        pipelineState = self.device.newComputePipelineStateWithFunction(kernalProgram!, error: nil);
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.BGRA8Unorm, width: 500, height: 500, mipmapped: true);
        
        inputTexture = device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = device.newTextureWithDescriptor(textureDescriptor);
        
        timer = CADisplayLink(target: self, selector: Selector("gameloop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func render() {
        let threadgroupCounts = MTLSizeMake(8, 8, 1);
        let threadgroups = MTLSizeMake(500 / threadgroupCounts.width, 500 / threadgroupCounts.height, 1);
        let commandBuffer = commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        commandEncoder.setComputePipelineState(pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding();
        commandBuffer.commit();
        commandBuffer.waitUntilCompleted();
        self.inputTexture = self.outputTexture;
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


}

