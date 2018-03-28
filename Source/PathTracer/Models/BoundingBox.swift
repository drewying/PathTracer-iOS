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
    
    func intersectsWithRay(_ ray:Ray) -> Bool{
        
        //Code from http://people.csail.mit.edu/amy/papers/box-jgt.ps
        
        var xMin:Float
        var xMax:Float
        var yMin:Float
        var yMax:Float
        var zMin:Float
        var zMax:Float
        
        if (ray.direction.x >= 0.0) {
            xMin = (min.x - ray.origin.x) / ray.direction.x;
            xMax = (max.x - ray.origin.x) / ray.direction.x;
        }
        else {
            xMin = (max.x - ray.origin.x) / ray.direction.x;
            xMax = (min.x - ray.origin.x) / ray.direction.x;
        }
        if (ray.direction.y >= 0) {
            yMin = (min.y - ray.origin.y) / ray.direction.y;
            yMax = (max.y - ray.origin.y) / ray.direction.y;
        }
        else {
            yMin = (max.y - ray.origin.y) / ray.direction.y;
            yMax = (min.y - ray.origin.y) / ray.direction.y;
        }
        
        if ((xMin > yMax) || (yMin > xMax)){
            return false;
        }
        
        if (yMin > xMin){
            xMin = yMin;
        }
        
        if (yMax < xMax){
            xMax = yMax;
        }
        
        if (ray.direction.z >= 0) {
            zMin = (min.z - ray.origin.z) / ray.direction.z;
            zMax = (max.z - ray.origin.z) / ray.direction.z;
        } else {
            zMin = (max.z - ray.origin.z) / ray.direction.z;
            zMax = (min.z - ray.origin.z) / ray.direction.z;
        }
        if ((xMin > zMax) || (zMin > xMax)){
            return false;
        }
        
        if (zMin > xMin){
            xMin = zMin;
        }
        
        if (zMax < xMax){
            xMax = zMax;
        }
        
        return true;
    }
}
