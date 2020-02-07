//
//  TailComponent.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/6/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//


import Foundation
import SceneKit
import GameplayKit



final class Tailanimate: GKComponent {
	var start:TimeInterval
	
	var tail:TailComp {
		return (entity?.component(ofType: TailComp.self))!
	}
	
	init(_ time: TimeInterval) {
		self.start = time
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func update (_ cgTime: CGFloat) {
		//	if let tail = self.entity?.component(ofType: TailComp.self) {
		let diff 	= cgTime - tail.node.position.z
		let remain 	= tail.length - diff
		let scale 	= ((remain / tail.length) - 1) * -1
		// scale is maxed out, remove component from system
		if scale > 1 {
			removeself()
		}
		for n in tail.node.childNodes {
			n.geometry?.firstMaterial?.transparent.contentsTransform.m42 	= scale
			n.geometry?.firstMaterial?.diffuse.contentsTransform.m42 		+= 0.022
		}
	}
	
	func keyup (_ event: Button) {
		if let chord = entity?.component(ofType: NoteComp.self) {
			if chord.chord.contains(event) {
				tail.maketailgray()
			}
		}
	}
	
	/// If a key is pressed during sustain, sustain is canceled
	/// - Parameter event: Button pressed
	func keydown (_ event: Button) {
		if let chord = entity?.component(ofType: NoteComp.self) {
			if chord.chord.count == 1 {
				if event.rawValue >= chord.chord.first!.rawValue {
					tail.maketailgray()
				}
				return
			}
			tail.maketailgray()
		}
	}
}

private extension Tailanimate {
	func removeself () {
		
		stagemc.track.tailsystem.removeComponent(foundIn: self.entity!)
		//		self.entity?.removeComponent(ofType: Tailanimate.self)
		//		self.entity?.removeComponent(ofType: TailComp.self)
		print (stagemc.track.tailsystem.components.count)
		//		self.willRemoveFromEntity()
//		stagemc.track.notes.remove(self.entity!)
	}
}


class TailComp: GKComponent {
	/// Length of tail in CGfloats already calculated with pace.fps
	///
	/// change this to end of note as duration is not acurate when translated to beats
	var length		: CGFloat
	let node 		= SCNNode()
	init(_ length 	: CGFloat) {
		self.length = length
		self.node.scale.z = length
		
		//		self.node.categoryBitMask = GemBit.dead
		self.node.pivot = SCNMatrix4MakeTranslation(0, 0, -0.5)
		//		self.node.simdPivot = simd_matrix4x4(simd_quatf(ix: -0.5, iy: 0, iz: 0, r: 0))
		super.init()
	}
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func update(_ cgTime: CGFloat) {
		
		for n in node.childNodes {
			n.geometry?.firstMaterial?.multiply.contents = NSColor.rbRed
			
			//				n.geometry?.firstMaterial?.transparent.contentsTransform.m42 = lapse
		}
		//			node.scale.z = lapse
	}
	
	func maketailgray() {
		for node in node.childNodes {
			stagemc.track.tailsystem.removeComponent(foundIn: self.entity!)
			node.geometry?.firstMaterial?.multiply.contents = NSColor.black
			node.geometry?.firstMaterial?.diffuse.contentsTransform.m22 = 1
			node.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = -0.99
		}
	}
}

