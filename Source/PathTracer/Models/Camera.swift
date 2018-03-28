//
//  Camera.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 1/1/15.
//  Copyright (c) 2015 Drew Ingebretsen. All rights reserved.
//

import Foundation

struct Camera {
    var cameraUp:Vector3D;
    var cameraRight:Vector3D {
        get{
            return (-cameraPosition.normalized() × cameraUp)
        }
    }
    var cameraPosition:Vector3D;
    var aspectRatio:Float;
    
    init(cameraUp:Vector3D, cameraPosition:Vector3D, aspectRatio:Float){
        self.cameraUp = cameraUp;
        self.cameraPosition = cameraPosition;
        self.aspectRatio = aspectRatio;
    }
    
    func getRay(_ x:Float, y:Float) -> Ray{
        let lookAt:Vector3D = -cameraPosition.normalized();
        let l:Vector3D = (lookAt-cameraPosition).normalized();
        var right:Vector3D = l × cameraUp;
        var up:Vector3D = l × right;
        right = right.normalized();
        up = up.normalized();
        right = right * aspectRatio;
        let direction = (l + right * x + up * y).normalized();
        return Ray(origin: cameraPosition, direction: direction);
    }
    
}
