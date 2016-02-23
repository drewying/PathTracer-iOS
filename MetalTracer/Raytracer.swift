//
//  Raytracer.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 1/15/15.
//  Copyright (c) 2015 Drew Ingebretsen. All rights reserved.
//

import UIKit

class Raytracer: NSObject {
    var renderContext:MetalContext;
    var xResolution:Int;
    var yResolution:Int;
    var inputTexture: MTLTexture;
    var outputTexture: MTLTexture;
    var sampleNumber = 1;
    var renderMode:Int = 3;
    var imageTexture: MTLTexture! = nil;
    
    var seedMemory:UnsafeMutablePointer<Void> = nil
    var alignment:Int = 0x4000
    var byteSize:Int = Int(196608 * sizeof(UInt32))
    
    init(renderContext:MetalContext, xResolution:Int, yResolution:Int){
        self.renderContext = renderContext;
        self.xResolution = xResolution;
        self.yResolution = yResolution;
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        inputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);

        //Set up seed memory
        posix_memalign(&seedMemory, alignment, byteSize)
        let x:UnsafeMutablePointer<UInt32> = UnsafeMutablePointer<UInt32>(seedMemory)
        for i in 0...196607 {
            x[i] = arc4random()
        }
    }
    
    func reset(){
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        inputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);
    }
    
    func renderScene(scene:Scene) -> UIImage{
        //let x:UnsafeMutablePointer<UInt32> = UnsafeMutablePointer<UInt32>(seedMemory)
        //print(x[0])
        
        let threadgroupCounts = MTLSizeMake(16,16, 1);
        let threadgroups = MTLSizeMake(xResolution / threadgroupCounts.width, yResolution / threadgroupCounts.height, 1);
        let commandBuffer = renderContext.commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        
        commandEncoder.setComputePipelineState(renderContext.pipelineState);
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        commandEncoder.setTexture(imageTexture, atIndex:2);
        
        let intParams = [UInt32(sampleNumber), UInt32(NSDate().timeIntervalSince1970), UInt32(xResolution), UInt32(yResolution), UInt32(renderMode), 2];
        
        let a = renderContext.device.newBufferWithBytes(intParams, length: sizeof(UInt32) * intParams.count, options:.CPUCacheModeDefaultCache);
        
        commandEncoder.setBuffer(renderContext.device.newBufferWithBytesNoCopy(seedMemory, length: byteSize, options:.CPUCacheModeDefaultCache, deallocator:nil), offset: 0, atIndex: 0)
        commandEncoder.setBuffer(a, offset: 0, atIndex: 1);
        commandEncoder.setBuffer(scene.cameraBuffer, offset: 0, atIndex: 2);
        commandEncoder.setBuffer(scene.sphereBuffer, offset: 0, atIndex: 3);
        commandEncoder.setBuffer(scene.wallColorBuffer, offset: 0, atIndex: 4);
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        
        renderContext.commandQueue.insertDebugCaptureBoundary();
        //commandEncoder.insertDebugSignpost("com.apple.GPUTools.event.debug-frame")
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
        
        //self.inputTexture.replaceRegion(MTLRegionMake2D(0, 0, self.xResolution, self.yResolution), mipmapLevel: 0, withBytes: &self.outputTexture, bytesPerRow: 4*self.xResolution);
        
        self.inputTexture = self.outputTexture;
        sampleNumber++
        //return UIImage.imageFromTexture(self.inputTexture)
        return UIImage(MTLTexture: self.inputTexture)
    }
}

//368 x 348