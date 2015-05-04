//
//  MetalContext.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 1/14/15.
//  Copyright (c) 2015 Drew Ingebretsen. All rights reserved.
//

import UIKit

class MetalContext: NSObject {
    let device:MTLDevice;
    let defaultLibrary: MTLLibrary;
    let commandQueue: MTLCommandQueue;
    let pipelineState: MTLComputePipelineState!;
    
    
    init(device:MTLDevice){
        self.device = device;
        defaultLibrary = device.newDefaultLibrary()!;
        commandQueue = device.newCommandQueue();
        let kernalProgram:MTLFunction! = defaultLibrary.newFunctionWithName("mainProgram");
        pipelineState = device.newComputePipelineStateWithFunction(kernalProgram, error: nil);
    }
}
