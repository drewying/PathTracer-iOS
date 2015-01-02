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
    var cameraRight:Vector3D{
        get {
            return -cameraPosition.normalized() × cameraUp;
        }
    }
    var cameraPosition:Vector3D;
    
    init(cameraUp:Vector3D, cameraPosition:Vector3D){
        self.cameraUp = cameraUp;
        self.cameraPosition = cameraPosition;
    }
    
    func getRay(x:Float, y:Float) -> Ray{
        let lookAt:Vector3D = -cameraPosition.normalized();
        let base:Vector3D = cameraRight * x + cameraUp * y;
        let centered:Vector3D = base - Vector3D(x:cameraRight.x/2.0, y:cameraUp.y/2.0, z:(cameraUp + cameraRight).z/2.0);
        let direction = (centered + lookAt).normalized();
        return Ray(origin: cameraPosition, direction: direction);
    }
    
    func getParameterArray() -> [Vector3D]{
        return [cameraPosition, cameraUp];
    }
    
}