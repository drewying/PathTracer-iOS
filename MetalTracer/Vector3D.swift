//
//  Vector.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/4/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import Foundation



struct Vector3D{
    var x:Float = 0.0;
    var y:Float = 0.0;
    var z:Float = 0.0;
    
    init(x:Float, y:Float, z:Float){
        self.x = x;
        self.y = y;
        self.z = z;
    }
    
    func normalized() -> Vector3D{
        let len = length();
        let scale = 1.0 / len;
        return Vector3D(x: x*scale, y: y*scale, z: z*scale);
    }
    
    func abs() -> Vector3D{
        return Vector3D(x: fabsf(x), y: fabsf(y), z: fabsf(z));
    }
    
    func length() -> Float{
        return sqrt(x * x + y * y + z * z);
    }
    
    func toString() -> String{
        return "(\(x),\(y),\(z)";
    }
    
    static func up() -> Vector3D {
        return Vector3D(x: 0.0, y: 1.0, z: 0.0)
    }
    
    static func down() -> Vector3D {
        return Vector3D(x: 0.0, y: -1.0, z: 0.0)
    }
    
    static func forward() -> Vector3D {
        return Vector3D(x: 0.0, y: 0.0, z: 1.0)
    }
    
    static func back() -> Vector3D {
        return Vector3D(x: 0.0, y: 0.0, z: -1.0)
    }
    
    static func right() -> Vector3D {
        return Vector3D(x: 1.0, y: 0.0, z: 0.0)
    }
    
    static func left() -> Vector3D {
        return Vector3D(x: -1.0, y: 0.0, z: 0.0)
    }
}

prefix func - (vector: Vector3D) -> Vector3D {
    return Vector3D(x:-vector.x, y:-vector.y, z:-vector.z);
}

func + (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x + right.x, y:left.y + right.y, z: left.z + right.z);
}

func + (left: Vector3D, right: Float) -> Vector3D{
    return Vector3D(x:left.x + right, y:left.y + right, z: left.z + right);
}

func - (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x - right.x, y:left.y - right.y, z: left.z - right.z);
}

func - (left: Vector3D, right: Float) -> Vector3D{
    return Vector3D(x:left.x - right, y:left.y - right, z: left.z - right);
}

func * (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x * right.x, y:left.y * right.y, z: left.z * right.z);
}

func * (left: Vector3D, right: Float) -> Vector3D{
    return Vector3D(x:left.x * right, y:left.y * right, z: left.z * right);
}

func / (left: Vector3D, right: Vector3D) -> Vector3D{
    return Vector3D(x:left.x / right.x, y:left.y / right.y, z: left.z / right.z);
}

func / (left: Vector3D, right: Float) -> Vector3D{
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

func ⋅ (left: Vector3D, right: Vector3D) -> Float{
    return left.x * right.x + left.y * right.y + left.z * right.z;
}



