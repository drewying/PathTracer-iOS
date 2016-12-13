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
    var light:Sphere = Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.light)
    var spheres:[Sphere] = [
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse)
    ]
            
    var wallColors:[Vector3D] = [
        Vector3D(x: 0.0, y: 0.0, z: 0.0),
        Vector3D(x: 0.0, y: 0.0, z: 0.0),
        Vector3D(x: 0.0, y: 0.0, z: 0.0),
        Vector3D(x: 0.0, y: 0.0, z: 0.0),
        Vector3D(x: 0.0, y: 0.0, z: 0.0),
        Vector3D(x: 0.0, y: 0.0, z: 0.0)
    ]
    
    var context:MetalContext;
    
    var sphereBuffer:MTLBuffer!
    var cameraBuffer:MTLBuffer!
    var wallColorBuffer:MTLBuffer!
    
    var sphereData:[Sphere] = []
    var cameraData:[Vector3D] = []
    
    var sphereCount:Int = 0
    
    init(camera:Camera, context:MetalContext){
        self.camera = camera
        self.context = context
    }
    
    func clearSpheres(){
        spheres = [
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.diffuse)
        ];
        sphereCount = 0
    }
    
    func resetBuffer(){
        sphereData = [];
        sphereData.append(light);
        for sphere:Sphere in spheres{
            sphereData.append(sphere);
        }
        sphereBuffer = context.device.makeBuffer(bytes: &sphereData, length: (MemoryLayout<Sphere>.size + 3) * (spheres.count + 1), options:MTLResourceOptions());
        
        cameraData = [camera.cameraPosition, camera.cameraUp];
        cameraBuffer = context.device.makeBuffer(bytes: &cameraData, length: MemoryLayout<Vector3D>.size * 2, options:MTLResourceOptions());
        
        wallColorBuffer = context.device.makeBuffer(bytes: &wallColors, length: MemoryLayout<Vector3D>.size * 6, options:MTLResourceOptions());
        
    }
    
    func getClosestHit(_ ray:Ray) -> Int{
        for i in (0...spheres.count-1){
            if (spheres[i].getBounds().intersectsWithRay(ray)){
                return i;
            }
        }
        return -1;
    }
    
    func addSphere(_ sphere:Sphere){
        spheres[sphereCount] = sphere;
        sphereCount += 1;
        resetBuffer();
    }
    
    func deleteSphere(_ index:Int){
        
        for i in index...spheres.count - 2 {
            spheres[i] = spheres[i + 1]
        }
        sphereCount -= 1;
        spheres[sphereCount].radius = 0.0
        
        
        resetBuffer();
    }
}
