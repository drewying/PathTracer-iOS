//
//  Matrix.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/20/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit

struct Matrix{
    var x:[[Float]] = [
        [0.0,0.0,0.0,0.0],
        [0.0,0.0,0.0,0.0],
        [0.0,0.0,0.0,0.0],
        [0.0,0.0,0.0,0.0]
    ];
    
    static func identityMatrix() -> Matrix{
        var m = Matrix();
        m.x = [
            [1.0,0.0,0.0,0.0],
            [0.0,1.0,0.0,0.0],
            [0.0,0.0,1.0,0.0],
            [0.0,0.0,0.0,1.0]
        ];
        return m;
    }
    
    static func translate(_ vector:Vector3D) -> Matrix{
        var returnMatrix = identityMatrix();
        returnMatrix.x[0][3] = vector.x;
        returnMatrix.x[1][3] = vector.y;
        returnMatrix.x[2][3] = vector.z;
        return returnMatrix;
    }
    
    static func rotate(_ axis:Vector3D, angle:Float) -> Matrix{
        let axisN:Vector3D = axis.normalized();
        
        var returnMatrix = Matrix();
        
        let x:Float = axisN.x;
        let y:Float = axisN.y;
        let z:Float = axisN.z;
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
        let t:Float = 1.0 - cosine;
        
        returnMatrix.x[0][0] = t * x * x + cosine
        returnMatrix.x[1][0] = t * x * y - sine * z;
        returnMatrix.x[2][0] = t * x * z + sine * y;
        returnMatrix.x[3][0] = 0.0;
        
        returnMatrix.x[0][1] = t * x * y + sine * z;
        returnMatrix.x[1][1] = t * y * y + cosine;
        returnMatrix.x[2][1] = t * y * z - sine * x;
        returnMatrix.x[3][1] = 0.0;
        
        returnMatrix.x[0][2] = t * x * z - sine * y;
        returnMatrix.x[1][2] = t * y * z + sine * x;
        returnMatrix.x[2][2] = t * z * z + cosine;
        returnMatrix.x[3][2] = 0.0;
        
        returnMatrix.x[0][3] = 0.0;
        returnMatrix.x[1][3] = 0.0;
        returnMatrix.x[2][3] = 0.0;
        returnMatrix.x[3][3] = 1.0;
        
        return returnMatrix;
    }
    
    static func rotateX(_ angle:Float) -> Matrix {
        var returnMatrix = identityMatrix();
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
        
        returnMatrix.x[1][1] = cosine;
        returnMatrix.x[1][2] = -sine;
        returnMatrix.x[2][1] = sine;
        returnMatrix.x[2][2] = cosine;
        
        return returnMatrix;
    }
    
    static func rotateY(_ angle:Float) -> Matrix {
        var returnMatrix = identityMatrix();
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
        
        returnMatrix.x[0][0] = cosine;
        returnMatrix.x[0][2] = sine;
        returnMatrix.x[2][0] = -sine;
        returnMatrix.x[2][2] = cosine;
        
        return returnMatrix
    }
    
    static func rotateZ(_ angle:Float) -> Matrix {
        var returnMatrix = identityMatrix();
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
        
        returnMatrix.x[0][0] = cosine;
        returnMatrix.x[0][1] = -sine;
        returnMatrix.x[1][0] = sine;
        returnMatrix.x[1][1] = cosine;
        
        return returnMatrix;
    }
    
    static func transformPoint(_ left:Matrix, right:Vector3D) -> Vector3D {
        return left * right;
    }
    
    static func transformVector(_ left:Matrix, right:Vector3D) -> Vector3D{
        
        var x = (right.x * left.x[0][0] + right.y * left.x[0][1] + right.z * left.x[0][2]);
        x += left.x[0][3];
        var y = (right.x * left.x[1][0] + right.y * left.x[1][1] + right.z * left.x[1][2]);
        y += left.x[1][3]
        var z = (right.x * left.x[2][0] + right.y * left.x[2][1] + right.z * left.x[2][2]);
        z += left.x[2][3]
        var t = (right.x * left.x[3][0] + right.y * left.x[3][1] + right.z * left.x[3][2]);
        t += left.x[3][3]
        let returnVector = Vector3D(x:x, y:y, z:z);
        return returnVector / t;
    }
    
}

func * (left: Matrix, right: Matrix) -> Matrix {
    var m = Matrix();
    for i in 0...3{
        for j in 0...3{
            var subt:Float = 0;
            for k in 0...3{
                subt += left.x[i][k] * right.x[k][j];
                m.x[i][j] = subt;
            }
        }
    }
    return m;
}

func * (left: Vector3D, right: Matrix) -> Vector3D {
    return right * left;
}

func * (left: Matrix, right: Vector3D) -> Vector3D {
    var x:Float
    x = (right.x * left.x[0][0])
    x += (right.y * left.x[0][1])
    x += (right.z * left.x[0][2])
    x += left.x[0][3];
    
    var y:Float;
    y = (right.x * left.x[1][0])
    y += (right.y * left.x[1][1])
    y += (right.z * left.x[1][2])
    y += left.x[1][3];
    
    var z:Float;
    z = (right.x * left.x[2][0])
    z += (right.y * left.x[2][1])
    z += (right.z * left.x[2][2])
    z += left.x[2][3];
    
    var t:Float;
    t = (right.x * left.x[3][0])
    t += (right.y * left.x[3][1])
    t += (right.z * left.x[3][2])
    t += left.x[3][3];
    
    var returnVector:Vector3D = Vector3D(x:x,y:y,z:z);
    returnVector = returnVector / t;
    
    return returnVector;
}
