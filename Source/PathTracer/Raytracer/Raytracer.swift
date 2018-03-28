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
        
        let inputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: xResolution, height: yResolution, mipmapped: false);
        inputTextureDescriptor.usage = .shaderRead;
        let outputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: xResolution, height: yResolution, mipmapped: false);
        outputTextureDescriptor.usage = .shaderWrite;
        let renderTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        renderTextureDescriptor.usage = .shaderWrite;
        
        inputTexture = renderContext.device.makeTexture(descriptor: inputTextureDescriptor)!;
        outputTexture = renderContext.device.makeTexture(descriptor: outputTextureDescriptor)!;
        renderTexture = renderContext.device.makeTexture(descriptor: renderTextureDescriptor)!;
    }
    
    func reset(){
        let inputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: xResolution, height: yResolution, mipmapped: false);
        inputTextureDescriptor.usage = .shaderRead;
        let outputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: xResolution, height: yResolution, mipmapped: false);
        outputTextureDescriptor.usage = .shaderWrite;
        let renderTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: xResolution, height: yResolution, mipmapped: false);
        renderTextureDescriptor.usage = .shaderWrite;
        
        inputTexture = renderContext.device.makeTexture(descriptor: inputTextureDescriptor)!;
        outputTexture = renderContext.device.makeTexture(descriptor: outputTextureDescriptor)!;
        renderTexture = renderContext.device.makeTexture(descriptor: renderTextureDescriptor)!;
        sampleNumber = 1
    }
    
    func renderScene(_ scene:Scene) -> UIImage{
        
        let threadgroupCounts = MTLSizeMake(16,16, 1);
        let threadgroups = MTLSizeMake(xResolution / threadgroupCounts.width, yResolution / threadgroupCounts.height, 1);
        let commandBuffer = renderContext.commandQueue.makeCommandBuffer();
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder();
        
        commandEncoder?.setComputePipelineState(renderContext.pipelineState);
        
        commandEncoder?.setTexture(inputTexture, index: 0);
        commandEncoder?.setTexture(outputTexture, index:1);
        commandEncoder?.setTexture(renderTexture, index:2);
        
        let intParams = [UInt32(sampleNumber), UInt32(Date().timeIntervalSince1970), UInt32(xResolution), UInt32(yResolution), UInt32(renderMode), 2];
        
        let a = renderContext.device.makeBuffer(bytes: intParams, length: MemoryLayout<UInt32>.size * intParams.count, options:MTLResourceOptions());
        
        commandEncoder?.setBuffer(a, offset: 0, index: 0);
        commandEncoder?.setBuffer(scene.cameraBuffer, offset: 0, index: 1);
        commandEncoder?.setBuffer(scene.sphereBuffer, offset: 0, index: 2);
        commandEncoder?.setBuffer(scene.wallColorBuffer, offset: 0, index: 3);
        
        commandEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        
        //renderContext.commandQueue.insertDebugCaptureBoundary();
        
        commandEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        self.inputTexture = self.outputTexture;
        sampleNumber += 1
        
        return UIImage.imageFromTexture(renderTexture)
    }
}

//368 x 348
