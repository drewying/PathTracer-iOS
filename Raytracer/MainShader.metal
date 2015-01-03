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

#define EPSILON 1.e-4

static constant int sphereCount = 5;
static constant int planeCount = 6;
static constant int triangleCount = 0;
static constant int bounceCount = 5;

enum Material { DIFFUSE = 0, SPECULAR = 1, DIELECTRIC = 2, TRANSPARENT = 3, LIGHT = 4};

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

struct PackedSphere{
    packed_float3 position;
    float radius;
    packed_float3 color;
    Material material;
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
    float3 lookAt = float3(0.0,0.0,1.0);
    float3 up = float3(0.0, 1.0, 0.0);
    float3 right = float3(1.0, 0.0, 0.0);
    float apertureSize = 0.0;
    float focalLength = 1.0;
};

struct RandomSeed{
    uint a;
    uint b;
    uint c;
    uint d;
};

inline Hit noHit(){
    Hit hit;
    hit.didHit = false;
    hit.distance = DBL_MAX;
    return hit;
}

inline Hit getHit(float maxT, float minT, Ray ray, float3 normal, float3 color, Material material){
    
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
    if (-denom > EPSILON) {
        float t = (d - dot(n, ray.origin)) / denom;
        return getHit(distance, t, ray, p.normal, p.color, p.material);
    }
    return noHit();
}

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

float rand(thread RandomSeed *seed)
{
    
    uint z1 = seed->a;
    uint z2 = seed->b;
    uint z3 = seed->c;
    uint z4 = seed->d;
    
    
    uint b;
    b  = ((z1 << 6) ^ z1) >> 13;
    z1 = ((z1 & 4294967294) << 18) ^ b;
    b  = ((z2 << 2) ^ z2) >> 27;
    z2 = ((z2 & 4294967288) << 2) ^ b;
    b  = ((z3 << 13) ^ z3) >> 21;
    z3 = ((z3 & 4294967280) << 7) ^ b;
    b  = ((z4 << 3) ^ z4) >> 12;
    z4 = ((z4 & 4294967168) << 13) ^ b;
    
    seed->a = z1;
    seed->b = z2;
    seed->c = z3;
    seed->d = z4;
    
    uint returnValue = (z1 ^ z2 ^ z3 ^ z4);
    return float(returnValue)/4294967295.0;
}

float3 uniformSampleDirection(thread RandomSeed *seed){
    float u1 = rand(seed);
    float u2 = rand(seed);
    
    float r = sqrt(1.0 - u1 * u2);
    float theta = 2 * M_PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = u1;
    
    return normalize(float3(x,y,z));
}

float3 bookSampleDirection(thread RandomSeed *seed){
    float u1 = rand(seed);
    float u2 = rand(seed);
    
    float r = sqrt(u1);
    float theta = 2 * M_PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(1.0 - x * x - y * y);
    return normalize(float3(x,y,z));
    
}


float3 cosineWeightedDirection(thread RandomSeed *seed){
    float u1 = rand(seed);
    float u2 = rand(seed);
    
    float r = sqrt(u1);
    float theta = 2 * M_PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(1.0 - u1);
    return normalize(float3(x,y,z));
}

Ray bounce(Hit h, thread RandomSeed *seed){
    
    float3 outVector;
    
    if (h.material == DIFFUSE){
        //outVector = uniformSampleDirection(seed);
        //outVector = cosineWeightedDirection(seed);
        outVector = bookSampleDirection(seed);
        float3 normal = h.normal;
        
        // if the point is in the wrong hemisphere, mirror it
        if (dot(normal, outVector) < 0.0) {
            outVector *= -1.0;
        }
        
    } else if (h.material == SPECULAR){
        outVector = reflect(h.ray.direction, normalize(h.normal));
    } else if (h.material == DIELECTRIC){
        float3 normal = normalize(h.normal);
        float3 incident = h.ray.direction;
        float3 nl = dot(normal, incident) < 0 ? normal : normal * -1.0;
        float into = dot(nl, normal);
        
        float refractiveIndexAir = 1;
        float refractiveIndexGlass = 1.5;
        float refractiveIndexRatio = pow(refractiveIndexAir / refractiveIndexGlass, (into > 0) - (into < 0));
        float cosI = dot(incident,nl);
        float cos2t = 1 - refractiveIndexRatio * refractiveIndexRatio * (1 - cosI * cosI);
        if (cos2t < 0) {
            //Reflect
            return Ray{h.hitPosition, incident - normal * (2 * dot(incident, normal))};
        }
        
        float3 refractedDirection = incident * (refractiveIndexRatio) - (normal * (((into > 0) - (into < 0) * (cosI * refractiveIndexRatio + sqrt(cos2t)))));
        refractedDirection = normalize(refractedDirection);
        
        float a = refractiveIndexGlass - refractiveIndexAir;
        float b = refractiveIndexGlass + refractiveIndexAir;
        float R0 = a * a / (b * b);
        float c = 1 - (into > 0 ? -cosI : dot(refractedDirection,normal));
        float Re = R0 + (1 - R0) * pow(c, 5);
        float P = 0.1 + 0.5 * Re;
        //Prob check?
        if (rand(seed) < P){
            return Ray{h.hitPosition, incident - normal * (2 * dot(incident, normal))};
        } else{
            return Ray{h.hitPosition, refractedDirection};
        }
    } else if (h.material == TRANSPARENT){
        outVector = h.ray.direction;
    }
    
    
    Ray outRay;
    outRay.origin = h.hitPosition;
    outRay.direction = outVector;
    return outRay;
}

static constant struct Plane planes[] = {
    {float3(-1.0,0.0,0.0), float3(1.0,0.0,0.0), float3(0.75,0.0,0.0), DIFFUSE},
    {float3(1.0,0.0,0.0), float3(-1.0,0.0,0.0), float3(0.0,0.75,0.0), DIFFUSE},
    {float3(0.0,-1.0,0.0), float3(0.0,1.0,0.0), float3(0.75,0.75,0.75), DIFFUSE},
    {float3(0.0,1.0,0.0), float3(0.0,-1.0,0.0), float3(0.75,0.75,0.75), DIFFUSE},
    {float3(0.0,0.0,-1.0), float3(0.0,0.0,1.0), float3(0.75,0.75,0.75), DIFFUSE},
    {float3(0.0,0.0,1.0), float3(0.0,0.0,-1.0), float3(0.75,0.75,0.75), DIFFUSE}
};

static constant struct Triangle triangles[] = {
    {float3(-0.5,0.99999,0.5), float3(-0.5,0.99999,-0.5), float3(0.5,0.99999,0.5), float3(1.0,1.0,1.0), DIFFUSE},
    {float3( 0.5,0.99999,0.5), float3(-0.5,0.99999,-0.5), float3(0.5,0.99999,-0.5), float3(1.0,1.0,1.0), DIFFUSE}
};

static constant float3 light = float3(0.25,0.75,0.5);

Hit getClosestHit(Ray r, Sphere spheres[]){
    Hit h = noHit();
    
    for (int i=0; i<planeCount; i++){
        Plane p = planes[i];
        Hit hit = planeIntersection(p, r, h.distance);
        if (hit.didHit){
            h = hit;
        }
    }
    
    for (int i=0; i<sphereCount; i++){
        //Unpack
        Hit hit = sphereIntersection(spheres[i], r, h.distance);
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

float3 getLight(thread RandomSeed *seed){
    float lightx = (rand(seed) * 0.1) - 0.05;
    float lighty = (rand(seed) * 0.1) - 0.05;
    float lightz = (rand(seed) * 0.1) - 0.05;
    return float3(light.x + lightx, light.y + lighty, light.z + lightz);
}
    
float3 traceRay(Ray r, thread RandomSeed *seed, Sphere spheres[]){
    //Jitter the light
    float3 jitteredLight = getLight(seed);
    
    float3 finalColor = float3(0.0,0.0,0.0);
    
    Hit h = getClosestHit(r, spheres);
    if (!h.didHit){
        return finalColor;
    }
    
    
    float3 normal = normalize(h.normal);
    float3 lightDirection = normalize(jitteredLight - h.hitPosition);
    float lightDistance = distance(jitteredLight, h.hitPosition);
    Ray shadowRay = {h.hitPosition, lightDirection};
    Hit shadowHit = getClosestHit(shadowRay, spheres);
    
    if (shadowHit.didHit && shadowHit.distance <= lightDistance){
        return finalColor;
    }
    
    float cosphi = dot(normal, lightDirection);
    
    if (cosphi > 0){
        finalColor = float3(1.0,1.0,1.0) * cosphi;
    }
    
    return finalColor * h.color;
}
    
float3 tracePath(Ray r, thread RandomSeed *seed, Sphere spheres[]){
    //Jitter the light
    float3 jitteredLight = getLight(seed);
    float3 accumulatedColor = float3(0.0,0.0,0.0);
    float3 reflectColor = float3(1.0,1.0,1.0);
    for (int i=0; i < bounceCount; i++){
        Hit h = getClosestHit(r, spheres);
        if (!h.didHit){
            return float3(0.0,0.0,0.0);
        }
        
        //Calculate direct lighting
        float3 normal = normalize(h.normal);
        float3 lightDirection = normalize(jitteredLight - h.hitPosition);
        float cosphi = dot(normal, lightDirection);
        
        
        //Calculate shadow factor
        
        Ray shadowRay = {h.hitPosition, lightDirection};
        Hit shadowHit = getClosestHit(shadowRay, spheres);
        
        float lightDistance = distance(jitteredLight, h.hitPosition);
        float shadowFactor = 1.0;
        if (shadowHit.didHit && shadowHit.distance <= lightDistance){
            shadowFactor = 0.0;
        }
        
        reflectColor *= h.color;
        accumulatedColor += reflectColor * cosphi * shadowFactor;
        
        r = bounce(h, seed);
    }
    
    return accumulatedColor * 0.5;
}


float3 tracePathNoDirect(Ray r, thread RandomSeed *seed, Sphere spheres[]){
    float3 accumulatedColor = float3(0.0,0.0,0.0);
    float3 reflectColor = float3(1.0,1.0,1.0);
    for (int i=0; i < bounceCount; i++){
        Hit h = getClosestHit(r, spheres);
        if (!h.didHit){
            return float3(0.0,0.0,0.0);
        }
        
        reflectColor *= h.color;
        accumulatedColor += reflectColor;
        
        if (h.material == LIGHT){
            return reflectColor;
            //return accumulatedColor;
        }
        
        
        r = bounce(h, seed);
    }
    
    return float3(0.0,0.0,0.0);
}

float4 monteCarloIntegrate(float4 currentSample, float4 newSample, uint sampleNumber){
    currentSample -= currentSample / (float)sampleNumber;
    currentSample += newSample / (float)sampleNumber;
    return currentSample;
}

Ray makeRay(float x, float y, float r1, float r2, constant packed_float3 *cameraParams){
    Camera cam;
    cam.eye = float3(cameraParams[0]);
    cam.up = float3(cameraParams[1]);
    cam.lookAt = -normalize(cam.eye);
    cam.right = cross(-normalize(cam.eye), cam.up);
    
    float3 base = cam.right * x + cam.up * y;
    float3 centered = base - float3(cam.right.x/2.0, cam.up.y/2.0, (cam.up + cam.right).z/2.0);
    
    float3 U = cam.up * r1 * cam.apertureSize;
    float3 V = cam.right * r2 * cam.apertureSize;
    float3 UV = U+V;
    
    float3 origin = cam.eye + UV;
    float3 direction = centered + cam.lookAt;
    direction = (direction * cam.focalLength) - UV;
    direction = normalize(direction);
    
    Ray outRay = {origin, direction};
    return outRay;
}


kernel void pathtrace(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]],
                      uint gindex [[thread_index_in_threadgroup]],
                      constant uint *intParams [[buffer(0)]],
                      constant packed_float3 *cameraParams [[buffer(1)]],
                      constant PackedSphere *spheres [[buffer(2)]]
                      ){
    
    uint gidIndex = gid.x * 500 + gid.y;
    uint sampleNumber = intParams[0];
    uint sysTime = intParams[1];
    
    
    RandomSeed seedMemory;
    seedMemory.a = gidIndex * sysTime * sampleNumber;
    seedMemory.b = gidIndex * gidIndex * sysTime * sysTime * sampleNumber * sampleNumber;
    seedMemory.c = gidIndex * gidIndex * sysTime * sampleNumber;
    seedMemory.d = gidIndex * gidIndex * gidIndex * sysTime * sampleNumber;
    
    thread RandomSeed *seed1 = &seedMemory;
    
    //Get the inColor
    uint2 textureIndex(gid.x, gid.y);
    float4 inColor = inTexture.read(textureIndex).rgba;
    
    float xResolution = 500.0;
    float yResolution = 500.0;
    float dx = 1.0 / xResolution;
    float dy = 1.0 / yResolution;
    float x = gid.x  * dx;
    float y = gid.y  * dy;
    
    
    //Jitter the ray
    uint jitterIndex = sampleNumber%100;
    uint xJitterPosition = jitterIndex%10;
    uint yJitterPosition = floor(float(jitterIndex)/10.0);
    
    float incX = 1.0/(xResolution*10);
    float xOffset = rand(seed1) * float(incX) + float(xJitterPosition) * float(incX);
    
    float incY = 1.0/(yResolution*10);
    float yOffset = rand(seed1) * float(incY) + float(yJitterPosition) * float(incY);
    
    
    Ray r = makeRay(x + xOffset, y + yOffset, 0.0, 0.0, cameraParams);
    
    //Unpack Sphere data
    Sphere unpackedSpheres[5];
    for (int i=0; i < 5; i++){
        PackedSphere p = spheres[i];
        unpackedSpheres[i] = {float3(p.position), p.radius, float3(p.color), p.material};
    }
    
    float4 outColor = float4(tracePath(r, seed1, unpackedSpheres), 1.0);
    //float4 outColor = float4(traceRay(r, seed1, unpackedSpheres), 1.0);
    
    //float4 outColor = float4(1.0,1.0,1.0,1.0);
    
    outTexture.write(mix(outColor, inColor, float(sampleNumber)/float(sampleNumber + 1)), gid);
}
