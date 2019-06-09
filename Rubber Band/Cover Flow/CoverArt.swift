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

class CoverArt: SCNNode, IDable  {
	let id:UUID
	init(id: UUID) {
		self.id = id
		super.init()
		self.geometry = SCNPlane(width: 0.8, height: 0.8)
		self.geometry?.firstMaterial = (cover.geometry?.firstMaterial?.copy() as! SCNMaterial)
		self.geometry?.firstMaterial?.diffuse.contents = nil
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

fileprivate let albumscn = SCNScene(named: "art.scnassets/scns/album.scn")!
fileprivate let cover 	= albumscn.rootNode.childNode(withName: "cover", recursively: false)!
