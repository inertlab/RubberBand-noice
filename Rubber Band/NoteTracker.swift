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



let particleDir = "art.scnassets/particles/"
let burst = SCNParticleSystem(named: "burst.scnp", inDirectory: particleDir)
//let spartiscle = SCNParticleSystem(named: "sparticle.scnp", inDirectory: particleDir)

/// note tracker is attached to triggers on the highway. depending on the trigger, it tracks notes hit
class NoteTracker {
	let posy 		= 0.5
	var nscore 		= 0
	var kick 		= false
	var count 		= CGFloat(0)
	let particle 	= SCNParticleSystem(named: "burst.scnp", inDirectory: particleDir)
	let note:		DrumKit
	let trigger:	SCNNode
	let burst:		SCNNode
	let glow:		SCNNode

	init(note: DrumKit){
		self.note 		= note
		self.particle?.particleColor = note.metrics.color
		switch self.note {
		case .r_snare:
			self.trigger 	= hwy.base.childNode(withName: "red"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "rburst"		, recursively: false)!
			self.glow 		= hwy.base.childNode(withName: "glow_red"	, recursively: false)!
		case .y_tom, .y_hihat:
			self.trigger 	= hwy.base.childNode(withName: "yellow"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "yburst"		, recursively: false)!
			self.glow 		= hwy.base.childNode(withName: "glow_yellow", recursively: false)!
		case .b_tom, .b_ride:
			self.trigger 	= hwy.base.childNode(withName: "blue"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "bburst"		, recursively: false)!
			self.glow 		= hwy.base.childNode(withName: "glow_blue"	, recursively: false)!
		case .o_bass:
			self.kick 		= true
			self.trigger 	= hwy.base.childNode(withName: "kburst"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "kburst"		, recursively: false)!
			self.glow 		= hwy.base.childNode(withName: "glow_blue"	, recursively: false)!
		case .g_tom, .g_crash:
			self.trigger 	= hwy.base.childNode(withName: "green"		, recursively: false)!
			self.burst 		= hwy.base.childNode(withName: "gburst"		, recursively: false)!
			self.glow 		= hwy.base.childNode(withName: "glow_green"	, recursively: false)!
		}
	}

	
	func checkHit() { // this more efficient than a dictionary
		let max = hwy.pista.position.z + pace.hitwindow
		//		let min = pista.position.z - pace.hitwindow
		for gem in hwy.gems.childNodes {
			
			if gem.categoryBitMask == self.note.metrics.bit {
				if gem.position.z < max {
					gem.removeFromParentNode()
					hit()
				}else{
					miss()
				}
				break
			}
		}
	}
	
	func hit() {
		scorekeeper.scoreOneUp()
		nscore += 1
		burstit()
	}
	
	func miss() {
		scorekeeper.scoreMiss()
		self.burst.removeAllActions()
		self.glow.opacity = 0
		self.trigger.addAnimation(thumpmiss, forKey: "selfllumination")
	}
	
	/// sends notification from drumkit to main process
	func notify() {
		drumCenter.post(name: drumNotification, object: self)
	}
	
	
	private let wait = SCNAction.wait(duration: 0.25)
	private let rotate = SCNAction.rotate(by: 0.75, around: SCNVector3(0, 1, 0), duration: 0.25)
}


private extension NoteTracker {
	/// a collection of the trigger animations for when player scores or misses
	func burstit () {
		self.burst.removeAllActions()
		if kick {
			if self.count < 1 {
				self.count += 0.075
			}else{
				self.count = 0
			}
			self.burst.geometry?.firstMaterial?.emission.intensity = 1
			self.burst.addAnimation(lightning, forKey: "emission")
			self.burst.geometry?.firstMaterial?.emission.contentsTransform.m41 = self.count
			self.burst.runAction(wait){
				self.burst.geometry?.firstMaterial?.emission.intensity = 0.001
			}
		}else{
//			self.glow.removeAllActions()
			splat(node: trigger)
//			self.glow.opacity = 1
			self.trigger.addParticleSystem(self.particle!)
//			self.trigger.addAnimation	(thump		, forKey: "selfIllumination")
			self.burst.addAnimation		(animup		, forKey: "emission"		)
			self.burst.addAnimation		(animdown	, forKey: "multiply"		)
			self.burst.runAction		(self.rotate)
			self.burst.geometry?.firstMaterial?.multiply.contentsTransform.m41 += 0.1
//			self.glow.runAction(wait){
//				self.glow.opacity = 0
//			}
		}
	}
	// MARK: animations
	/// animation for kick score
	var lightning:CABasicAnimation  {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.contentsTransform.m11")
			animation.fromValue 		= 0
			animation.toValue 			= 0.76
			animation.duration 			= 0.25
			animation.repeatCount 		= 0
			animation.timingFunction 	= CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		return animation
	}
	
	/// transforms the colore gradient upward
	var animup:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.contentsTransform.m42")
			animation.fromValue 		= 0.55
			animation.toValue 			= 1
			animation.duration 			= 0.25
			animation.autoreverses 		= false
			animation.repeatCount 		= 0
			animation.timingFunction 	= CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		return animation
	}
	
	/// transforms burst pattern upward
	var animdown:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.multiply.contentsTransform.m42")
			animation.byValue 			= -0.32
			animation.duration 			= 0.25
			animation.isCumulative 		= true
			animation.repeatCount 		= 0
			animation.timingFunction 	= CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		return animation
	}
	
	var waiter:SCNAction {
		return SCNAction.wait(duration: 0.25)
	}
	
	/// makes trigger fade to black and back. used when player misses and scores
	var thump:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.intensity")
			animation.fromValue 	= 0
			animation.toValue 		= 1
			animation.duration 		= 0.1
			animation.autoreverses 	= true
			animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
		return animation
	}
	
	var thumpmiss:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.selfIllumination.intensity")
		animation.fromValue 	= 0.5
		animation.toValue 		= 0
		animation.duration 		= 0.1
		animation.autoreverses 	= true
		return animation
	}
	
	func splat(node: SCNNode)  {
		node.addAnimation(splatx, forKey: "scalex")
		node.addAnimation(splatz, forKey: "scalez")
		node.addAnimation(thump, forKey: "thump")
	}
	var splatx:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "transform.scale.x")
		animation.fromValue 	= 1
		animation.toValue 		= 1.2
		animation.duration 		= 0.075
		animation.autoreverses 	= true
		return animation
	}
	var splatz:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "transform.scale.z")
		animation.fromValue 	= 1
		animation.toValue 		= 1.2
		animation.duration 		= 0.075
		animation.autoreverses 	= true
		return animation
	}
	
	func twitch () {
		self.trigger.position.y = -0.075
		self.trigger.runAction(waitflash){
			self.trigger.position.y = 0
		}
	}
}



var kick 	= NoteTracker(note: .o_bass)
var snare 	= NoteTracker(note: .r_snare)
var yellowC = NoteTracker(note: .y_hihat)
var blueC 	= NoteTracker(note: .b_ride)
var greenC 	= NoteTracker(note: .g_crash)
var yellowT = NoteTracker(note: .y_tom)
var blueT 	= NoteTracker(note: .b_tom)
var greenT 	= NoteTracker(note: .g_tom)

