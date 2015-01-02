//
//  Scene.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation

class Scene : NSObject {
    
    var camera:Camera;
    var spheres:[Sphere] = [];
    
    init(camera:Camera){
        self.camera = camera;
    }
    
    func getClosestHit(ray:Ray) -> Int{
        for i in (0...spheres.count-1){
            if (spheres[i].getBounds().intersectsWithRay(ray)){
                return i;
            }
        }
        return -1;
    }
    
    func addSphere(sphere:Sphere){
        spheres.append(sphere);
    }
}