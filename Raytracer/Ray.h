//
//  Ray.h
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/14/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

#ifndef Raytracer_Ray_h
#define Raytracer_Ray_h

#include <metal_stdlib>
using namespace metal;

struct Ray{
    float3 origin;
    float3 direction;
};

#endif
