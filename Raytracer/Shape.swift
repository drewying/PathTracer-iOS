//
//  Shape.swift
//  Raytracer
//
//  Created by Drew Ingebretsen on 12/13/14.
//  Copyright (c) 2014 Drew Ingebretsen. All rights reserved.
//

import UIKit

protocol Shape{
    func intersect(ray:Ray, distance:Double) -> Hit;
    func getMaterial() -> Material;
}