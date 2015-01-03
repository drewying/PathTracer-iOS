//
//  Sphere.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/29/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation

struct Sphere{
    var position:Vector3D = Vector3D(x: 0.0,y: 0.0,z: 0.0);
    var radius:Float = 0.0;
    var color:Vector3D = Vector3D(x: 0.0,y: 0.0,z: 0.0);
    var material:Material = Material.DIFFUSE;

    init(position:Vector3D, radius:Float, color:Vector3D, material:Material){
        self.position = position;
        self.radius = radius;
        self.color = color;
        self.material = material;
    }
    
    func getBounds() -> BoundingBox{
        let diagonal = Vector3D(x: radius, y: radius, z: radius);
        return BoundingBox(min: position-diagonal, max: position+diagonal);
    }
}