//
//  Sphere.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/29/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation

struct Sphere{
    var position:Vector3D;
    var radius:Float;
    var color:Vector3D;
    var material:Float;
    
    func getBounds() -> BoundingBox{
        let diagonal = Vector3D(x: radius, y: radius, z: radius);
        return BoundingBox(min: position-diagonal, max: position+diagonal);
    }
}