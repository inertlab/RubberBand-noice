//
//  OctopustComponent.swift
//  noice
//
//  Created by Fernando Zamora on 1/8/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit


final class OctoArmComp: GKComponent {
	private let times = [4, 5.5, 7, 8]
	let rotation: CGFloat
	let node: SCNNode
	let bubbles = instruments.rootNode.childNode(withName: "bubbles", recursively: false)?.particleSystems?.first
	init(node: SCNNode) {
		self.node = node
		self.rotation = node.rotation.z
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func comein() {
		node.removeAllActions()
		node.addParticleSystem(bubbles!)
		node.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.5)) {
			self.wave()
		}
	}
	func leave() {
		node.removeAllActions()
		node.removeAllParticleSystems()
		node.runAction(SCNAction.rotateTo(x: 0, y: 0, z: rotation, duration: 0.25))
	}
	func wave() {
		node.runAction(
			SCNAction.sequence([
				SCNAction.rotateBy(x: 0, y: 0, z: 0.065, duration: self.times.randomElement()!),
				SCNAction.rotateBy(x: 0, y: 0, z: -0.065, duration: self.times.randomElement()!),
				SCNAction.rotateBy(x: 0, y: 0, z: 0.03, duration: 3)
			])
		)
	}
}


final class OctoInstrumentComp: GKComponent {
	enum Hand {
		case left, right
	}
	let node: SCNNode
	var hand: Hand
	var particle = SCNParticleSystem()
	init(node: SCNNode, hand: Hand?) {
		self.node = node
		if let poof = instruments.rootNode.childNode(withName: "poof", recursively: false) {
			self.particle = poof.particleSystems![0]
		}
		self.hand = hand ?? .right
		super.init()
		updateinstrument()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func willRemoveFromEntity() {
		node.removeAllParticleSystems()
	}
	
	func updateinstrument() {
		node.childNodes.last?.removeFromParentNode()
		if let inst = getinstrument() {
			node.addChildNode(inst)
			node.childNodes.last?.addParticleSystem(particle)
		}
	}
	
	private func getinstrument() -> SCNNode? {
		let name: String
		switch User.current.instrument {
		case .prodrums:
			name = "prostick"
		case .drums:
			name = "dumbstick"
		case .bass:
			if hand == .right {return nil}
			name = "bass"
		case .guitar:
			if hand == .left {return nil}
			name = "guitar"
		case .keys:
			if hand == .right {return nil}
			name = "keytar"
		}
		return instruments.rootNode.childNode(withName: name, recursively: false)!.clone()
	}
}


final class JointComp: GKComponent {
	let angles:[CGFloat] = [1.05, 1.1, 1.15]
	let anglex:[CGFloat] = [0.8, 0.95, 0.75]
	let speed: Double
	let node: SCNNode
	let angle: CGFloat
	let start: CGFloat
	let index: Int
	init(node: SCNNode, speed: Double, dir: CGFloat, index: Int) {
		self.node 	= node
		self.angle 	= node.eulerAngles.z
		self.speed 	= speed
		self.start 	= dir
		self.index 	= index
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func pose() {
		node.removeAllActions()
		node.rotation.z = start 
		node.runAction(SCNAction.sequence([
			SCNAction.rotateTo(x: 0, y: 0, z: angle * angles.randomElement()!, duration: speed * 0.25),
			SCNAction.rotateTo(x: 0, y: 0, z: angle * anglex.randomElement()!, duration: speed * 0.25),
			SCNAction.rotateTo(x: 0, y: 0, z: angle, duration: speed * 0.5),
		]
		))
	}
}

fileprivate let instruments = SCNScene(named: "art.scnassets/scns/octo_instruments.scn")!

