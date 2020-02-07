//
//  Triggers.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/29/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit

class StringTrigger {
	
	let note: 	Button
	let node: 	SCNNode
	let burst: 	SCNNode
	let particle 	= SCNParticleSystem(named: "smoke.scnp", inDirectory: particleDir)
	
	init (note: Button, hwy: HWY) {
		self.note = note
		switch self.note {
		case .green:
			self.particle?.particleColor = NSColor.rbGreen
			self.node 	= hwy.base.childNode(withName: "green"		, recursively: false)!
			self.burst 	= hwy.base.childNode(withName: "gburst"		, recursively: false)!
		case .red:
			self.particle?.particleColor = NSColor.rbRed
			self.node 	= hwy.base.childNode(withName: "red"		, recursively: false)!
			self.burst 	= hwy.base.childNode(withName: "rburst"		, recursively: false)!
		case .yellow:
			self.particle?.particleColor = NSColor.rbYellow
			self.node 	= hwy.base.childNode(withName: "yellow"		, recursively: false)!
			self.burst 	= hwy.base.childNode(withName: "yburst"		, recursively: false)!
		case .blue:
			self.particle?.particleColor = NSColor.rbBlue
			self.node 	= hwy.base.childNode(withName: "blue"		, recursively: false)!
			self.burst 	= hwy.base.childNode(withName: "bburst"		, recursively: false)!
		default: // orange
			self.particle?.particleColor = NSColor.rbOrange
			self.node 	= hwy.base.childNode(withName: "orange"		, recursively: false)!
			self.burst 	= hwy.base.childNode(withName: "oburst"		, recursively: false)!
		}
	}
	
	func fretted() {
		node.position.y = 0.25
		toggle(true)
	}
	
	func open() {
		node.position.y = 0.05
		toggle(false)
	}
	
	func hit(){
//		node.addAnimation(thump, forKey: "thump")
		burst.addParticleSystem(self.particle!)
	}
	
	func thump(node: SCNNode)  {
//		node.addAnimation(thump, forKey: "thump")
	}
}

private extension StringTrigger {
	func toggle(_ on: Bool) {
		if on {
			burst.opacity = 1
		} else {
			burst.opacity = 0
		}
	}
}
