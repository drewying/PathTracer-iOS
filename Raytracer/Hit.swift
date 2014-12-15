//
//  Hit.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation

struct Hit{
    var distance: Double;
    var ray : Ray?;
    var shape: Shape?;
    var material: Material?;
    var normal: Vector3D?;
    
    func didHit() -> Bool{
        return shape == nil;
    }
    
    func hitPosition() -> Vector3D{
        return ray!.origin + ray!.direction * distance;
    }
    
}