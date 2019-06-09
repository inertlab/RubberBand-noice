//
//  Highway.swift
//  RubberBand
//
//  Created by Fernando Zamora on 5/12/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit

/// reference to highway 3D model and model parts
struct Hiway {
	/// parent geometry of highway, not to be confused with rootnode or scene
	let base = drumScene.rootNode.childNode(withName: "highway", recursively: false)!
	/// the animated track of the highway
	let pista		:SCNNode
	/// the animated note gems not including the activation gems handled by starpower
	let notes		:SCNNode
	/// the graphic lines representing single and half beats
	var beatlines	:SCNNode
	var spherex		:SCNNode
	var sphereglow : SCNNode
	
	let sphere = drumScene.rootNode.childNode(withName: "spherex", recursively: false)!
	init(){
		self.pista 		= base.childNode(withName	: "pista"	, recursively: false)!
		self.notes 		= pista.childNode(withName	: "gems"	, recursively: false)!
		self.beatlines 	= pista.childNode(withName	: "beats"	, recursively: false)!
		self.spherex 	= sphere.childNode(withName: "sphere", recursively: false)!
		self.sphereglow = sphere.childNode(withName: "glow", recursively: true)!
	}
}


let hwy = Hiway()
