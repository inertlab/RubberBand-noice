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

// i need a ref to triggers here? ouch

final class Tailanimate: GKComponent {
	
	var delegate: TriggerDelegate?
	var scoredel: ScoreDelegate?
	var pts: CGFloat = 12
	var tail:TailComp {
		return (entity?.component(ofType: TailComp.self))!
	}
	
	override func update (_ cgTime: CGFloat) {
		let diff 	= cgTime - tail.node.position.z
		let remain 	= tail.length - diff
		let scale 	= ((remain / tail.length) - 1) * -1
		scoredel?.tailupdate(scale * tail.beats * pts)
		// scale is maxed out, remove component from system
		if scale > 1 {
//			ensures total possible score is added to the score
			scoredel?.taildidend(tail.beats * pts)
			delegate?.tailended()
			removeself()
		}
		
		for n in tail.node.childNodes {
			n.geometry?.firstMaterial?.transparent.contentsTransform.m42 = scale
			n.geometry?.firstMaterial?.diffuse.contentsTransform.m42 	+= 0.022
		}
	}
	
	func keyup (_ event: Button) {
		if let chord = entity?.component(ofType: NoteComp.self) {
			if chord.chord.contains(event) {
				delegate?.tailended()
				scoredel?.taildidend(nil)
				tail.maketailgray()
			}
		}
	}
	
	/// If a key is pressed during sustain, sustain is canceled
	/// - Parameter event: Button pressed
	func keydown (_ event: Button) {
		if let chord = entity?.component(ofType: NoteComp.self) {
			if chord.chord.count == 1 {
//				if fret to the right of the tail is pressed, end it else, do nothing return
				if event.rawValue >= chord.chord.first!.rawValue {
					delegate?.tailended()
					scoredel?.taildidend(nil)
					tail.maketailgray()
				}
				return
			}
			delegate?.tailended()
			scoredel?.taildidend(nil)
			tail.maketailgray()
		}
	}
	override func didAddToEntity() {
		pts *= CGFloat(tail.node.childNodes.count)
	}
}

private extension Tailanimate {
	func removeself () {
		stagemc.track.tailsystem.removeComponent(self)
	}
}


class TailComp: GKComponent {
	/// Length of tail in CGfloats already calculated with pace.fps
	///
	/// change this to end of note as duration is not acurate when translated to beats
	var length	: CGFloat
	let node 	= SCNNode()
	let beats	: CGFloat
	
	init(_ length: CGFloat, beats: CGFloat) {
		self.length = length
		self.beats = beats
		self.node.scale.z = length
		self.node.pivot = SCNMatrix4MakeTranslation(0, 0, -0.5)
		super.init()
	}
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func update(_ cgTime: CGFloat) {
		for n in node.childNodes {
			n.geometry?.firstMaterial?.multiply.contents = NSColor.rbRed
		}
	}
	
	func maketailgray() {
		for node in node.childNodes {
//			stagemc.track.tailsystem.removeComponent(self)
			stagemc.track.tailsystem.removeComponent(foundIn: entity!)
			node.geometry?.firstMaterial?.multiply.contents = NSColor.black
			node.geometry?.firstMaterial?.diffuse.contentsTransform.m22 = 1
			node.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = -0.99
		}
	}
}

