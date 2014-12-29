
#include <metal_stdlib>
using namespace metal;

//constant float3 eye;
//constant float3 initialRay;
//constant float textureWeight;
//constant float timeSinceStart;
//constant sampler2D texture;
constant float glossiness = 0.0;
constant float3 roomCubeMin = float3(-1.0, -1.0, -1.0);
constant float3 roomCubeMax = float3(1.0, 1.0, 1.0);
constant float3 light = float3(0.0,0.999,0.0);
constant float3 sphereCenter0 = float3(0.0,-0.75,0.0);
constant float sphereRadius0 = 0.25;
constant float3 sphereCenter1 = float3(0.5,-0.25,0.0);
constant float sphereRadius1 = 0.25;
constant float3 sphereCenter2 = float3(-0.5,0.25,0.0);
constant float sphereRadius2 = 0.25;
constant float3 sphereCenter3 = float3(-0.5,0.3,-0.5);
constant float sphereRadius3 = 0.25;

float2 intersectCube(float3 origin, float3 ray, float3 cubeMin, float3 cubeMax) {
    float3 tMin = (cubeMin - origin) / ray;
    float3 tMax = (cubeMax - origin) / ray;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return float2(tNear, tFar);
}

float3 normalForCube(float3 hit, float3 cubeMin, float3 cubeMax) {
    if(hit.x < cubeMin.x + 0.0001)
        return float3(-1.0, 0.0, 0.0);
    else if(hit.x > cubeMax.x - 0.0001)
        return float3(1.0, 0.0, 0.0);
    else if(hit.y < cubeMin.y + 0.0001)
        return float3(0.0, -1.0, 0.0);
    else if(hit.y > cubeMax.y - 0.0001)
        return float3(0.0, 1.0, 0.0);
    else if(hit.z < cubeMin.z + 0.0001)
        return float3(0.0, 0.0, -1.0);
    else return float3(0.0, 0.0, 1.0);
}

float intersectSphere(float3 origin, float3 ray, float3 sphereCenter, float sphereRadius){
    float3 toSphere = origin - sphereCenter;
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

float3 normalForSphere(float3 hit, float3 sphereCenter, float sphereRadius) {
    return (hit - sphereCenter) / sphereRadius;
}

float random(float3 scale, float seed, float3 pos) {
    return fract(sin(dot(pos + seed, scale)) * 43758.5453 + seed);
}

float3 cosineWeightedDirection(float seed, float3 normal, float3 pos) {
    float u = random(float3(12.9898, 78.233, 151.7182), seed, pos);
    float v = random(float3(63.7264, 10.873, 623.6736), seed, pos);
    float r = sqrt(u);
    float angle = 6.283185307179586 * v;
    float3 sdir, tdir;
    if (abs(normal.x)<.5) {
        sdir = cross(normal, float3(1,0,0));
    } else {
        sdir = cross(normal, float3(0,1,0));
    }
    tdir = cross(normal, sdir);
    
    return r*cos(angle)*sdir + r*sin(angle)*tdir + sqrt(1.-u)*normal;
}

float3 uniformlyRandomDirection(float seed, float3 pos) {
    float u = random(float3(12.9898, 78.233, 151.7182), seed, pos);
    float v = random(float3(63.7264, 10.873, 623.6736), seed, pos);
    float z = 1.0 - 2.0 * u;   float r = sqrt(1.0 - z * z);
    float angle = 6.283185307179586 * v;
    return float3(r * cos(angle), r * sin(angle), z);
}

float3 uniformlyRandomVector(float seed, float3 pos) {
    return uniformlyRandomDirection(seed, pos) * sqrt(random(float3(36.7539, 50.3658, 306.2759), seed, pos));
}

float shadow(float3 origin, float3 ray) {
    float tSphere0 = intersectSphere(origin, ray, sphereCenter0, sphereRadius0);
    if(tSphere0 < 1.0) return 0.0;
    float tSphere1 = intersectSphere(origin, ray, sphereCenter1, sphereRadius1);
    if(tSphere1 < 1.0) return 0.0;
    float tSphere2 = intersectSphere(origin, ray, sphereCenter2, sphereRadius2);
    if(tSphere2 < 1.0) return 0.0;
    float tSphere3 = intersectSphere(origin, ray, sphereCenter3, sphereRadius3);
    if(tSphere3 < 1.0) return 0.0;   return 1.0;
}

float4 calculateColor(float3 origin, float3 ray, float3 light, float timeSinceStart, float3 pos) {
    float3 colorMask = float3(1.0);
    float3 accumulatedColor = float3(0.0);
    for(int bounce = 0; bounce < 5; bounce++) {
        float2 tRoom = intersectCube(origin, ray, roomCubeMin, roomCubeMax);
        float tSphere0 = intersectSphere(origin, ray, sphereCenter0, sphereRadius0);
        float tSphere1 = intersectSphere(origin, ray, sphereCenter1, sphereRadius1);
        float tSphere2 = intersectSphere(origin, ray, sphereCenter2, sphereRadius2);
        float tSphere3 = intersectSphere(origin, ray, sphereCenter3, sphereRadius3);
        float t = 10000.0;
        if(tRoom.x < tRoom.y) t = tRoom.y;
        if(tSphere0 < t) t = tSphere0;
        if(tSphere1 < t) t = tSphere1;
        if(tSphere2 < t) t = tSphere2;
        if(tSphere3 < t) t = tSphere3;
        float3 hit = origin + ray * t;
        float3 surfaceColor = float3(0.75);
        float specularHighlight = 0.0;
        float3 normal;
        if(t == tRoom.y) {
            normal = -normalForCube(hit, roomCubeMin, roomCubeMax);
            if(hit.x < -0.9999) surfaceColor = float3(0.1, 0.5, 1.0);
            else if(hit.x > 0.9999) surfaceColor = float3(1.0, 0.9, 0.1);
            ray = cosineWeightedDirection(timeSinceStart + float(bounce), normal, pos);
        } else if(t == 10000.0) {
            break;
        } else {
            if(false) ;
            else if(t == tSphere0) normal = normalForSphere(hit, sphereCenter0, sphereRadius0);
            else if(t == tSphere1) normal = normalForSphere(hit, sphereCenter1, sphereRadius1);
            else if(t == tSphere2) normal = normalForSphere(hit, sphereCenter2, sphereRadius2);
            else if(t == tSphere3) normal = normalForSphere(hit, sphereCenter3, sphereRadius3);
            ray = cosineWeightedDirection(timeSinceStart + float(bounce), normal, pos);
        }
        float3 toLight = light - hit;
        float diffuse = max(0.0, dot(normalize(toLight), normal));
        float shadowIntensity = shadow(hit + normal * 0.0001, toLight);
        colorMask *= surfaceColor;
        accumulatedColor += colorMask * (0.5 * diffuse * shadowIntensity);
        accumulatedColor += colorMask * specularHighlight * shadowIntensity;
        origin = hit;
    }
    return float4(accumulatedColor,1.0);
}

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
                      uint2 gid [[thread_position_in_grid]],
                      uint gindex [[thread_index_in_threadgroup]],
                      constant uint *intParams [[buffer(0)]],
                      constant float3 *floatParams [[buffer(1)]]){
    
    
    uint sampleNumber = intParams[0];
    uint timeSinceStart = intParams[1];
    
    
    
    
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
    
    
    //Jitter the ray
    /*uint jitterIndex = sampleNumber%100;
    uint xJitterPosition = jitterIndex%10;
    uint yJitterPosition = floor(jitterIndex/10.0);
    
    float incX = 1.0/xResolution;
    float xOffset = (rand(seed1) * incX) + (xJitterPosition * incX);
    
    float incY = 1.0/yResolution;
    float yOffset = (rand(seed1) * incY) + (yJitterPosition * incY);
    
    xOffset = rand(seed1)/xResolution;
    yOffset = rand(seed1)/yResolution;*/
    
    
    float3 ray = makeRay(x, y);
    float4 outColor = calculateColor(eye, ray, light, timeSinceStart, float3(gid.x, gid.y, 0.5));
    
    //float4 outColor = float4(1.0,1.0,1.0,1.0);
    
    outTexture.write(mix(outColor, inColor, float(sampleNumber)/float(sampleNumber + 1)), gid);
}