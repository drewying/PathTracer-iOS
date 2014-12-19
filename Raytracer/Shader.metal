//Simple path tracer by Movania Muhammad Mobeen
#include <metal_stdlib>
using namespace metal;

static constant float3 light = float3(10.0,10.0,10.0);

struct Sphere {
    float4 center_radius;
};

struct Box {
    float3 min, max;
};

static constant Box rootCube = {float3(-1.0,-1.0,-1.0), float3(1.0,1.0,1.0)};
static constant Sphere spheres[4] = {{float4(0.0,-0.75,0.0,0.25)}, {float4(0.0,-0.25,0.0,0.25)}, {float4(0.0,0.25,0.0,0.25)}, {float4(0.0,0.75,0.0,0.25)}};

float2 intersectCube(float3 origin, float3 ray, Box cube) {
    float3   tMin = (cube.min - origin) / ray;
    float3   tMax = (cube.max - origin) / ray;
    float3     t1 = min(tMin, tMax);
    float3     t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float  tFar = min(min(t2.x, t2.y), t2.z);
    return float2(tNear, tFar);
}
float3 normalForCube(float3 hit, Box cube)	{
    if(hit.x < cube.min.x + 0.0001) return float3(-1.0, 0.0, 0.0);
    else if(hit.x > cube.max.x - 0.0001) return float3(1.0, 0.0, 0.0);
    else if(hit.y < cube.min.y + 0.0001) return float3(0.0, -1.0, 0.0);
    else if(hit.y > cube.max.y - 0.0001) return float3(0.0, 1.0, 0.0);
    else if(hit.z < cube.min.z + 0.0001) return float3(0.0, 0.0, -1.0);
    else return float3(0.0, 0.0, 1.0);
}

float intersectSphere(float3 origin, float3 ray, Sphere s) {
    float3 toSphere = origin - s.center_radius.xyz;
    float sphereRadius = s.center_radius.w;
    float a = dot(ray, ray);
    float b = 2.0 * dot(toSphere, ray);
    float c = dot(toSphere, toSphere) - sphereRadius*sphereRadius;
    float discriminant = b*b - 4.0*a*c;
    if(discriminant > 0.0) {
        float t = (-b - sqrt(discriminant)) / (2.0 * a);
        if(t > 0.0) return t;
    }
    return 10000.0;
}

float3 normalForSphere(float3 hit, Sphere s) {
    return (hit - s.center_radius.xyz) / s.center_radius.w;
}

float random(float3 scale, float seed, float2 pos) {
    return fract(sin(dot(float3(pos, 1.0) + seed, scale)) * 43758.5453 + seed);
}

float3 uniformlyRandomDirection(float seed, float2 pos) {
    float u = random(float3(12.9898, 78.233, 151.7182), seed, pos);
    float v = random(float3(63.7264, 10.873, 623.6736), seed, pos);
    float z = 1.0 - 2.0 * u;
    float r = sqrt(1.0 - z * z);
    float angle = 6.283185307179586 * v;
    return float3(r * cos(angle), r * sin(angle), z);
}

float3 cosineWeightedDirection(float seed, float2 pos, float3 normal) {
   float u = random(float3(12.9898, 78.233, 151.7182), seed, pos);
   float v = random(float3(63.7264, 10.873, 623.6736), seed, pos);
   float r = sqrt(u);
   float angle = 6.283185307179586 * v;
// compute basis from normal
   float3 sdir, tdir;
   if (abs(normal.x)<.5) {
     sdir = cross(normal, float3(1,0,0));
   } else {
     sdir = cross(normal, float3(0,1,0));
   }
   tdir = cross(normal, sdir);
   return r*cos(angle)*sdir + r*sin(angle)*tdir + sqrt(1.-u)*normal;
}

float3 cosineWeightedVector(float seed, float2 pos, float3 normal){
    return cosineWeightedDirection(seed, pos, normal) *  (random(float3(36.7539, 50.3658, 306.2759), seed, pos));
}

float3 uniformlyRandomVector(float seed, float2 pos)
{
    return uniformlyRandomDirection(seed, pos) *  (random(float3(36.7539, 50.3658, 306.2759), seed, pos));
}

float shadow(float3 origin, float3 ray) {
    float tSphere0 = intersectSphere(origin, ray, spheres[0]);
    if(tSphere0 < 1.0) return 0.0;
    float tSphere1 = intersectSphere(origin, ray, spheres[1]);
    if(tSphere1 < 1.0) return 0.0;
    float tSphere2 = intersectSphere(origin, ray, spheres[2]);
    if(tSphere2 < 1.0) return 0.0;
    float tSphere3 = intersectSphere(origin, ray, spheres[3]);
    if(tSphere3 < 1.0) return 0.0;
    return 1.0;
}

float3 calculateColor(float3 origin, float3 ray, float3 light, float timeSinceStart, float2 pos) {
    float3 colorMask = float3(1.0);
    float3 accumulatedColor = float3(0.0);
    int i=0;
    float rindex0=0;
    for(int bounce = 0; bounce < 5; bounce++) {
        float2 tRoom = intersectCube(origin, ray, rootCube);
        float t = 10000.0;
        if(tRoom.x < tRoom.y)
            t = tRoom.y;
        else
            break;
        float tSphere0 = intersectSphere(origin, ray, spheres[0]);
        float tSphere1 = intersectSphere(origin, ray, spheres[1]);
        float tSphere2 = intersectSphere(origin, ray, spheres[2]);
        float tSphere3 = intersectSphere(origin, ray, spheres[3]);
        
        if(tSphere0 < t) { t = tSphere0;i=0;}
        if(tSphere1 < t) { t = tSphere1;i=1;}
        if(tSphere2 < t) { t = tSphere2;i=2;}
        if(tSphere3 < t) { t = tSphere3;i=3;}
        
        float3 hit = origin + ray * t;
        float3 surfaceColor = float3(0.75);//(t==tLight)?float3(10):float3(0.75);
        float specularHighlight = 0.0;
        float3 normal;
        if(t == tRoom.y) {
            normal = -normalForCube(hit, rootCube);
            if(hit.x < -0.9999)
                //surfaceColor = float3(0.5, 0.0, 0.0);
                surfaceColor = float3(0.1, 0.5, 1.0);
            else if(hit.x > 0.9999)
                //surfaceColor = float3(0.0, 0.5, 0.0);
                surfaceColor = float3(1.0, 0.9, 0.1);
            //ray = uniformlyRandomDirection(timeSinceStart + float(bounce), pos);
            ray = cosineWeightedDirection(timeSinceStart + float(bounce), pos, normal);
            if(dot(normal, ray) < 0.0) ray = -ray;
        }
        else if(t == 10000.0) {
            break;
        } else {
            if(false) ;
            normal = normalForSphere(hit, spheres[i]);
            //diffuse
            //ray = uniformlyRandomDirection(timeSinceStart + float(bounce), pos);
            ray = cosineWeightedDirection(timeSinceStart + float(bounce), pos, normal);
            
            //if(dot(normal, ray) < 0.0)
            //		ray = -ray;
            //}
        }
        float3 toLight = light - hit;
        float diffuse = max(0.0, dot(normalize(toLight), normal));
        float shadowIntensity = shadow(hit + normal * 0.0001, toLight);
        colorMask *= surfaceColor;
        accumulatedColor += colorMask * (diffuse * shadowIntensity);
        accumulatedColor += specularHighlight * shadowIntensity;			
        origin = hit;		
    }		
    return accumulatedColor * 0.5;	
}

struct Camera{
    float3 eye = eye;
    
    float apertureSize = 0.0;
    float focalLength = 1.0;
};

static constant float3 eye = float3(0.0,0.0,-3.0);
static constant float3 lookAt = float3(0.0,0.0,1.0);
static constant float3 up = float3(0.0, 1.0, 0.0);
static constant float3 right = float3(1.0, 0.0, 0.0);

float3 makeRay(float x, float y){
    float3 base = right * x + up * y;
    float3 centered = base - float3(right.x/2.0, up.y/2.0, 0.0);
    float3 direction = normalize(centered + lookAt);
    return direction;
}

kernel void pathtrace(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]], device uint *params [[buffer(0)]]){
    
    float timeSinceStart = float(params[0]);
    uint sampleNumber = params[1];
    
    //Set the random seed;
    uint initialSeed = (timeSinceStart * (sampleNumber * 500)) * (gid.x + 500 * (gid.y-1)); //gid.x * gid.y;
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
    
    float3 r = makeRay(x, y);
    
    float4 outColor = float4(calculateColor(eye, r, light, timeSinceStart, float2(gid.x,gid.y)),1.0);
    
    outTexture.write(mix(outColor, inColor, float(sampleNumber)/float(sampleNumber + 1)), gid);
}