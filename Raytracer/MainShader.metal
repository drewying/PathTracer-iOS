//
//  MainShader.metal
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define DBL_MAX 1.7976931348623157E+308
#define INT_MAX 2147483647
#define UINT_MAX 4294967295
#define M_PI 3.14159265358979323846

#define EPSILON 1.e-6

static constant int sphereCount = 2;
static constant int planeCount = 6;
static constant int triangleCount = 2;
static constant int sampleCount = 10;

struct Ray{
    float3 origin;
    float3 direction;
};

struct Hit{
    float distance;
    Ray ray;
    float3 normal;
    float3 hitPosition;
    float3 color;
    float3 emmitColor;
    bool didHit;
};

struct Sphere{
    float3 position;
    float radius;
    float3 color;
    float3 emmitColor;
};

struct Plane{
    float3 position;
    float3 normal;
    float3 color;
    float3 emmitColor;
};

struct Triangle{
    float3 p0;
    float3 p1;
    float3 p2;
    float3 color;
    float3 emmitColor;
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

Hit getHit(float maxT, float minT, Ray ray, float3 normal, float3 color, float3 emmitColor){
    
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

Hit triangleIntersection(Triangle t, Ray ray, float distance){
    float tVal;
    
    float A = t.p0.x - t.p1.x;
    float B = t.p0.y - t.p1.y;
    float C = t.p0.z - t.p1.z;
    
    float D = t.p0.x - t.p2.x;
    float E = t.p0.y - t.p2.y;
    float F = t.p0.z - t.p2.z;
    
    float G = ray.direction.x;
    float H = ray.direction.y;
    float I = ray.direction.z;
    
    float J = t.p0.x - ray.origin.x;
    float K = t.p0.y - ray.origin.y;
    float L = t.p0.z - ray.origin.z;
    
    float EIHF = E*I-H*F;
    float GFDI = G*F-D*I;
    float DHEG = D*H-E*G;
    
    float denom = (A*EIHF + B*GFDI + C*DHEG);
    
    float beta = (J*EIHF + K*GFDI + L*DHEG) / denom;
    
    if (beta <= 0.0f || beta >= 1.0f){
        return noHit();
    }
    
    float AKJB = A*K-J*B;
    float JCAL = J*C-A*L;
    float BLKC = B*L-K*C;
    
    float gamma = (I*AKJB + H*JCAL + G*BLKC)/denom;
    
    if (gamma <= 0.0f || beta + gamma >= 1.0f){
        return noHit();
    }
    
    tVal = -(F*AKJB + E*JCAL + D*BLKC) / denom;
    
    if (tVal > 0){
        float3 normal = cross((t.p1-t.p2), (t.p2-t.p0));
        return getHit(distance, tVal, ray, normal, t.color, t.emmitColor);
    } else{
        return noHit();
    }
}

static constant struct Sphere spheres[] = {
    {float3(0.2,-0.7,0.7), 0.3, float3(0.0,0.0,1.0), float3(0.0,0.0,0.0)},
    {float3(-0.2,-0.7,-0.7), 0.3, float3(1.0,0.0,0.0), float3(0.0,0.0,0.0)}
};

static constant struct Plane planes[] = {
    {float3(-1.0,0.0,0.0), float3(1.0,0.0,0.0), float3(1.0,0.0,0.0), float3(0.0,0.0,0.0)},
    {float3(1.0,0.0,0.0), float3(-1.0,0.0,0.0), float3(0.0,1.0,0.0), float3(0.0,0.0,0.0)},
    {float3(0.0,-1.0,0.0), float3(0.0,1.0,0.0), float3(0.75,0.75,0.75), float3(0.0,0.0,0.0)},
    {float3(0.0,1.0,0.0), float3(0.0,-1.0,0.0), float3(0.75,0.75,0.75), float3(0.0,0.0,0.0)},
    {float3(0.0,0.0,-5.0), float3(0.0,0.0,5.0), float3(0.75,0.75,0.75), float3(0.0,0.0,0.0)},
    {float3(0.0,0.0,2.0), float3(0.0,0.0,-2.0), float3(0.75,0.75,0.75), float3(0.0,0.0,0.0)}
};

static constant struct Triangle triangles[] = {
    {float3(-0.5,0.99,0.5), float3(0.5,0.99,0.5), float3(-0.5,0.99,-0.5), float3(1.0,1.0,1.0), float3(5.0,5.0,5.0)},
    {float3(0.5,0.99,0.5), float3(0.5,0.99,-0.5), float3(-0.5,0.99,-0.5), float3(1.0,1.0,1.0), float3(5.0,5.0,5.0)}
};

float rand(thread uint *seed)
{
    uint long_max = 4294967295;
    float float_max = 4294967295.0;
    uint mult = 62089911;
    uint next = *seed;
    next = mult * next;
    *seed = next;
    return (float)(next % long_max) / float_max;
}



Ray bounce(Hit h, thread uint *seed){
    float pi = M_PI;
    float phi = 2 * pi * (float)rand(seed);
    float r = sqrt(rand(seed));
    float x = r * cos(phi);
    float y = r * sin(phi);
    float z = sqrt(1 - x * x - y * y);
    float3 randomVector = normalize(float3(x,y,z));

    float3 normal = h.normal;
    
    // if the point is in the wrong hemisphere, mirror it
    if (dot(normal, randomVector) < 0.0) {
        randomVector *= -1.0;
    }
    
    Ray outRay;
    outRay.origin = h.hitPosition;
    outRay.direction = randomVector;
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
    
    for (int i=0; i<triangleCount; i++){
        Triangle t = triangles[i];
        Hit hit = triangleIntersection(t, r, h.distance);
        if (hit.didHit){
            h = hit;
        }
    }
    
    return h;
}




float4 pathTrace(Ray r, thread uint *seed){
    
    float3 reflectColor = float3(1.0,1.0,1.0);
    for (int i=0; i < sampleCount; i++){
        Hit h = getClosestHit(r);
        if (!h.didHit){
            return float4(0.0,0.0,0.0,1.0);
        }
        
        reflectColor = reflectColor * h.color;
        
        if (h.emmitColor.r > 0.0 || h.emmitColor.g > 0.0 || h.emmitColor.b > 0.0){
            return float4(reflectColor * h.emmitColor,1.0);
        }
        
        r = bounce(h, seed);
    }
    
    return float4(0.0,0.0,0.0,1.0);
}

kernel void pathtrace(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]], device uint *params [[buffer(0)]]){
    
    uint timeSinceStart = params[0];
    uint sampleNumber = params[1];
    
    //Set the random seed;
    uint initialSeed = timeSinceStart * (sampleNumber * 500) * (gid.x + 500 * (gid.y-1)); //gid.x * gid.y;
    thread uint *seed = &initialSeed;
    
    //Get the inColor
    uint2 textureIndex(gid.x, gid.y);
    float4 inColor = inTexture.read(textureIndex).rgba;
    
    float xResolution = 500.0;
    float yResolution = 500.0;
    
    float dx = 1.0 / xResolution;
    float xmin = 0.0;
    float dy = 1.0 / yResolution;
    float ymin = 0.0;
    float x = xmin + gid.x  * dx;
    float y = ymin + gid.y  * dy;
    
    
    
    float xOffset = rand(seed)/(xResolution);
    float yOffset = rand(seed)/(yResolution);
    
    Ray r = makeRay(x + xOffset,y + yOffset, 0.0, 0.0);
    

    
    
    float4 outColor = pathTrace(r, seed);
    
    
    
    outTexture.write(mix(outColor, inColor, float(sampleNumber)/float(sampleNumber + 1)), gid);
    
    
}
