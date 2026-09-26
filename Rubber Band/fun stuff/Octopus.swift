//
//  Octopus.swift
//  noice
//
//  Created by Fernando Zamora on 1/24/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import GameKit

class Octopus {
	var arms = Set<GKEntity>()
	var joints = Set<GKEntity>()
	let node: SCNNode
	
	init(arm: SCNNode) {
		self.node = menuScene.rootNode.childNode(withName: "octopus", recursively: false)!
		setup()
		for joint in joints {
			if let comp = joint.component(ofType: JointComp.self) {
				comp.node.replaceChildNode(comp.node.childNodes[0], with: arm.childNodes[comp.index].clone())
				comp.node.childNodes[0].position.x = 0
			}
		}
	}
	
	init() {
		self.node = menuScene.rootNode.childNode(withName: "octopus", recursively: false)!
		setup()
	}
	
	init(octonode: SCNNode) {
		self.node = octonode
		setup()
	}
	
	private func setup() {
		for arm in node.childNodes {
			let direction:CGFloat
			if arm.rotation.z > 0 {
				direction = 60
			} else {
				direction = -60
			}
			for i in 0...5 {
				if let joint = arm.childNode(withName: "joint\(i)", recursively: true) {
					let ent = GKEntity()
					ent.addComponent(JointComp(node: joint, speed: Double((i + 1)), dir: direction, index: i))
					joints.insert(ent)
				}
			}
			
			let entity = GKEntity()
			entity.addComponent(OctoArmComp(node: arm))
			arms.insert(entity)
			switch arm.name {
			case "arm1":
				if let node = arm.childNode(withName: "instrument", recursively: true){
					entity.addComponent(OctoInstrumentComp(node: node, hand: .left))
				}
				
			case "arm2":
				if let node = arm.childNode(withName: "instrument", recursively: true){
					entity.addComponent(OctoInstrumentComp(node: node, hand: nil))
				}
			default:
				break;
			}
		}
	}
	
	func updatearms() {
		for arm in arms {
			if let hand = arm.component(ofType: OctoInstrumentComp.self) {
				hand.updateinstrument()
			}
		}
	}
	
	func comein() {
		for arm in arms {
			arm.component(ofType: OctoArmComp.self)?.comein()
		}
		for joint in joints {
			joint.component(ofType: JointComp.self)?.pose()
		}
	}
	
	func leave() {
		for arm in arms {
			arm.component(ofType: OctoArmComp.self)?.leave()
		}
	}
}
