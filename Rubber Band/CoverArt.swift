//
//  CoverArt.swift
//  RubberBand
//
//  Created by Fernando on 8/9/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit


protocol IDable {
	var id:UUID {get}
//	var node:SCNNode {get}
}

extension IDable where Self: SCNNode {
	func printer(){
		print(self.id)
	}
}


class CoverArt: SCNNode, IDable  {
	let id:UUID
	init(id: UUID) {
		self.id = id
		super.init()
		self.geometry = SCNPlane(width: 0.8, height: 0.8)
		self.geometry?.firstMaterial = material
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


fileprivate let normal 	= NSImage(byReferencingFile: "art.scnassets/textures/album/album_normal.jpg")
//fileprivate let mask 	= #imageLiteral(resourceName: "watercolor.jpg")
fileprivate let mask 	= NSImage(byReferencingFile: "art.scnassets/textures/album/album_mask.jpg")
fileprivate let shiny 	= NSImage(byReferencingFile: "art.scnassets/textures/album/album_shiny.jpg")
fileprivate let noart	= NSImage(byReferencingFile: "art.scnassets/textures/album/album_noart.jpg")

fileprivate var material:SCNMaterial  {
	let mat = SCNMaterial()
		mat.isDoubleSided 			= false
		mat.normal.contents 		= normal
		mat.transparent.contents 	= mask
		mat.transparencyMode 		= .rgbZero
		mat.reflective.contents 	= shiny
	return mat
}

fileprivate func inicover (albumart: NSImage) -> SCNNode {
	let plane = makeCover()
	plane.geometry?.firstMaterial?.diffuse.contents 	= albumart
	plane.geometry?.firstMaterial?.isDoubleSided 		= false
	plane.geometry?.firstMaterial?.normal.contents 		= normal
	plane.geometry?.firstMaterial?.transparent.contents = mask
	plane.geometry?.firstMaterial?.transparencyMode 	= .rgbZero
	plane.geometry?.firstMaterial?.reflective.contents 	= shiny
	return plane
}

fileprivate func makeCover () -> SCNNode {
	let plane = SCNNode()
	plane.geometry = SCNPlane(width: 0.8, height: 0.8)
	
	return plane
}

