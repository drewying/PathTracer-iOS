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
#define M_PI 3.14159265358979323846
#define EPSILON 1.e-6

static constant int sphereCount = 2;
static constant int planeCount = 6;
static constant int sampleCount = 5;

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
    float4 emmitColor;
    bool didHit;
};

struct Sphere{
    float3 position;
    float radius;
    float4 color;
    float4 emmitColor;
};

struct Plane{
    float3 position;
    float3 normal;
    float4 color;
    float4 emmitColor;
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
    hit.distance = DBL_MAX;
    return hit;
}

Hit getHit(float maxT, float minT, Ray ray, float3 normal, float4 color, float4 emmitColor){
    
    if (minT > EPSILON && minT < maxT){
        Hit hit;
        hit.distance = minT;
        hit.ray = ray;
        hit.normal = normal;
        hit.color = color;
        hit.emmitColor = emmitColor;
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
    if (abs(denom) > EPSILON) {
        float t = (d - dot(n, ray.origin)) / denom;
        return getHit(distance, t, ray, p.normal, p.color, p.emmitColor);
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
    if (tFar <= EPSILON) {
        return noHit();
    }
    float tNear = b - d;
    
    if (tNear <= EPSILON) {
        float3 hitpos = ray.origin + ray.direction * tFar;
        float3 norm = (hitpos - s.position);
        return getHit(distance, tFar, ray, norm, s.color, s.emmitColor);
    } else{
        float3 hitpos = ray.origin + ray.direction * tNear;
        float3 norm = (hitpos - s.position);
        return getHit(distance, tNear, ray, norm, s.color, s.emmitColor);
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
    {float3(0.0,-0.7,0.0), 0.3, float4(0.0,0.0,1.0,1.0), float4(0.0,0.0,0.0,1.0)},
    {float3(0.0,0.0,-4.0), 0.75, float4(0.0,1.0,0.0,1.0), float4(20.0,20.0,20.0,1.0)}
};

static constant struct Plane planes[] = {
    {float3(-1.0,0.0,0.0), float3(1.0,0.0,0.0), float4(1.0,0.0,0.0,1.0), float4(0.0,0.0,0.0,1.0)},
    {float3(1.0,0.0,0.0), float3(-1.0,0.0,0.0), float4(0.0,1.0,0.0,1.0), float4(0.0,0.0,0.0,1.0)},
    {float3(0.0,-1.0,0.0), float3(0.0,1.0,0.0), float4(1.0,1.0,1.0,1.0), float4(0.0,0.0,0.0,1.0)},
    {float3(0.0,1.0,0.0), float3(0.0,-1.0,0.0), float4(1.0,1.0,1.0,1.0), float4(0.0,0.0,0.0,1.0)},
    {float3(0.0,0.0,-5.0), float3(0.0,0.0,5.0), float4(1.0,1.0,1.0,1.0), float4(0.0,0.0,0.0,1.0)},
    {float3(0.0,0.0,2.0), float3(0.0,0.0,-2.0), float4(1.0,1.0,1.0,1.0), float4(0.0,0.0,0.0,1.0)}
};

float4 monteCarloIntegrate(float4 currentSample, float4 newSample, int sampleNumber){
    currentSample -= currentSample / sampleNumber;
    currentSample += newSample / sampleNumber;
    return currentSample;
}


float random(float3 scale, float seed, uint2 gid) {
    float3 temp = float3(gid.x, gid.y, 0.5);
    return fract(sin(dot(temp.xyz + seed, scale)) * 43758.5453 + seed);
}

float3 uniformlyRandomDirection(float seed, uint2 gid) {
    float u = random(float3(12.9898, 78.233, 151.7182), seed, gid);
    float v = random(float3(63.7264, 10.873, 623.6736), seed, gid);
    float z = 1.0 - 2.0 * u;
    float r = sqrt(1.0 - z * z);
    float angle = 6.283185307179586 * v;
    return float3(r * cos(angle), r * sin(angle), z);
}

float3 uniformlyRandomVector(float seed, uint2 gid)
{
    return uniformlyRandomDirection(seed, gid) *  (random(float3(36.7539, 50.3658, 306.2759), seed, gid));
}

Ray bounce(Hit h, float seed, uint2 gid){
    Ray outRay;
    outRay.origin = h.hitPosition;
    outRay.direction = uniformlyRandomVector(seed, gid);
    return outRay;
}



Hit getClosestHit(Ray r){
    Hit h = noHit();
    
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
    
    return h;
}


/*float4 pathTrace(Ray r, float seed, uint2 gid){
    float4 finalColor = float4(0.0,0.0,0.0,1.0);
    float4 reflectColor = float4(1.0,1.0,1.0,1.0);
    for (int i=0; i < sampleCount; i++){
        Hit h = getClosestHit(r);
        if (!h.didHit){
            return float4(0.0,0.0,0.0,1.0);
        }
        if (h.emmitColor.r > 0.0 || h.emmitColor.g > 0.0 || h.emmitColor.b > 0.0){
            return finalColor * h.emmitColor;
        }
        
        reflectColor = reflectColor * h.color;
        finalColor += (h.color * reflectColor);
        r = bounce(h, seed, gid);
    }
    
    return float4(0.0,0.0,0.0,1.0);
}*/


float4 pathTrace(Ray r, float seed, uint2 gid){
    float4 finalColor = float4(0.0,0.0,0.0,1.0);
    float4 reflectColor = float4(1.0,1.0,1.0,1.0);
    for (int i=0; i < sampleCount; i++){
        Hit h = getClosestHit(r);
        if (!h.didHit){
            return float4(0.0,0.0,0.0,1.0);
        }
        if (h.emmitColor.r > 0.0 || h.emmitColor.g > 0.0 || h.emmitColor.b > 0.0){
            return finalColor * h.emmitColor;
        }
        
        reflectColor = reflectColor * h.color;
        finalColor += reflectColor;
        r = bounce(h, seed, gid);
        seed *= seed * seed;
    }
    
    return float4(0.0,0.0,0.0,1.0);
}

kernel void pathtrace(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]], device float *params [[buffer(0)]]){
    
    //Get the inColor
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
    
    //Set the random seed;
    float sampleNum = params[0];
    float seed = params[1];
    float4 c = pathTrace(r, seed, gid);
    outTexture.write(monteCarloIntegrate(inColor, c, sampleNum), gid);
    //outTexture.write(c + inColor, gid);
    
}
