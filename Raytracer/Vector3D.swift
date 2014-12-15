//
//  Vector.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/4/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation



struct Vector3D{
    var x:Double = 0.0;
    var y:Double = 0.0;
    var z:Double = 0.0;
    
    func normalized() -> Vector3D{
        let len = length();
        let scale = 1.0 / len;
        return Vector3D(x: x*scale, y: y*scale, z: z*scale);
    }
    
    func length() -> Double{
        return sqrt(x * x + y * y + z * z);
    }
}

prefix func - (vector: Vector3D) -> Vector3D {
    return Vector3D(x:-vector.x, y:-vector.y, z:-vector.z);
}

func + (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x + right.x, y:left.y + right.y, z: left.z + right.z);
}

func + (left: Vector3D, right: Double) -> Vector3D{
    return Vector3D(x:left.x + right, y:left.y + right, z: left.z + right);
}

func - (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x - right.x, y:left.y - right.y, z: left.z - right.z);
}

func - (left: Vector3D, right: Double) -> Vector3D{
    return Vector3D(x:left.x - right, y:left.y - right, z: left.z - right);
}

func * (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x * right.x, y:left.y * right.y, z: left.z * right.z);
}

func * (left: Vector3D, right: Double) -> Vector3D{
    return Vector3D(x:left.x * right, y:left.y * right, z: left.z * right);
}

func / (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x / right.x, y:left.y / right.y, z: left.z / right.z);
}

func / (left: Vector3D, right: Double) -> Vector3D{
    return Vector3D(x:left.x / right, y:left.y / right, z: left.z / right);
}

infix operator × { associativity left precedence 160 }
infix operator ⋅ { associativity left precedence 160 }

func × (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(
        x: right.y * left.z - right.z * left.y,
        y: right.z * left.x - right.x * left.z,
        z: right.x * left.y - right.y * left.x
    );
}

func ⋅ (left: Vector3D, right: Vector3D) -> Double{
    return left.x * right.x + left.y * right.y + left.z * right.z;
}



