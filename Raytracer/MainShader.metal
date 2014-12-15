//
//  MainShader.metal
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define DBL_MAX    1.7976931348623157E+308

struct Ray{
    float3 origin;
    float3 direction;
};

struct Hit{
    float distance;
    Ray ray;
    float3 normal;
    float3 hitPosition;
    float4 color;
    bool didHit;
};

struct Sphere{
    float3 position;
    float radius;
    float4 color;
};

struct Plane{
    float3 position;
    float3 normal;
    float4 color;
};


struct Light{
    float3 center = float3(0.0,0.0,-1.0);
};

struct Camera{
    float3 eye = float3(0.0,0.0,-3.0);
    float3 lookAt = float3(0.0,0.0,1.0);
    float3 up = float3(0.0, 1.0, 0.0);
    float3 right = float3(1.0, 0.0, 0.0);
    float apertureSize = 0.0;
    float focalLength = 1.0;
};


Ray makeRay(float x, float y, float r1, float r2){
    Camera cam;
    float3 base = cam.right * x + cam.up * y;
    float3 centered = base - float3(cam.right.x/2.0, cam.up.y/2.0, 0.0);
    
    float3 U = cam.up * r1 * cam.apertureSize;
    float3 V = cam.right * r2 * cam.apertureSize;
    float3 UV = U+V;
    
    float3 origin = cam.eye + UV;
    float3 direction = normalize(((centered + cam.lookAt) * cam.focalLength) - UV);
    
    Ray outRay;
    outRay.origin = origin;
    outRay.direction = direction;
    return outRay;
}

Hit noHit(){
    Hit hit;
    hit.didHit = false;
    return hit;
}

Hit getHit(float maxT, float minT, Ray ray, float3 normal, float4 color){
    
    if (minT > 1.e-6 && minT < maxT){
        Hit hit;
        hit.distance = minT;
        hit.ray = ray;
        hit.normal = normal;
        hit.color = color;
        float3 hitpos = ray.origin + ray.direction * minT;
        hit.hitPosition = hitpos;
        hit.didHit = true;
        return hit;
    } else{
        return noHit();
    }
    
    
}

Hit planeIntersection(Plane p, Ray ray, float distance);
Hit planeIntersection(Plane p, Ray ray, float distance){
    float3 n = normalize(p.normal);
    float d = dot(n, p.position);
    
    float denom = dot(n, ray.direction);
    if (abs(denom) > 1.e-6) {
        float t = (d - dot(n, ray.origin)) / denom;
        return getHit(distance, t, ray, p.normal, p.color);
    }
    return noHit();
}


Hit sphereIntersection(Sphere s, Ray ray, float distance);
Hit sphereIntersection(Sphere s, Ray ray, float distance){
    float3 v = s.position - ray.origin;
    float b = dot(v, ray.direction);
    float discriminant = b * b - dot(v, v) + s.radius * s.radius;
    if (discriminant < 0) {
        return noHit();
    }
    float d = sqrt(discriminant);
    float tFar = b + d;
    float eps = 1e-4;
    if (tFar <= eps) {
        return noHit();
    }
    float tNear = b - d;
    
    if (tNear <= eps) {
        float3 hitpos = ray.origin + ray.direction * tFar;
        float3 norm = (hitpos - s.position);
        return getHit(distance, tFar, ray, norm, s.color);
    } else{
        float3 hitpos = ray.origin + ray.direction * tNear;
        float3 norm = (hitpos - s.position);
        return getHit(distance, tNear, ray, norm, s.color);
    }
}

float4 getLighting(Hit hit){
    Light l;
    float3 normal = normalize(hit.normal);
    float3 lightDirection = l.center - hit.hitPosition;
    float cosphi = dot(normal, lightDirection);
    return float4(1.0,1.0,1.0,1.0) * cosphi * hit.color;
}

static constant struct Sphere spheres[] = {
    {float3(0.5,0.0,0.0), 0.2, float4(0.0,0.0,1.0,1.0)},
    {float3(-0.5,0.0,0.0), 0.2, float4(0.0,1.0,0.0,1.0)}
};

static constant struct Plane planes[] = {
    {float3(-1.0,0.0,0.0), float3(1.0,0.0,0.0), float4(1.0,0.0,0.0,1.0)},
    {float3(1.0,0.0,0.0), float3(-1.0,0.0,0.0), float4(0.0,1.0,0.0,1.0)},
    {float3(0.0,-1.0,0.0), float3(0.0,1.0,0.0), float4(1.0,1.0,1.0,1.0)},
    {float3(0.0,1.0,0.0), float3(0.0,-1.0,0.0), float4(1.0,1.0,1.0,1.0)},
    {float3(0.0,0.0,-4.0), float3(0.0,0.0,4.0), float4(1.0,1.0,1.0,1.0)},
    {float3(0.0,0.0,2.0), float3(0.0,0.0,-2.0), float4(1.0,1.0,1.0,1.0)}
};

static constant float sphereCount = 2;
static constant float planeCount = 6;

kernel void pathtrace(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]){
    
    uint2 textureIndex(gid.x, gid.y);
    float4 inColor = inTexture.read(textureIndex).rgba;
    
    float xResolution = 500.0;
    float yResolution = 500.0;
    
    float dx = 1.0 / xResolution;
    float xmin = 0.0;
    float dy = 1.0 / yResolution;
    float ymin = 0.0;
    float x = xmin + gid.x * dx;
    float y = ymin + gid.y * dy;
    
    
    Ray r = makeRay(x,y, 0.0, 0.0);
    
    Hit h;
    h.distance = DBL_MAX;
    
    for (int i=0; i<planeCount; i++){
        Plane p = planes[i];
        Hit hit = planeIntersection(p, r, h.distance);
        if (hit.didHit){
            h = hit;
        }
    }
    
    for (int i=0; i<sphereCount; i++){
        Sphere s = spheres[i];
        Hit hit = sphereIntersection(s, r, h.distance);
        if (hit.didHit){
            h = hit;
        }
    }
    
    if (h.didHit){
        outTexture.write(getLighting(h), gid);
    } else{
        outTexture.write(float4(0.0,0.0,0.0,0.0), gid);
    }
    
    
    
    /*Plane p;
    Hit h1 = planeIntersection(p, r, 10000.0);
    if (h1.didHit){
        outTexture.write(getLighting(h, s.color), gid);
    }
    else{
        outTexture.write(float4(1.0,1.0,1.0,1.0), gid);
    }*/
    
}
