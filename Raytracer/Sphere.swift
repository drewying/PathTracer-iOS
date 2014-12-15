//
//  Sphere.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation

class Sphere : Shape {
    
    let radius: Double;
    let center: Vector3D;
    let material: Material;
    
    init(material: Material, center: Vector3D, radius: Double){
        self.material = material;
        self.radius = radius;
        self.center = center;
    }
    
    func intersect(ray:Ray, distance:Double) -> Hit{
 
        let v = center - ray.origin;
        
        let b = v ⋅ ray.direction;
        
        let discriminant = b * b - (v ⋅ v) + radius * radius;
        
        if (discriminant < 0) {
            return Hit(distance:DBL_MAX, ray: nil, shape: nil, material: nil, normal: nil);
        }
        
        let d = sqrt(discriminant);
        
        let tFar = b + d;
        
        let eps = 1e-4;
        
        if (tFar <= eps) {
            return Hit(distance:DBL_MAX, ray: nil, shape: nil, material: nil, normal: nil);
        }
        
        let tNear = b - d;
        
        if (tNear <= eps) {
            let hitpos = ray.origin + ray.direction * tFar;
            let norm = (hitpos - center);
            return Hit(distance:tFar, ray: ray, shape: self, material: material, normal: norm);
        } else{
            let hitpos = ray.origin + ray.direction * tNear;
            let norm = (hitpos - center);
            return Hit(distance:tNear, ray: ray, shape: self, material: material, normal: norm);
        }
    }
    
    func getMaterial() -> Material{
        return material;
    }
}