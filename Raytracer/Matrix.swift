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
        [1.0,0.0,0.0,0.0],
        [0.0,1.0,0.0,0.0],
        [0.0,0.0,1.0,0.0],
        [0.0,0.0,0.0,1.0]
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
    
    static func rotateX(angle:Float) -> Matrix {
        var returnMatrix = identityMatrix();
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
    
        returnMatrix.x[1][1] = cosine;
        returnMatrix.x[1][2] = -sine;
        returnMatrix.x[2][1] = sine;
        returnMatrix.x[2][2] = cosine;
    
        return returnMatrix;
    }
    
    static func rotateY(angle:Float) -> Matrix {
        var returnMatrix = identityMatrix();
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
    
        returnMatrix.x[0][0] = cosine;
        returnMatrix.x[0][2] = sine;
        returnMatrix.x[2][0] = -sine;
        returnMatrix.x[2][2] = cosine;
        
        return returnMatrix
    }
    
    static func rotateZ(angle:Float) -> Matrix {
        var returnMatrix = identityMatrix();
        let cosine:Float = cos(angle);
        let sine:Float = sin(angle);
    
        returnMatrix.x[0][0] = cosine;
        returnMatrix.x[0][1] = -sine;
        returnMatrix.x[1][0] = sine;
        returnMatrix.x[1][1] = cosine;
    
        return returnMatrix;
    }
    
    static func transformPoint(left:Matrix, right:Vector3D) -> Vector3D {
        return left * right;
    }
    
    static func transformVector(left:Matrix, right:Vector3D) -> Vector3D{
        
        let x = (right.x * left.x[0][0] + right.y * left.x[0][1] + right.z * left.x[0][2]);
        let y = (right.x * left.x[1][0] + right.y * left.x[1][1] + right.z * left.x[1][2]);
        let z = (right.x * left.x[2][0] + right.y * left.x[2][1] + right.z * left.x[2][2]);
    
        let returnVector = Vector3D(x:x, y:y, z:z);
        return returnVector;
    }

}

func * (left: Matrix, right: Vector3D) -> Vector3D {
    let x:Float = (right.x * left.x[0][0] + right.y * left.x[0][1] + right.z * left.x[0][2] + left.x[0][3]);
    let y:Float = (right.x * left.x[1][0] + right.y * left.x[1][1] + right.z * left.x[1][2] + left.x[1][3]);
    let z:Float = (right.x * left.x[2][0] + right.y * left.x[2][1] + right.z * left.x[2][2] + left.x[2][3]);
    var temp:Float = right.x * left.x[3][0] + right.y * left.x[3][1] + right.z * left.x[3][2] + left.x[3][3];
    
    var returnVector:Vector3D = Vector3D(x:x,y:y,z:z);
    returnVector /= temp;
    return returnVector;
}
