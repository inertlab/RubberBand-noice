//
//  NoteTracker.swift
//  RubberBand
//
//  Created by Fernando Zamora on 2/26/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit
import GameplayKit


let particleDir = "art.scnassets/particles/"
let burst = SCNParticleSystem(named: "burst.scnp", inDirectory: particleDir)

/// note tracker is attached to triggers on the highway. depending on the trigger, it tracks notes hit
class DrumTrigger: Burstable {
	let posy 		= 0.5
	var nscore 		= 0
	var kick 		= false
	let particle 	= SCNParticleSystem(named: "burst.scnp", inDirectory: particleDir)
	let trigger		: SCNNode
	let burst		: SCNNode
	var reactor 	= SCNNode()

	init(btn: Button, hwy: HWY){
		self.particle?.particleColor = btn.metric.color
		switch btn {
		case .red:
			self.trigger 	= hwy.base.childNode(withName: "red"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "rburst"		, recursively: false)!
		case .yellow:
			self.trigger 	= hwy.base.childNode(withName: "yellow"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "yburst"		, recursively: false)!
		case .blue:
			self.trigger 	= hwy.base.childNode(withName: "blue"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "bburst"		, recursively: false)!
		case .orange:
			self.kick 		= true
			self.trigger 	= hwy.base.childNode(withName: "peg"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "oburst"		, recursively: false)!
			self.reactor 	= hwy.base.childNode(withName: "reactor"	, recursively: false)!
		default:
			self.trigger 	= hwy.base.childNode(withName: "green"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "gburst"		, recursively: false)!
		}
	}
	
	func hit() {
		nscore += 1
		burstit()
	}
	
	func miss() {
		self.burst.removeAllActions()
		if kick {
			self.trigger.geometry?.firstMaterial?.diffuse.intensity = 1
			self.trigger.addAnimation(shrinkx, forKey: "shrink")
			self.reactor.addAnimation(kickback, forKey: "kickback")
		}
	
		self.trigger.addAnimation(thumpmiss, forKey: "selfllumination")
	}
}


private extension DrumTrigger {
	// a collection of the trigger animations for when player scores or misses
	
	/// handles the succesful hit animations
	func burstit () {
		self.burst.removeAllActions()
		if kick {
			self.trigger.geometry?.firstMaterial?.diffuse.intensity = 0
			// this changes the range of animation for the orange blob
			self.burst.geometry?.firstMaterial?.diffuse.contentsTransform.m42 += 0.25
			self.reactor.addAnimation(thump, forKey: "thump")
			self.burst.addAnimation(kickframe, forKey: "self")
			self.trigger.addAnimation(shrinkx, forKey: "shrink")
			self.reactor.addAnimation(kickback, forKey: "kickback")
		}else{
			splat(node: trigger)
			self.trigger.addParticleSystem(self.particle!)
			self.burst.addAnimation		(animup		, forKey: "emission")
			self.burst.addAnimation		(animdown	, forKey: "multiply")
			self.burst.geometry?.firstMaterial?.multiply.contentsTransform.m41 += 0.1
		}
	}
	// MARK: animations
	/// transforms the colore gradient upward
	var animup:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.contentsTransform.m42")
			animation.fromValue 		= 0.55
			animation.toValue 			= 1
			animation.duration 			= 0.2
			animation.autoreverses 		= false
			animation.repeatCount 		= 0
			animation.timingFunction 	= CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
		return animation
	}
	
	/// transforms burst pattern upward
	var animdown:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.multiply.contentsTransform.m42")
			animation.byValue 			= -0.32
			animation.duration 			= 0.2
			animation.isCumulative 		= true
			animation.repeatCount 		= 0
			animation.timingFunction 	= CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
		return animation
	}
	
	func splat(node: SCNNode)  {
		node.addAnimation(splatx, forKey: "scalex")
		node.addAnimation(splatz, forKey: "scalez")
		node.addAnimation(thump,  forKey: "thump")
	}
	
	var splatx:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "transform.scale.x")
		animation.fromValue 	= 1.25
		animation.toValue 		= 1
		animation.duration 		= 0.25
		return animation
	}
	
	var kickback:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "transform.scale.x")
		animation.fromValue 	= 1.025
		animation.toValue 		= 1
		animation.duration 		= 0.25
		return animation
	}
	
	/// animation for drum_peg
	var shrinkx:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "transform.scale.x")
		animation.fromValue 	= 0.92
		animation.toValue 		= 1
		animation.duration 		= 0.4
		animation.autoreverses 	= false
		return animation
	}
	
	var splatz:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "transform.scale.y")
		animation.fromValue 	= 1.25
		animation.toValue 		= 1
		animation.duration 		= 0.25
		return animation
	}
	
	var kickframe:CAKeyframeAnimation {
		let animation = CAKeyframeAnimation(keyPath: "geometry.firstMaterial.diffuse.contentsTransform.m41")
			animation.values = [0.8, 0.6, 0.4, 0.2, 0]
			animation.keyTimes = [0, 0.025, 0.045, 0.9, 0.18]
			animation.calculationMode = CAAnimationCalculationMode.discrete
		return animation
	}
}
