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
    var renderTexture: MTLTexture;
    var sampleNumber = 1;
    var renderMode:Int = 3;
    var imageTexture: MTLTexture! = nil;
    
    init(renderContext:MetalContext, xResolution:Int, yResolution:Int){
        self.renderContext = renderContext;
        self.xResolution = xResolution;
        self.yResolution = yResolution;
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA32Float, width: xResolution, height: yResolution, mipmapped: false);
        let textureDescriptorRender = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        inputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);
        renderTexture = renderContext.device.newTextureWithDescriptor(textureDescriptorRender);
    }
    
    func reset(){
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA32Float, width: xResolution, height: yResolution, mipmapped: false);
        let textureDescriptorRender = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        inputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);
        outputTexture = renderContext.device.newTextureWithDescriptor(textureDescriptor);
        renderTexture = renderContext.device.newTextureWithDescriptor(textureDescriptorRender);
    }
    
    func renderScene(scene:Scene) -> UIImage{
        
        let threadgroupCounts = MTLSizeMake(16,16, 1);
        let threadgroups = MTLSizeMake(xResolution / threadgroupCounts.width, yResolution / threadgroupCounts.height, 1);
        let commandBuffer = renderContext.commandQueue.commandBuffer();
        let commandEncoder = commandBuffer.computeCommandEncoder();
        
        commandEncoder.setComputePipelineState(renderContext.pipelineState);
        
        commandEncoder.setTexture(inputTexture, atIndex: 0);
        commandEncoder.setTexture(outputTexture, atIndex:1);
        commandEncoder.setTexture(renderTexture, atIndex:2);
        
        let intParams = [UInt32(sampleNumber), UInt32(NSDate().timeIntervalSince1970), UInt32(xResolution), UInt32(yResolution), UInt32(renderMode), 2];
        
        let a = renderContext.device.newBufferWithBytes(intParams, length: sizeof(UInt32) * intParams.count, options:.CPUCacheModeDefaultCache);
        
        commandEncoder.setBuffer(a, offset: 0, atIndex: 0);
        commandEncoder.setBuffer(scene.cameraBuffer, offset: 0, atIndex: 1);
        commandEncoder.setBuffer(scene.sphereBuffer, offset: 0, atIndex: 2);
        commandEncoder.setBuffer(scene.wallColorBuffer, offset: 0, atIndex: 3);
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        
        //renderContext.commandQueue.insertDebugCaptureBoundary();
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    
        self.inputTexture = self.outputTexture;
        sampleNumber++
        //return UIImage.imageFromTexture(self.inputTexture)
        return UIImage(MTLTexture: self.renderTexture)
    }
}

//368 x 348