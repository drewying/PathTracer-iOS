//
//  Camera.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/4/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation

import UIKit

class Camera : NSObject{
    let eye:Vector3D;
    let lookAt:Vector3D;
    let up:Vector3D = Vector3D(x: 0.0, y: 1.0, z: 0.0);
    let right:Vector3D = Vector3D(x: 1.0, y: 0.0, z:0.0);
    
    let xResolution:Int = 1024;
    let yResolution:Int = 800;
    let apertureSize:Double = 0;
    let focalLength:Double = 0;
    
    init(eye:Vector3D, lookAt: Vector3D){
        self.eye = eye;
        self.lookAt = lookAt;
    }
    
    func makeRay(x:Double, y:Double, r1:Double, r2:Double) -> Ray{
    
        let base = right * x + up * y;
        let centered = base - Vector3D(x:right.x/2.0, y:up.y/2.0, z:0.0);
    
        let U = up * r1 * apertureSize;
        let V = right * r2 * apertureSize;
        let UV = U+V;
    
        let direction = (((centered + lookAt) * focalLength) - UV).normalized();
        let origin = eye + UV;
    
        return Ray(origin: origin, direction: direction);
    }
    
    func render(scene: NSArray) -> UIImage{
    
        let dx = 1.0 / Double(xResolution);
        let xMin = 0.0;
        let dy = 1.0 / Double(yResolution);
        let yMin = 0.0;
        
        
        for var i = 0; i < yResolution; ++i {
            let y = yMin + Double(i) * dy;
            for var j = 0; j < xResolution; j+=1 {
                let x = xMin + Double(j) * dx;
                //finalColor = samplePixel(scene, x, y, time);
                //image->set(j, i, finalColor);
            }
        }
        
        return UIImage();
    }
    
    func samplePixel(scene: NSArray, x:Double, y:Double){
        
    }
    
}