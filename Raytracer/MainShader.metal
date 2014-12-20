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
#define UNSIGNED_INT_MAX 4294967295
#define M_PI 3.14159265358979323846

#define EPSILON 1.e-6

static constant int sphereCount = 3;
static constant int planeCount = 6;
static constant int triangleCount = 2;
static constant int bounceCount = 10;

enum Material { DIFFUSE, SPECULAR, DIELECTRIC, LIGHT};

struct Ray{
    float3 origin;
    float3 direction;
};

struct Hit{
    float distance;
    Ray ray;
    float3 normal;
    float3 hitPosition;
    Material material;
    float3 color;
    bool didHit;
};

struct Sphere{
    float3 position;
    float radius;
    float3 color;
    Material material;
};

struct Plane{
    float3 position;
    float3 normal;
    float3 color;
    Material material;
};

struct Box{
    float3 min;
    float3 max;
    float3 color;
    Material material;
};



struct Triangle{
    float3 p0;
    float3 p1;
    float3 p2;
    float3 color;
    Material material;
};

struct Camera{
    float3 eye;
    float3 lookAt = float3(0.0,0.0,0.001);
    float3 up = float3(0.0, 1.0, 0.0);
    float3 right = float3(1.0, 0.0, 0.0);
    float apertureSize = 0.0;
    float focalLength = 1.0;
};

Ray makeRay(float x, float y, float r1, float r2, constant float3 *floatParams){
    Camera cam;
    cam.eye = floatParams[0];
    float3 base = cam.right * x + cam.up * y;
    float3 centered = base - float3(cam.right.x/2.0, cam.up.y/2.0, 0.0);
    
    float3 U = cam.up * r1 * cam.apertureSize;
    float3 V = cam.right * r2 * cam.apertureSize;
    float3 UV = U+V;
    
    float3 origin = cam.eye + UV;
    float3 direction = normalize(((centered + normalize(cam.lookAt)) * cam.focalLength) - UV);
    
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

Hit getHit(float maxT, float minT, Ray ray, float3 normal, float3 color, Material material){
    
    if (minT > EPSILON && minT < maxT){
        Hit hit;
        hit.distance = minT;
        hit.ray = ray;
        hit.normal = normal;
        hit.color = color;
        hit.material = material;
        float3 hitpos = ray.origin + ray.direction * minT;
        hit.hitPosition = hitpos;
        hit.didHit = true;
        return hit;
    } else{
        return noHit();
    }
    
    
}

Hit boxIntersection(Box b, Ray ray, float distance){
    float3 tMin = (b.min - ray.origin) / ray.direction;
    float3 tMax = (b.max - ray.origin) / ray.direction;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);

    float t;
    if (tNear <= EPSILON) {
        t = tNear;
    } else{
        t = tFar;
    }
    
    float3 hit = ray.origin + ray.direction * t;
    
    //Get Normal
    float3 normal;
    
    if(hit.x < b.min.x + 0.0001) normal = float3(-1.0, 0.0, 0.0);
    else if(hit.x > b.max.x - 0.0001) normal = float3(1.0, 0.0, 0.0);
    else if(hit.y < b.min.y + 0.0001) normal = float3(0.0, -1.0, 0.0);
    else if(hit.y > b.max.y - 0.0001) normal = float3(0.0, 1.0, 0.0);
    else if(hit.z < b.min.z + 0.0001) normal = float3(0.0, 0.0, -1.0);
    else normal = float3(0.0, 0.0, 1.0);

    return getHit(distance, t, ray, normal, b.color, b.material);
}

Hit planeIntersection(Plane p, Ray ray, float distance);
Hit planeIntersection(Plane p, Ray ray, float distance){
    float3 n = normalize(p.normal);
    float d = dot(n, p.position);
    
    float denom = dot(n, ray.direction);
    if (abs(denom) > EPSILON) {
        float t = (d - dot(n, ray.origin)) / denom;
        return getHit(distance, t, ray, p.normal, p.color, p.material);
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
        return getHit(distance, tFar, ray, norm, s.color, s.material);
    } else{
        float3 hitpos = ray.origin + ray.direction * tNear;
        float3 norm = (hitpos - s.position);
        return getHit(distance, tNear, ray, norm, s.color, s.material);
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
        return getHit(distance, tVal, ray, normal, t.color, t.material);
    } else{
        return noHit();
    }
}

static constant struct Sphere spheres[] = {
    {float3(0.0,-0.75,0.0), 0.25, float3(0.5,0.5,0.5), DIFFUSE},
    {float3(0.5,-0.25,0.0), 0.25, float3(1.0,1.0,1.0), SPECULAR},
    {float3(-0.5,0.25,0.0), 0.25, float3(0.5,0.5,0.5), DIFFUSE}
};

static constant struct Plane planes[] = {
    {float3(-1.0,0.0,0.0), float3(1.0,0.0,0.0), float3(1.0,0.0,0.0), DIFFUSE},
    {float3(1.0,0.0,0.0), float3(-1.0,0.0,0.0), float3(0.0,1.0,0.0), DIFFUSE},
    {float3(0.0,-1.0,0.0), float3(0.0,1.0,0.0), float3(0.75,0.75,0.75), DIFFUSE},
    {float3(0.0,1.0,0.0), float3(0.0,-1.0,0.0), float3(0.75,0.75,0.75), DIFFUSE},
    {float3(0.0,0.0,-5.0), float3(0.0,0.0,5.0), float3(0.75,0.75,0.75), DIFFUSE},
    {float3(0.0,0.0,2.0), float3(0.0,0.0,-2.0), float3(0.75,0.75,0.75), DIFFUSE}
};

static constant struct Triangle triangles[] = {
    {float3(-0.5,0.99,0.5), float3(0.5,0.99,0.5), float3(-0.5,0.99,-0.5), float3(7.0,7.0,7.0), LIGHT},
    {float3(0.5,0.99,0.5), float3(0.5,0.99,-0.5), float3(-0.5,0.99,-0.5), float3(7.0,7.0,7.0), LIGHT}
};

/*float rand(thread uint *seed)
{
    //From Realistic Ray Tracing
    uint long_max = 4294967295;
    float float_max = 4294967295.0;
    uint mult = 62089911;
    uint next = *seed;
    next = mult * next;
    *seed = next;
    float returnValue = (float)(next % long_max) / float_max;
    
    return returnValue;
    
}*/

float rand(thread uint *seed)
{
    
    uint z1 = seed[0];
    uint z2 = seed[1];
    uint z3 = seed[2];
    uint z4 = seed[3];
    
    
    uint b;
    b  = ((z1 << 6) ^ z1) >> 13;
    z1 = ((z1 & 4294967294) << 18) ^ b;
    b  = ((z2 << 2) ^ z2) >> 27;
    z2 = ((z2 & 4294967288) << 2) ^ b;
    b  = ((z3 << 13) ^ z3) >> 21;
    z3 = ((z3 & 4294967280) << 7) ^ b;
    b  = ((z4 << 3) ^ z4) >> 12;
    z4 = ((z4 & 4294967168) << 13) ^ b;
    
    seed[0] = z1;
    seed[1] = z2;
    seed[2] = z3;
    seed[3] = z4;
    
    uint returnValue = (z1 ^ z2 ^ z3 ^ z4);
    return float(returnValue)/4294967295.0;
}

float3 uniformSampleDirection(thread uint *seed){
    float u1 = rand(seed);
    float u2 = rand(seed);
    float r = sqrt(1.0 - u1 * u2);
    float phi = 2 * M_PI * u2;
    float x = r * cos(phi);
    float y = r * sin(phi);
    float z = u1;
    
    return normalize(float3(x,y,z));
}


float3 cosineWeightedDirection(thread uint *seed){
    float u1 = rand(seed);
    float u2 = rand(seed);
    
    float r = sqrt(u1);
    float theta = 2 * M_PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(1.0 - u1);
    return normalize(float3(x,y,z));
}

Ray bounce(Hit h, thread uint *seed){
    
    float3 outVector;
    
    if (h.material == DIFFUSE){
        outVector = uniformSampleDirection(seed);
        //outVector = cosineWeightedDirection(seed);
        float3 normal = h.normal;
        
        // if the point is in the wrong hemisphere, mirror it
        if (dot(normal, outVector) < 0.0) {
            outVector *= -1.0;
        }
        
    } else if (h.material == SPECULAR){
        float3 normal = normalize(h.normal);
        float cosine = dot(h.ray.direction, normal);
        outVector = h.ray.direction - (2.0 * normal * cosine);
    }
    
    
    Ray outRay;
    outRay.origin = h.hitPosition;
    outRay.direction = outVector;
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




float4 tracePath(Ray r, thread uint *seed){
    
    float3 reflectColor = float3(1.0,1.0,1.0);
    for (int i=0; i < bounceCount; i++){
        Hit h = getClosestHit(r);
        if (!h.didHit){
            return float4(0.0,0.0,0.0,1.0);
        }
        
        reflectColor = reflectColor * h.color;
        
        if (h.material == LIGHT){
            return float4(reflectColor, 1.0);
        }
        
        r = bounce(h, seed);
    }
    
    return float4(0.0,0.0,0.0,1.0);
}

float4 monteCarloIntegrate(float4 currentSample, float4 newSample, uint sampleNumber){
    currentSample -= currentSample / (float)sampleNumber;
    currentSample += newSample / (float)sampleNumber;
    return currentSample;
}


kernel void pathtrace(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]], constant uint *params [[buffer(0)]], constant float3 *floatParams [[buffer(1)]]){
    
    uint timeSinceStart = params[0];
    uint sampleNumber = params[1];
    
    //Set the random seed;
    float gridNumber = fract(sin(dot(float2(gid.x, gid.y), float2(12.9898,78.233))) * 43758.5453);
    
    uint temp = uint(gridNumber * 4294967295.0);
    
    uint initialSeed[4];
    initialSeed[0] = timeSinceStart * temp;
    initialSeed[1] = timeSinceStart * temp;
    initialSeed[2] = timeSinceStart * temp;
    initialSeed[3] = timeSinceStart * temp;
    
    
    thread uint *seed = initialSeed;
    
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
    
    Ray r = makeRay(x + xOffset,y + yOffset, 0.0, 0.0, floatParams);
    
    float4 outColor = tracePath(r, seed);
    
    //outTexture.write(mix(outColor, inColor, float(sampleNumber)/float(sampleNumber + 1)), gid);
    outTexture.write(monteCarloIntegrate(inColor, outColor, sampleNumber),gid);
    //outTexture.write(outColor,gid);
}
