//
//  PresetScenes.swift
//  MetalTracer
//
//  Created by Ingebretsen, Andrew (HBO) on 3/27/18.
//  Copyright © 2018 Drew Ingebretsen. All rights reserved.
//

import UIKit

class PresetScenes: NSObject {
    static var scene:Scene?
    static func selectPresetScene(sceneIndex:Int) {
        scene?.clearSpheres()
        if (sceneIndex == 0){
            //Metal and Glass
            scene?.addSphere(Sphere(position: Vector3D(x:-0.5, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            scene?.addSphere(Sphere(position: Vector3D(x:0.5, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.dielectric))
            scene?.light = Sphere(position:Vector3D(x:0.0,y:0.8,z:0.0), radius:0.0, color:Vector3D(x: 3.0,y: 3.0,z: 3.0), material:Material.light)
            
            scene?.wallColors[0] = Vector3D(x: 0.75, y: 0.0, z: 0.0)
            scene?.wallColors[1] = Vector3D(x: 0.0, y: 0.0, z: 0.75)
            scene?.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            scene?.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            scene?.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            scene?.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75)
            
            scene?.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene?.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 1){
            //Column of Balls
            scene?.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.75, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            scene?.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.25, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            scene?.addSphere(Sphere(position: Vector3D(x:0.0, y:0.25, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            scene?.addSphere(Sphere(position: Vector3D(x:0.0, y:0.75, z:0.0),radius:0.25, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            scene?.light = Sphere(position:Vector3D(x:-0.3,y:0.25,z:0.95), radius:0.0, color:Vector3D(x: 1.5,y: 1.5,z: 1.5), material:Material.light)
            
            scene?.wallColors[0] = Vector3D(x: 1.0, y: 1.0, z: 0.0);
            scene?.wallColors[1] = Vector3D(x: 0.0, y: 0.0, z: 1.0);
            scene?.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene?.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene?.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene?.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            
            scene?.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene?.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 2){
            //Mirrored
            scene?.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.7, z:0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            scene?.addSphere(Sphere(position: Vector3D(x:-0.3, y:-0.7, z:-0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            scene?.addSphere(Sphere(position: Vector3D(x:0.3, y:-0.7, z:-0.3),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            scene?.addSphere(Sphere(position: Vector3D(x:0.0, y:-0.2, z:0.0),radius:0.3, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            scene?.light = Sphere(position:Vector3D(x:0.0,y:0.9,z:0.0), radius:0.0, color:Vector3D(x: 3.0,y: 3.0,z: 3.0), material:Material.light)
            
            scene?.wallColors[0] = Vector3D(x: 0.75, y: 0.00, z: 0.00);
            scene?.wallColors[1] = Vector3D(x: 0.00, y: 0.75, z: 0.00);
            scene?.wallColors[2] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene?.wallColors[3] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene?.wallColors[4] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            scene?.wallColors[5] = Vector3D(x: 0.75, y: 0.75, z: 0.75);
            
            scene?.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene?.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 3){
            //Primary Colors
            scene?.addSphere(Sphere(position: Vector3D(x: 0.3, y:-0.7, z:-0.5),radius:0.3, color:Vector3D(x: 0.25, y: 0.25, z: 1.0), material: Material.diffuse))
            scene?.addSphere(Sphere(position: Vector3D(x: 0.0, y:-0.7, z:0.0),radius:0.3, color:Vector3D(x: 0.25, y: 1.0, z: 0.25), material: Material.diffuse))
            scene?.addSphere(Sphere(position: Vector3D(x:-0.3, y:-0.7, z:0.5),radius:0.3, color:Vector3D(x: 1.0, y: 0.25, z:0.25), material: Material.diffuse))
            scene?.light = Sphere(position:Vector3D(x:0.0,y:0.5,z:0.0), radius:0.0, color:Vector3D(x: 2.0,y: 2.0,z: 2.0), material:Material.light)
            
            scene?.wallColors[0] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene?.wallColors[1] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene?.wallColors[2] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene?.wallColors[3] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene?.wallColors[4] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            scene?.wallColors[5] = Vector3D(x: 0.80, y: 0.80, z: 0.80);
            
            scene?.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene?.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        } else if (sceneIndex == 4){
            //Escher
            scene?.addSphere(Sphere(position: Vector3D(x: 0.0, y: -0.3, z:-0.3), radius:0.7, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.specular))
            scene?.addSphere(Sphere(position: Vector3D(x: -0.5, y: 0.6, z:0.7), radius:0.2, color:Vector3D(x: 1.0, y: 1.0, z: 1.0), material: Material.diffuse))
            scene?.addSphere(Sphere(position: Vector3D(x: 0.4, y:-0.6, z:0.6), radius:0.2, color:Vector3D(x: 0.5, y: 0.5, z:0.5), material: Material.dielectric))
            scene?.light = Sphere(position:Vector3D(x:0.0,y:0.0,z:0.95), radius:0.0, color:Vector3D(x: 1.5,y: 1.5,z: 1.5), material:Material.light)
            
            scene?.wallColors[0] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene?.wallColors[1] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene?.wallColors[2] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene?.wallColors[3] = Vector3D(x: 0.35, y: 0.35, z: 0.35);
            scene?.wallColors[4] = Vector3D(x: 1.0, y: 1.0, z: 1.0);
            scene?.wallColors[5] = Vector3D(x: 1.0, y: 1.0, z: 1.0);
            
            scene?.camera.cameraPosition = Vector3D(x:0.0, y:0.0, z:3.0)
            scene?.camera.cameraUp = Vector3D(x:0.0, y:1.0, z:0.0)
        }
    }
}
