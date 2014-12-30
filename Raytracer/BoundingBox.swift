//
//  BoundingBox.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/30/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation

struct BoundingBox {
    var min:Vector3D;
    var max:Vector3D;
    
    func intersectsWithPoint(point:CGPoint) -> Bool{
        let x = Float(point.x);
        let y = Float(point.y);
        
        if (x > max.x){
            return false;
        }
        if (x < min.x){
            return false;
        }
        if (y > max.y){
            return false;
        }
        if (y < min.y){
            return false;
        }
    
        return true;
    }
}