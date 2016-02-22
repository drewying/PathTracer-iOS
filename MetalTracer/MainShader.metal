//
//  MainShader.metal
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//#define FLT_MAX 3.40282347E+38
#define INT_MAX 2147483647
#define UNSIGNED_INT_MAX 4294967295
#define M_PI 3.14159265358979323846

#define EPSILON 1.e-3

static constant int bounceCount = 7;

enum Material : uint { DIFFUSE = 0, SPECULAR = 1, DIELECTRIC = 2, TRANSPARENT = 3, LIGHT = 4};
    
struct Ray{
    float3 origin;
    float3 direction;
};

struct Hit{
    float distance;
    Ray ray;
    float3 normal;
    float3 hitPosition;
    uint material;
    float3 color;
    bool didHit;
};

struct Sphere{
    packed_float3 position;
    float radius;
    uint material;
    packed_float3 color;
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
    float3 normal;
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
    float3 position;
    float3 up;
    float apertureSize = 0.0;
    float focalLength = 1.0;
};
    
struct Scene{
    Sphere light;
    constant Sphere *spheres;
    constant packed_float3 *colors;
};
    
static constant struct Box boxes[] = {
    {float3(-1.0,1.0,-1.0), float3(-1.0,-1.0,1.0), float3(1.0,0.0,0.0), float3(0.75,0.0,0.0), DIFFUSE}, //Left
    {float3(1.0,1.0,-1.0), float3(1.0,-1.0,1.0), float3(-1.0,0.0,0.0), float3(0.0,0.0,0.75), DIFFUSE}, //Right
    {float3(1.0,1.0,-1.0), float3(-1.0,-1.0,-1.0), float3(0.0,0.0,1.0), float3(0.75,0.75,0.75), DIFFUSE}, //Back
    {float3(1.0,1.0,1.0), float3(-1.0,-1.0,1.0), float3(0.0,0.0,-1.0), float3(0.75,0.75,0.75), DIFFUSE}, //Front
    {float3(1.0,1.0,1.0), float3(-1.0,1.0,-1.0), float3(0.0,-1.0,0.0), float3(0.75,0.75,0.75), DIFFUSE}, //Top
    {float3(1.0,-1.0,1.0), float3(-1.0,-1.0,-1.0), float3(0.0,1.0,0.0), float3(0.75,0.75,0.75), DIFFUSE} //Bottom
};


inline Hit noHit(){
    Hit hit;
    hit.didHit = false;
    hit.distance = FLT_MAX;
    return hit;
}

inline Hit getHit(float maxT, float minT, Ray ray, float3 normal, float3 color, uint material){
    
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
    
    
    if (tNear > tFar){
        return noHit();
    }
    
    if (dot(b.normal, ray.direction) > 0){
        return noHit();
    }
    
    float t;
    if (tNear <= EPSILON) {
        t = tNear;
    } else{
        t = tFar;
    }
    
    return getHit(distance, t, ray, normalize(b.normal), b.color, b.material);
}
    


Hit planeIntersection(Plane p, Ray ray, float distance);
Hit planeIntersection(Plane p, Ray ray, float distance){
    float3 n = normalize(p.normal);
    float d = dot(n, p.position);
    float denom = dot(n, ray.direction);
    if (-denom > EPSILON) {
        float t = (d - dot(n, ray.origin)) / denom;
        float3 hitpos = ray.origin + ray.direction * t;
        return getHit(distance, t, ray, p.normal, p.color, p.material);
    }
    return noHit();
}

Hit sphereIntersection(Sphere s, Ray ray, float distance){
    if (s.radius < 0.05){
        return noHit();
    }
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
        float3 norm = normalize(hitpos - s.position);
        return getHit(distance, tFar, ray, norm, s.color, s.material);
    } else{
        float3 hitpos = ray.origin + ray.direction * tNear;
        float3 norm = normalize(hitpos - s.position);
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

inline float rand(thread uint *seed)
{
    //A hack for the sin funciton
    /*uint x = *seed;
    x++;
    *seed = x;
    return fract(sin(float(x))*43758.5453123);*/
    
    
    //http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
    //LCG which is faster
    /*uint x = *seed;
    x = 1664525 * x + 1013904223;
    *seed = x;
    return float(x) / 4294967295.0;*/
    
    //While a xor_shift... produces better results
    uint x = *seed;
    x ^= (x << 13);
    x ^= (x >> 17);
    x ^= (x << 5);
    *seed = x;
    return float(x) / 4294967295.0;
}

float3 uniformSampleDirection(thread uint *seed){
    float u1 = rand(seed);
    float u2 = rand(seed);
    
    float r = sqrt(1.0 - u1 * u2);
    float theta = 2 * M_PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = u1;
    
    return normalize(float3(x,y,z));
}

float3 bookSampleDirection(thread uint *seed){
    float u1 = rand(seed);
    float u2 = rand(seed);
    
    float r = sqrt(u1);
    float theta = 2 * M_PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(1.0 - x * x - y * y);
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
    
float3 cosWeightedRandomHemisphereDirection( const float3 n, thread uint *seed ) {
    
    float u1 = rand(seed);
    float u2 = rand(seed);
    
    float3  uu = normalize( cross( n, float3(0.0,1.0,1.0) ) );
    float3  vv = cross( uu, n );
    
    float r = sqrt(u1);
    float theta = 2 * M_PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(1.0 - u1);
    
    return normalize(float3(x*uu + y*vv + z*n));
}

Ray bounce(Hit h, thread uint *seed){
    
    float3 outVector;
    
    if (h.material == DIFFUSE){
        //outVector = uniformSampleDirection(seed);
        //outVector = cosineWeightedDirection(seed);
        //outVector = bookSampleDirection(seed);
        outVector = cosWeightedRandomHemisphereDirection(h.normal, seed);
    } else if (h.material == SPECULAR){
        outVector = reflect(h.ray.direction, h.normal);
    } else if (h.material == DIELECTRIC){
        if (rand(seed) > 0.925){
            outVector = reflect(h.ray.direction, h.normal);
        } else{
            float3 normal = h.normal;
            float3 incident = h.ray.direction;
            float3 nl = dot(normal, incident) < 0 ? normal : normal * -1.0;
            float into = dot(nl, normal);
            
            float refractiveIndexAir = 1;
            float refractiveIndexGlass = 1.5;
            float refractiveIndexRatio = pow(refractiveIndexAir / refractiveIndexGlass, (into > 0) - (into < 0));
            normal *= ((into > 0) - (into < 0));
            outVector = refract(incident, normal, refractiveIndexRatio);
        }
        
    } else {
        outVector = h.ray.direction;
    }
    
    
    Ray outRay;
    outRay.origin = h.hitPosition;
    outRay.direction = outVector;
    return outRay;
}
    

inline Hit getClosestHit(Ray r, Scene scene, thread uint *seed){
    Hit h = noHit();

    /*for (int i=0; i<boxCount; i++){
        Box b = boxes[i];
        Hit hit = boxIntersection(b, r, h.distance);
        if (hit.didHit){
            h = hit;
            if (scene.colors[i][0] >= 0.0){
                h.color = scene.colors[i];
            } else{
                float x;
                float y;
                if (abs(hit.normal.x) > 0){
                    x = hit.hitPosition.z;
                    y = hit.hitPosition.y;
                } else if (abs(hit.normal.y) > 0){
                    x = hit.hitPosition.x;
                    y = hit.hitPosition.z;
                } else if (abs(hit.normal.z) > 0){
                    x = hit.hitPosition.x;
                    y = hit.hitPosition.y;
                }
                h.color = imageTexture.read(uint2(((x/2)+0.5) * 1000, 1000 - (((y/2)+0.5) * 1000))).rgb;
            }
        }
    }*/
    
    Hit hit = boxIntersection(boxes[0], r, h.distance);
    if (hit.didHit){
        h = hit;
        h.color = scene.colors[0];
    }
    hit = boxIntersection(boxes[1], r, h.distance);
    if (hit.didHit){
        h = hit;
        h.color = scene.colors[1];
    }
    hit = boxIntersection(boxes[2], r, h.distance);
    if (hit.didHit){
        h = hit;
        h.color = scene.colors[2];
    }
    hit = boxIntersection(boxes[3], r, h.distance);
    if (hit.didHit){
        h = hit;
        h.color = scene.colors[3];
    }
    hit = boxIntersection(boxes[4], r, h.distance);
    if (hit.didHit){
        h = hit;
        h.color = scene.colors[4];
    }
    hit = boxIntersection(boxes[5], r, h.distance);
    if (hit.didHit){
        h = hit;
        h.color = scene.colors[5];
    }
    
    hit = sphereIntersection(scene.spheres[0], r, h.distance);
    if (hit.didHit){
        h = hit;
    }
    hit = sphereIntersection(scene.spheres[1], r, h.distance);
    if (hit.didHit){
        h = hit;
    }
    hit = sphereIntersection(scene.spheres[2], r, h.distance);
    if (hit.didHit){
        h = hit;
    }
    hit = sphereIntersection(scene.spheres[3], r, h.distance);
    if (hit.didHit){
        h = hit;
    }
    hit = sphereIntersection(scene.spheres[4], r, h.distance);
    if (hit.didHit){
        h = hit;
    }
    return h;
}

float3 jitterPosition(thread uint *seed, float3 position){
    float lightx = (rand(seed) * 0.06) - 0.03;
    float lighty = (rand(seed) * 0.06) - 0.03;
    float lightz = (rand(seed) * 0.06) - 0.03;
    return float3(position.x + lightx, position.y + lighty, position.z + lightz);
}
    
    
float3 randomSphereDirection(thread uint *seed) {
    float2 r = float2(rand(seed), rand(seed));
    float3 dr = float3(sin(r.x)*float2(sin(r.y),cos(r.y)),cos(r.x));
    return dr;
}

    
float3 sampleLight(float3 lightPosition, thread uint *seed) {
    float3 n = randomSphereDirection(seed) * 0.5;
    return lightPosition.xyz + n;
}

float3 tracePath(Ray ray, thread uint *seed, Scene scene){
    float3 indirectLightingColor = float3(1.0,1.0,1.0);
    float3 accumulatedColor = float3(0.0,0.0,0.0);
    
    for (int i=0; i < bounceCount; i++){
        Hit h = getClosestHit(ray, scene, seed);
        
        if (h.didHit == false){
            return float3(0,0,0);
        }
        
        
        //Bounce the ray
        ray = bounce(h, seed);
        
        //Indirect Lighting Factor
        indirectLightingColor *= h.color;
        
        //Direct Lighting Shadow Factor
        float3 lightDirection = normalize(scene.light.position - h.hitPosition);
        float3 jitteredPosition = jitterPosition(seed, h.hitPosition);
        Ray shadowRay = {jitteredPosition, lightDirection};
        Hit shadowHit = getClosestHit(shadowRay, scene, seed);
        float lightDistance = distance(scene.light.position, jitteredPosition);
        bool inShadow = (shadowHit.didHit && shadowHit.distance <= lightDistance);
        
        if (!inShadow && i < bounceCount - 1){
            //Direct Lighting Factor
            
            //float directLightingFactor = dot(normal, lightDirection)/dot(lightDirection, lightDirection);
            float directLightingFactor = dot(h.normal, lightDirection);
            
            float cos_a_max = sqrt(1.0 - clamp(0.5 * 0.5 / dot(scene.light.position - ray.origin, scene.light.position - ray.origin), 0.0, 1.0));
            float weight = 2.0 * (1.0 - cos_a_max);
            
            accumulatedColor += indirectLightingColor * scene.light.color * weight * clamp(directLightingFactor, 0.0, 1.0);
        }
        
    
        //Direct Lighting Shadow Factor
        //float3 jitteredPosition = jitterPosition(seed, h.hitPosition);
        //Ray shadowRay = {jitteredPosition, lightDirection};
        //Hit shadowHit = getClosestHit(shadowRay, scene, seed);
        //float lightDistance = distance(lightPosition, jitteredPosition);
        //float shadowFactor = (shadowHit.didHit && shadowHit.distance <= lightDistance) ? 0.0 : 1.0;
    }
    return accumulatedColor;
    
}

Ray makeRay(thread uint *seed, float x, float y, float aspectRatio, constant packed_float3 *cameraParams){
    Camera cam;
    cam.position = float3(cameraParams[0]);
    cam.up = float3(cameraParams[1]);
    float3 lookAt = -normalize(cam.position);
    
    float r1 = 0;
    float r2 = 0;
    
    if (cam.apertureSize > 0.0){
        r1 = (rand(seed) * 2.0) - 1.0;
        r2 = (rand(seed) * 2.0) - 1.0;
    }
    
    float3 l = normalize(lookAt-cam.position);
    float3 right = cross(l, cam.up);
    float3 up = cross(right, l);
    
    float3 U = up * r1 * cam.apertureSize;
    float3 V = right * r2 * cam.apertureSize;
    float3 UV = U+V;
    
    
    right = normalize(right);
    up = normalize(up);
    
    right *= aspectRatio;
    
    float3 direction = l + right * x + up * y;
    direction = (direction * cam.focalLength) - UV;
    direction = normalize(direction);
    
    float3 origin = cam.position + UV;
    
    Ray outRay = {origin, direction};
    return outRay;
}

    
uint hashSeed(uint seed){
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}

kernel void mainProgram(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]],
                      uint gindex [[thread_index_in_threadgroup]],
                      constant uint *intParams [[buffer(0)]],
                      constant packed_float3 *cameraParams [[buffer(1)]],
                      constant Sphere *spheres [[buffer(2)]],
                      constant packed_float3 *wallColors [[buffer(3)]]
                      ){
    
    uint gidIndex = gid.x * intParams[2] + gid.y;
    uint sampleNumber = intParams[0];
    uint sysTime = intParams[1];
    float xResolution = float(intParams[2]);
    float yResolution = float(intParams[3]);
    int sphereCount = int(intParams[4]);
    
    uint seedMemory = hashSeed(gidIndex * sysTime * sampleNumber);
    
    thread uint *seed = &seedMemory;
    
    //Get the inColor
    float4 inColor = inTexture.read(gid).rgba;
    
    float aspect_ratio = xResolution/yResolution;
    
    //Jitter the ray
    xResolution += (rand(seed) - 0.5);
    yResolution += (rand(seed) - 0.5);
    
    float dx = 1.0 / xResolution;
    float dy = 1.0 / yResolution;
    float x = -0.5 + gid.x  * dx;
    float y = -0.5 + gid.y  * dy;
    
    Ray r = makeRay(seed, x, y, aspect_ratio, cameraParams);
    Scene scene = Scene{spheres[0], spheres + 1, wallColors};
    float4 outColor = float4(tracePath(r, seed, scene), 1.0);
    outTexture.write(mix(outColor, inColor, float(sampleNumber)/float(sampleNumber + 1)), gid);
}
