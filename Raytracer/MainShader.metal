//
//  MainShader.metal
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

#include <metal_stdlib>
#include "Ray.h"

using namespace metal;

struct Hit{
    float distance;
    Ray ray;
    float3 normal;
    float3 hitPosition;
    bool didHit;
};

Hit getHit(float distance, Ray ray, float3 normal){
    Hit hit;
    hit.distance = distance;
    hit.ray = ray;
    hit.normal = normal;
    float3 hitpos = ray.origin + ray.direction * distance;
    hit.hitPosition = hitpos;
    hit.didHit = true;
    return hit;
}

Hit noHit();
Hit noHit(){
    Hit hit;
    hit.didHit = false;
    return hit;
}

struct Sphere{
    float3 position = float3(0.0,0.0,0.0);
    float radius = 0.1;
    float4 color = float4(1.0,0.0,0.0,1.0);
};

struct Plane{
    float3 position = float3(-1.0,0.0,0.0);
    float3 normal = float3(1.0,0.0,0.0);
    float4 color = float4(0.0,1.0,0.0,1.0);
};


struct Light{
    float3 center = float3(0.0,-0.5,-0.5);
};

struct Camera{
    float3 eye = float3(0.0,0.0,-1.0);
    float3 lookAt = float3(0.0,0.0,1.0);
    float3 up = float3(0.0, 1.0, 0.0);
    float3 right = float3(1.0, 0.0, 0.0);
    float apertureSize = 0.0;
    float focalLength = 1.0;
};

Ray makeRay(float x, float y, float r1, float r2);
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

Hit planeIntersection(Plane p, Ray ray, float distance);
Hit planeIntersection(Plane p, Ray ray, float distance){
    float3 n = normalize(p.normal);
    float d = dot(n, p.position);
    
    float denom = dot(n, ray.direction);
    if (denom > 1.e-6) {
        float t = (d - dot(n, ray.origin)) / denom;
        return getHit(t, ray, p.normal);
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
        return getHit(tFar, ray, norm);
    } else{
        float3 hitpos = ray.origin + ray.direction * tNear;
        float3 norm = (hitpos - s.position);
        return getHit(tNear, ray, norm);
    }
}

float4 getLighting(Hit hit, float4 color){
    Light l;
    float3 normal = normalize(hit.normal);
    float3 lightDirection = l.center - hit.hitPosition;
    float cosphi = dot(normal, lightDirection);
    return float4(1.0,1.0,1.0,1.0) * cosphi * color;
}

float rand(float2 co){
    return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

vertex float4 basic_vertex(const device packed_float3* vertex_array [[ buffer(0) ]],unsigned int vid [[ vertex_id ]]) {
    return float4(vertex_array[vid], 1.0);
}

fragment float4 basic_fragment(const device float* array [[buffer(0)]], float4 position [[position]]) {
    
    return float4(array[0], array[0], array[0], 1.0);
    
    float xResolution = 375.0;
    float yResolution = 667.0;
    
    float dx = 1.0 / xResolution;
    float xmin = 0.0;
    float dy = 1.0 / yResolution;
    float ymin = 0.0;
    float x = xmin + position.x * dx;
    float y = ymin + position.y * dy;
    
    
    Ray r = makeRay(x,y, 0.0, 0.0);
    
    Sphere s;
    Hit h = sphereIntersection(s, r, 10000.0);
    if (h.didHit){
        return getLighting(h, s.color);
    }
    
    Plane p;
    Hit h1 = planeIntersection(p, r, 10000.0);
    if (h1.didHit){
        return getLighting(h1, p.color);
    }
    
    return float4(array[0], array[0], array[0], 1.0);
    
}

