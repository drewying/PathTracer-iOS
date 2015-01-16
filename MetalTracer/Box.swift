//
//  Plane.swift
//  MetalTracer
//
//  Created by Drew Ingebretsen on 1/15/15.
//  Copyright (c) 2015 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Box {
    var min:Vector3D = Vector3D(x: 0.0,y: 0.0,z: 0.0);
    var max:Vector3D = Vector3D(x: 0.0,y: 0.0,z: 0.0);
    var normal:Vector3D = Vector3D(x: 0.0, y:0.0, z:0.0);
    var color:Vector3D = Vector3D(x: 0.0,y: 0.0,z: 0.0);
    var material:Material = Material.DIFFUSE;
    
    init(min:Vector3D, max:Vector3D, normal:Vector3D, color:Vector3D, material:Material){
        self.min = min;
        self.max = max;
        self.normal = normal;
        self.color = color;
        self.material = material;
    }
}
