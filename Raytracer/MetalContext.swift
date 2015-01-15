//
//  MetalContext.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 1/14/15.
//  Copyright (c) 2015 Drew Ingebretsen. All rights reserved.
//

import UIKit

class MetalContext: NSObject {
    let device:MTLDevice = MTLCreateSystemDefaultDevice();
}
