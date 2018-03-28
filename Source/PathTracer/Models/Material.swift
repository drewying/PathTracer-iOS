//
//  Material.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit

enum Material:UInt32{
    case diffuse = 0;
    case specular = 1;
    case dielectric = 2;
    case transparent = 3;
    case light = 4;
}
