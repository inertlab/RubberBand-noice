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
class HWY {
	/// parent geometry of highway, not to be confused with rootnode or scene
	let base: SCNNode
	/// the animated track of the highway
	let pista: SCNNode
	/// the animated note gems not including the activation gems handled by starpower
	let notes: SCNNode
	/// the graphic lines representing single and half beats
	var beatlines: SCNNode
	var spherex: Spherex
	let asphalt: SCNNode
	let backdrop: SCNNode
	var flow:Bool = false {
		didSet {
			if self.flow {
				asphalt.addAnimation(lightup, forKey: "selfIllumination")
				asphalt.geometry?.firstMaterial?.multiply.intensity = 0.98
				backdrop.runAction(SCNAction.fadeIn(duration: 0.65))
				
			} else {
				backdrop.runAction(SCNAction.fadeOut(duration: 0.35))
				asphalt.addAnimation(lightdown, forKey: "selfIllumination")
				asphalt.geometry?.firstMaterial?.multiply.intensity = 0.85
			}
			setflow()
		}
	}
	
	var starpower:Bool 	= false {
		didSet {
			// updating scorekeeper is the only place that updates spherex
			stagemc.track.scorekeeper.updatexlabel()
			setflow()
		}
	}

	init(_ scn: SCNScene){
		self.backdrop = scn.rootNode.childNode(withName: "bg", recursively: false)!
		self.base = scn.rootNode.childNode(withName: "highway", recursively: false)!
		self.pista = base.childNode(withName: "pista", recursively: false)!
		self.notes = pista.childNode(withName: "gems", recursively: false)!
		self.beatlines = pista.childNode(withName: "beats", recursively: false)!
		self.asphalt = base.childNode(withName: "asphalt", recursively: false)!
		self.spherex = Spherex(scn)
	}
	
	/// resets highway and sphere to it's initial state, off screen with no notes or beats
	func reset() {
		asphalt_initialstate()
		base_initialstate()
		remove_notes_beats()
	}
}

private extension HWY {
	
	/// sets the texture for the hwy by checking status of SP and Multiplier
	func setflow()  {
		
		if flow {
			if starpower {
				asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0.75
			} else {
				asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0.25
			}
		} else {
			if starpower {
				asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0.5
			} else {
				asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0
			}
		}
	}
	
	func base_initialstate() {
		base.position.y = -10
	}
	
	func asphalt_initialstate() {
		asphalt.removeAllAnimations()
		asphalt.geometry?.firstMaterial?.multiply.intensity = 0.85
		asphalt.geometry?.firstMaterial?.diffuse.intensity = 0.5
		asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0
	}
	
	func removenodes(node: SCNNode) {
		for node in node.childNodes {
			node.removeFromParentNode()
		}
	}
	
	func remove_notes_beats() {
		removenodes(node: notes)
		removenodes(node: beatlines)
	}
	
	/// lights up the asphalt
	var lightup:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.diffuse.intensity")
			animation.fromValue = 0.5
			animation.toValue = 1.5
			animation.duration = 0.5
			animation.fillMode = CAMediaTimingFillMode.forwards
			animation.repeatCount = 0
			animation.isRemovedOnCompletion = false
		return animation
	}
	
	/// turns light on asphalt off
	var lightdown:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.diffuse.intensity")
			animation.fromValue = 1.5
			animation.toValue = 0.5
			animation.duration = 0.25
			animation.autoreverses = false
			animation.fillMode = CAMediaTimingFillMode.forwards
			animation.repeatCount = 0
			animation.isRemovedOnCompletion = false
		return animation
	}
}



