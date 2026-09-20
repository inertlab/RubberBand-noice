//
//  Triggers.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/29/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit

protocol TriggerDelegate {
	func tailended()
}

class StringTrigger {

	let note: 	Button
	let node: 	SCNNode
	let particle:SCNParticleSystem?
	let pressed:SCNMaterial?
	let neutral:SCNMaterial?
	let missed:SCNMaterial?
	let hitmat:SCNMaterial?
	let treck:SCNParticleSystem?
	/// the ring around the buttons
	let btnring:SCNNode?
	let burner:SCNParticleSystem?
	
	init (note: Button, hwy: HWY) {
		let scn = SCNScene(named: "art.scnassets/particles/particles.scn")
		
		treck 		= scn?.rootNode.childNodes.first?.particleSystems?.first
		particle 	= scn?.rootNode.childNodes[1].particleSystems?.first
		burner 		= scn?.rootNode.childNodes[2].particleSystems?.first
		particle?.particleColor = note.metric.color
		burner?.particleColor 	= note.metric.color
		
		let frets 	= hwy.base.childNode(withName: "frets", recursively: false)
		let bases 	= frets?.childNode(withName: "base", recursively: false)
		let buttons = frets?.childNodes.first!
		let green 	= buttons?.childNode(withName: "green", recursively: false)
		self.note 	= note
		
		if note == .green {
			node = green!
		} else {
			node = buttons?.childNode(withName: note.string, recursively: false) ?? SCNNode()
		}
		btnring = bases?.childNode(withName: note.string, recursively: false)
		btnring?.geometry?.firstMaterial = btnring?.geometry?.firstMaterial?.copy() as? SCNMaterial
		
		neutral = green!.geometry?.firstMaterial
		pressed = green!.geometry?.material(named: "pressed") ?? neutral
		missed = green!.geometry?.material(named: "missed") ?? neutral
		hitmat = neutral?.copy() as? SCNMaterial
		hitmat?.diffuse.intensity = 3
	}
	
	func fretted() {
		node.position.y = -0.075
		node.geometry?.firstMaterial = pressed
		toggle(true)
	}
	
	func open() {
		node.position.y = -0.1
		node.geometry?.firstMaterial = neutral
		toggle(false)
	}
	
	func burn() {
		node.addParticleSystem(burner!)
	}
	
	func hit(){
		node.geometry?.firstMaterial = hitmat
		btnring?.geometry?.firstMaterial?.diffuse.intensity = 4
		node.runAction(SCNAction.wait(duration: 0.25), forKey: "wating") {
			self.node.geometry?.firstMaterial = self.pressed
			self.btnring?.geometry?.firstMaterial?.diffuse.intensity = 1
		}
		node.removeAllParticleSystems()
		node.addParticleSystem(particle!)
		node.addParticleSystem(treck!)
	}
	
	
	func miss(){
		node.geometry?.firstMaterial = missed
		btnring?.geometry?.firstMaterial?.diffuse.intensity = 0
		node.runAction(SCNAction.wait(duration: 0.1), forKey: "wating") {
			self.node.geometry?.firstMaterial = self.neutral
			self.btnring?.geometry?.firstMaterial?.diffuse.intensity = 1
		}
	}
	
	func thump(node: SCNNode)  {
//		node.addAnimation(thump, forKey: "thump")
	}
}

private extension StringTrigger {
	func toggle(_ on: Bool) {
		if on {
//			burst.opacity = 1
		} else {
//			burst.opacity = 0
		}
	}
	
	
}

