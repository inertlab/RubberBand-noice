//
//  Spherex.swift
//  RubberBand
//
//  Created by Fernando on 1/15/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import Foundation
import SceneKit


/// reference to highway 3D model and model parts
class Spherex {
	/// orbx is the group node orb and glow belong too
	var orbx: SCNNode
	var glow: SCNNode
	let orb: SCNNode
	
	init (_ scn: SCNScene){
		self.orbx = scn.rootNode.childNode(withName: "spherex", recursively: false)!
		self.orb = orbx.childNode(withName: "sphere", recursively: false)!
		self.glow = orbx.childNode(withName: "glow", recursively: true)!
	}
	
	/// resets highway and sphere to it's initial state, off screen with no notes or beats
	func reset() {
		sphere_initialstate()
	}
	
	func flow(multiplier: Int) {
		switch multiplier {
		case 1:
			sphere_initialstate()
		case 2, 3:
			pulsenode(node: glow)
		case 4:
//			make sure the orb is in the right place
			orb.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0.75
			spin()
		default:
			break
		}
	}
	
	func increment() {
		orb.geometry?.firstMaterial?.diffuse.contentsTransform.m41 += 0.025
	}
}

private extension Spherex {
	
	func sphere_initialstate() {
		glow.removeAllActions()
		orb.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0
		glow.opacity = 0
	}
	
	func spin()  {
		glow.runAction(SCNAction.repeatForever(spinpulse), forKey: "spin")
	}
	
	func pulsenode(node: SCNNode) {
		node.geometry?.firstMaterial?.diffuse.contentsTransform.m41 += 0.5
		node.runAction(pulsequick)
	}
	
	/// pulse On then Off - once
	/// total duration should = spinpulse total duration
	var pulse:SCNAction {
		let pulsef = SCNAction.fadeOpacity(by: 0.9, duration: 0.5)
		let pulseb = SCNAction.fadeOpacity(by: -0.9, duration: 2.5)
		let sequence = SCNAction.sequence([pulsef, pulseb])
		return sequence
	}
	
	/// pulse On then Off - once
	/// total duration should = spinpulse total duration
	var pulsequick:SCNAction {
		let pulsef = SCNAction.fadeOpacity(by: 0.6, duration: 0.25)
		let pulseb = SCNAction.fadeOpacity(by: -0.6, duration: 0.75)
		let sequence = SCNAction.sequence([pulsef, pulseb])
		return sequence
	}
	
	/// spin and pulse forever
	var spinpulse:SCNAction {
		let spin = SCNAction.rotateBy(x: 0, y: 0, z: 0.75, duration: 3)
		let group = SCNAction.group([pulse, spin])
		return group
	}
	
	/// turns light on asphalt off
	var shinedown:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.intensity")
			animation.fromValue = 0
			animation.toValue = 0.2
			animation.duration = 0.5
			animation.repeatCount = 0
		return animation
	}
}
