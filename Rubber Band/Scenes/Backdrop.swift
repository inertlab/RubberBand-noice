//
//  Backdrop.swift
//  noice
//
//  Created by Fernando Zamora on 3/15/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import SceneKit

/// states that react in the background. all custom background should adopt this state to interact with music
enum BGState {
	case combo2, combo3, combo4, start, idle, groove, angry, seeingstars
}

/// Protocol for backgrounds
protocol Backdrop {
	var active: Bool {get set}
	var node: SCNNode {get set}
	var state: BGState {get set}
	func state(_ state: BGState)
	func setnode(node: SCNNode)
}

class Pentapuss: Backdrop {
	var node = SCNNode()
	var active = false
	var color = NSColor.black
	private var material = SCNMaterial()
	private var animation = SCNAnimationPlayer()

	var state: BGState = .idle {
		didSet {
			switch state {
			case .start:
				start()
			case .combo2:
				animation.speed = 0.65
				material.addAnimation(NCAnimation.flash(color: NCColor.combo2), forKey: nil)
			case .combo3:
				animation.speed = 0.55
				material.addAnimation(NCAnimation.flash(color: NCColor.combo3), forKey: nil)
			case .combo4:
				animation.speed = 0.35
				material.removeAllAnimations()
				material.addAnimation(NCAnimation.glow(), forKey: nil)
				material.addAnimation(NCAnimation.flow(), forKey: nil)
				material.addAnimation(NCAnimation.intensify(property: "multiply", 0.5), forKey: nil)
				spartiscle?.speedFactor = 0.2
			case .idle:
				animation.speed = 0.75
				spartiscle?.speedFactor = 1
				material.removeAllAnimations()
				material.diffuse.intensity = 1
				material.multiply.intensity = 0
				material.selfIllumination.intensity = 0
				material.addAnimation(NCAnimation.flash(color: NSColor.red), forKey: nil)
				NCAnimation.retreat(node: node)
			default: break
			}
		}
	}
	
	func setnode(node: SCNNode) {
		self.active = true
		self.node = node
		node.position.z = -10
		
		self.animation = (node.childNode(withName: "joint0", recursively: true)?.animationPlayer(forKey: "animation1"))!
	
		
		let nodes = node.childNodes { (node, stop) -> Bool in
			if node.name == "tentacle" {return true}
			return false
		}
		
		let joints = node.childNodes { (node, stop) -> Bool in
			if node.name == "joint0" {return true}
			return false
		}
		
		for j in joints {
			j.addAnimationPlayer(animation, forKey: "animation1")
		}
		
		for n in nodes {
			// if i apply shader to geometry it won't break animations
			n.geometry?.shaderModifiers = [.geometry: wiggle]
		}
		
		if !nodes.isEmpty {
			material = nodes[0].geometry!.materials[0]
			color = material.diffuse.contents as! NSColor
			material.diffuse.intensity = 0
		}

	}
	
	func state(_ state: BGState) {
		if active {
			self.state = state
		}
	}
	
	private func start() {
		material.removeAllAnimations()
		animation.speed = 0.65
		node.runAction(SCNAction.move(to: SCNVector3(0, 0, 0), duration: 2)){
			self.material.addAnimation(NCAnimation.intensify(property: "diffuse"), forKey:nil)
		}
	}
}

enum NCAnimation {
	static func retreat(node: SCNNode) {
		node.runAction(SCNAction.move(to: SCNVector3(0, 0, -1.5), duration: 0.125)) {
			node.runAction(SCNAction.move(to: SCNVector3(0, 0, 0), duration: 1.25))
		}
	}
	
	static func intensify(property: String, _ time: Double = 3 ) -> CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "\(property).intensity")
			animation.fromValue = 0
			animation.toValue = 1
			animation.duration = time
			animation.autoreverses = false
			animation.fillMode = CAMediaTimingFillMode.forwards
			animation.isRemovedOnCompletion = false
		return animation
	}
	
	static func fadeintensity(property: String ) -> CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "\(property).intensity")
			animation.fromValue = 1
			animation.toValue = 0
			animation.duration = 3
			animation.autoreverses = false
			animation.fillMode = CAMediaTimingFillMode.forwards
			animation.isRemovedOnCompletion = false
		return animation
	}

	static func grow(property: String ) -> CABasicAnimation {
		let animation = CABasicAnimation(keyPath: property)
			animation.fromValue = 1
			animation.toValue = 0.5
			animation.duration = 600
			animation.autoreverses = false
			animation.isRemovedOnCompletion = false
		return animation
	}
	
	static func flash()  -> CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "diffuse.intensity")
			animation.fromValue = 2
			animation.duration = 1
			animation.autoreverses = false
		return animation
	}
	
	static func glow()  -> CABasicAnimation {
		let ani = CABasicAnimation(keyPath: "emission.intensity")
			ani.fromValue = 0
			ani.toValue			= 1
			ani.duration = 2
			ani.autoreverses = true
			ani.timingFunction = CAMediaTimingFunction(name: .easeIn)
			ani.repeatCount = .infinity
		return ani
	}
	
	static func flow()  -> CABasicAnimation {
		let ani = CABasicAnimation(keyPath: "emission.contentsTransform.m41")
			ani.byValue = -1
			ani.duration = 30
			ani.timingFunction = CAMediaTimingFunction(name: .linear)
			ani.repeatCount = .infinity
		return ani
	}
	
	static func flash(color: NSColor)  -> CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "diffuse.contents")
			animation.fromValue = color
			animation.duration = 1
			animation.autoreverses = false
		return animation
	}
}

enum NCColor {
	static var happy = NSColor(srgbRed: 1, green: 1, blue: 0, alpha: 1)
	static var sad = NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
	static var combo2 = NSColor(srgbRed: 0, green: 1, blue: 1, alpha: 1)
	static var combo3 = NSColor(srgbRed: 1, green: 0.85, blue: 0, alpha: 1)
}

extension NSImage {
	convenience init?(gradientColors: [NSColor], imageSize: NSSize) {
		guard let gradient = NSGradient(colors: gradientColors) else { return nil }
		let rect = NSRect(origin: CGPoint.zero, size: imageSize)
		self.init(size: rect.size)
		let path = NSBezierPath(rect: rect)
		self.lockFocus()
		gradient.draw(in: path, angle: 0.0)
		self.unlockFocus()
	}
}
