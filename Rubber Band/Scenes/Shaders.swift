//
//  Shaders.swift
//  noice
//
//  Created by Fernando Zamora on 3/16/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation


var wiggle = """
float speed = 2.5;
float amplitude = _geometry.color.x * 0.025;

vec4 WorldPos = _geometry.position;

float sine = sin(u_time * speed + (WorldPos.x * 10)) * amplitude;
float cose = cos(u_time * speed + ((WorldPos.z + WorldPos.x) * 3)) * amplitude;
WorldPos.y += sine;
WorldPos.y += cose;

_geometry.position = WorldPos;
"""

var shine = """
float AO = pow(_surface.ambientOcclusion, 3);
float fresnelBasis = saturate(dot(_surface.view, _surface.normal));
float fresnel = saturate(pow(1.-fresnelBasis , 12)) * (pow(AO,5));
vec3 color = fresnel * 2 * vec3(1,1,1);
_output.color =  _output.color + vec4(color,1);
"""
