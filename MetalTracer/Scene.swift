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
    var light:Sphere = Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.LIGHT)
    var spheres:[Sphere] = [
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
        Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE)
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
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE),
            Sphere(position: Vector3D(x: 0.0, y: 0.0, z: 0.0), radius: 0.0, color: Vector3D(x:0.0, y:0.0, z:0.0), material: Material.DIFFUSE)
        ];
        sphereCount = 0
    }
    
    func resetBuffer(){
        sphereData = [];
        sphereData.append(light);
        for sphere:Sphere in spheres{
            sphereData.append(sphere);
        }
        sphereBuffer = context.device.newBufferWithBytes(&sphereData, length: (sizeof(Sphere) + 3) * (spheres.count + 1), options:.CPUCacheModeDefaultCache);
        
        cameraData = [camera.cameraPosition, camera.cameraUp];
        cameraBuffer = context.device.newBufferWithBytes(&cameraData, length: sizeof(Vector3D) * 2, options:.CPUCacheModeDefaultCache);
        
        wallColorBuffer = context.device.newBufferWithBytes(&wallColors, length: sizeof(Vector3D) * 6, options:.CPUCacheModeDefaultCache);
        
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
        spheres[sphereCount] = sphere;
        sphereCount++;
        resetBuffer();
    }
    
    func deleteSphere(index:Int){
        
        for i in index...spheres.count - 2 {
            spheres[i] = spheres[i + 1]
        }
        sphereCount--;
        spheres[sphereCount].radius = 0.0
        
        
        resetBuffer();
    }
}