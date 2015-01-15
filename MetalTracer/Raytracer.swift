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
    
    init(renderContext:MetalContext){
        self.renderContext = renderContext;
    }
    
    func renderScene(scene:Scene) -> UIImage{
        return UIImage();
    }
}
