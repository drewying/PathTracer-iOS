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

#define EPSILON 1.e-3/*

This shader is an attempt at porting smallpt to GLSL.

See what it's all about here:
http://www.kevinbeason.com/smallpt/

The code is based in particular on the slides by David Cline.

Some differences:

- For optimization purposes, the code considers there is
only one light source (see the commented loop)
- Russian roulette and tent filter are not implemented

I spent quite some time pulling my hair over inconsistent
behavior between Chrome and Firefox, Angle and native. I
expect many GLSL related bugs to be lurking, on top of
implementation errors. Please Let me know if you find any.

--
Zavie

*/

// Play with the two following values to change quality.
// You want as many samples as your GPU can bear. :)
#define SAMPLES 6
#define MAXDEPTH 4

// Uncomment to see how many samples never reach a light source
//#define DEBUG

// Not used for now
#define DEPTH_RUSSIAN 2

#define PI 3.14159265359
#define DIFF 0
#define SPEC 1
#define REFR 2
#define NUM_SPHERES 9

//float rand(thread uint *seed) {  uint x = *seed; *seed = x; return fract(sin(float(x))*43758.5453123); }

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



struct Ray { float3 o, d; };
struct Sphere {
    float r;
    float3 p, e, c;
    int refl;
};

static constant Sphere lightSourceVolume = {20., float3(50., 81.6, 81.6), float3(12.), float3(0.), DIFF};
static constant Sphere spheres[NUM_SPHERES] = {
    {1e5, float3(-1e5+1., 40.8, 81.6),	float3(0.), float3(.75, .25, .25), DIFF},
    {1e5, float3( 1e5+99., 40.8, 81.6),float3(0.), float3(.25, .25, .75), DIFF},
    {1e5, float3(50., 40.8, -1e5),		float3(0.), float3(.75), DIFF},
    {1e5, float3(50., 40.8,  1e5+170.),float3(0.), float3(0.), DIFF},
    {1e5, float3(50., -1e5, 81.6),		float3(0.), float3(.75), DIFF},
    {1e5, float3(50.,  1e5+81.6, 81.6),float3(0.), float3(.75), DIFF},
    {16.5, float3(27., 16.5, 47.), 	float3(0.), float3(1.), SPEC},
    {16.5, float3(73., 16.5, 78.), 	float3(0.), float3(.7, 1., .9), REFR},
    {600., float3(50., 681.33, 81.6),	float3(12.), float3(0.), DIFF}
};


float intersect(Sphere s, Ray r) {
    float3 op = s.p - r.o;
    float t, epsilon = 1e-3, b = dot(op, r.d), det = b * b - dot(op, op) + s.r * s.r;
    if (det < 0.) return 0.; else det = sqrt(det);
    return (t = b - det) > epsilon ? t : ((t = b + det) > epsilon ? t : 0.);
}

int intersect(Ray r, thread float &t, thread Sphere &s, int avoid) {
    int id = -1;
    t = 1e5;
    s = spheres[0];
    for (int i = 0; i < NUM_SPHERES; ++i) {
        Sphere S = spheres[i];
        float d = intersect(S, r);
        if (i!=avoid && d!=0. && d<t) { t = d; id = i; s=S; }
    }
    return id;
}

float3 jitter(float3 d, float phi, float sina, float cosa) {
    float3 w = normalize(d), u = normalize(cross(w.yzx, w)), v = cross(w, u);
    return (u*cos(phi) + v*sin(phi)) * sina + w * cosa;
}

float3 radiance(Ray r, thread uint *seed) {
    float3 acc = float3(0.);
    float3 mask = float3(1.);
    int id = -1;
    for (int depth = 0; depth < MAXDEPTH; ++depth) {
        float t;
        Sphere obj;
        if ((id = intersect(r, t, obj, id)) < 0) break;
        float3 x = t * r.d + r.o;
        float3 n = normalize(x - obj.p), nl = n * sign(-dot(n, r.d));
        
        //float3 f = obj.c;
        //float p = dot(f, float3(1.2126, 0.7152, 0.0722));
        //if (depth > DEPTH_RUSSIAN || p == 0.) if (rand() < p) f /= p; else { acc += mask * obj.e * E; break; }
        
        if (obj.refl == DIFF) {
            float r2 = rand(seed);
            float3 d = jitter(nl, 2.*PI*rand(seed), sqrt(r2), sqrt(1. - r2));
            float3 e = float3(0.);
            //for (int i = 0; i < NUM_SPHERES; ++i)
            {
                // Sphere s = sphere(i);
                // if (dot(s.e, float3(1.)) == 0.) continue;
                
                // Normally we would loop over the light sources and
                // cast rays toward them, but since there is only one
                // light source, that is mostly occluded, here goes
                // the ad hoc optimization:
                Sphere s = lightSourceVolume;
                int i = 8;
                
                float3 l0 = s.p - x;
                float cos_a_max = sqrt(1. - clamp(s.r * s.r / dot(l0, l0), 0., 1.));
                float cosa = mix(cos_a_max, 1., rand(seed));
                float3 l = jitter(l0, 2.*PI*rand(seed), sqrt(1. - cosa*cosa), cosa);
                
                if (intersect(Ray{x, l}, t, s, id) == i) {
                    float omega = 2. * PI * (1. - cos_a_max);
                    e += (s.e * clamp(dot(l, n),0.,1.) * omega) / PI;
                }
            }
            float E = 1.;//float(depth==0);
            acc += mask * obj.e * E + mask * obj.c * e;
            mask *= obj.c;
            r = Ray{x, d};
        } else if (obj.refl == SPEC) {
            acc += mask * obj.e;
            mask *= obj.c;
            r = Ray{x, reflect(r.d, n)};
        } else {
            float a=dot(n,r.d), ddn=abs(a);
            float nc=1., nt=1.5, nnt=mix(nc/nt, nt/nc, float(a>0.));
            float cos2t=1.-nnt*nnt*(1.-ddn*ddn);
            r = Ray{x, reflect(r.d, n)};
            if (cos2t>0.) {
                float3 tdir = normalize(r.d*nnt + sign(a)*n*(ddn*nnt+sqrt(cos2t)));
                float R0=(nt-nc)*(nt-nc)/((nt+nc)*(nt+nc)),
                c = 1.-mix(ddn,dot(tdir, n),float(a>0.));
                float Re=R0+(1.-R0)*c*c*c*c*c,P=.25+.5*Re,RP=Re/P,TP=(1.-Re)/(1.-P);
                if (rand(seed)<P) { mask *= RP; }
                else { mask *= obj.c*TP; r = Ray{x, tdir}; }
            }
        }
    }
    return acc;
}

/*void mainImage( out float4 fragColor, in float2 fragCoord ) {
    
}*/



kernel void mainProgram(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      texture2d<float, access::read> imageTexture [[texture(2)]],
                      uint2 gid [[thread_position_in_grid]],
                      uint gindex [[thread_index_in_threadgroup]],
                      constant uint *intParams [[buffer(0)]],
                      constant packed_float3 *cameraParams [[buffer(1)]],
                      constant Sphere *spheresa [[buffer(2)]],
                      constant packed_float3 *wallColors [[buffer(3)]]
                      ){
    
    uint gidIndex = gid.x * intParams[2] + gid.y;
    uint sampleNumber = intParams[0];
    uint sysTime = intParams[1];
    float xResolution = float(intParams[2]);
    float yResolution = float(intParams[3]);
    int sphereCount = int(intParams[4]);
    
    float2 fragCoord = float2(gid.x, gid.y);
    
    float2 iResolution = float2(xResolution,yResolution);
    
    //Get the inColor
    float4 inColor = inTexture.read(gid).rgba;
    
    float2 iMouse = float2(0,0);
    
    uint seed = sysTime + iResolution.y * fragCoord.x / iResolution.x + fragCoord.y / iResolution.y;
    float2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
    float3 camPos = float3(0,0,10); //float3((2. * (.5*iResolution.xy) / iResolution.xy - 1.) * float2(48., 40.) + float2(50., 40.8), 169.);
    float3 cz = normalize(float3(50., 40., 81.6) - camPos);
    float3 cx = float3(1., 0., 0.);
    float3 cy = normalize(cross(cx, cz)); cx = cross(cz, cy);
    float3 color = float3(0.);
    for (int i = 0; i < SAMPLES; ++i)
    {
#ifdef DEBUG
        float3 test = radiance(Ray(camPos, normalize(.53135 * (iResolution.x/iResolution.y*uv.x * cx + uv.y * cy) + cz)));
        if (dot(test, test) > 0.) color += float3(1.); else color += float3(0.5,0.,0.1);
#else
        color += radiance(Ray{camPos, normalize(.53135 * (iResolution.x/iResolution.y*uv.x * cx + uv.y * cy) + cz)}, &seed);
#endif
    }
    //fragColor = float4(pow(clamp(color/float(SAMPLES), 0., 1.), float3(1./2.2)), 1.);
    
    
    outTexture.write(mix(float4(color,1.0), inColor, float(sampleNumber)/float(sampleNumber + 1)), gid);
}
