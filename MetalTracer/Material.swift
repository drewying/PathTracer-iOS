//
//  Material.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit

enum Material:UInt32{
    case DIFFUSE = 0;
    case SPECULAR = 1;
    case DIELECTRIC = 2;
    case TRANSPARENT = 3;
    case LIGHT = 4;
}
