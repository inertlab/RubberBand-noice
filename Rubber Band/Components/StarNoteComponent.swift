//
//  StarNoteComponent.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/7/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit
import SceneKit

/// duplicates notecomponent nodes, changes them to white and hides the original
final class StarNoteComp: GKComponent {
	var set:Int
	var meta = false

	var node = SCNNode()
	init(_ set: Int) {
		self.set = set
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func didAddToEntity() {
		setTailColor()
		setmaterial()
	}
	
	override func willRemoveFromEntity() {
		stagemc.track.starsystem.removeComponent(self)
	}
	
	func starmissed () {
		if let chord = entity?.component(ofType: NoteComp.self) {
			node.runAction(SCNAction.fadeOut(duration: 0.1))
//			if chord.chord == [.green, .green_c] { return }
			chord.node.runAction(SCNAction.fadeIn(duration: 0.1))
			resettailcolor()
		}
	}
}


private extension StarNoteComp {
	func setTailColor() {
		if let tails = self.entity?.component(ofType: TailComp.self) {
			for tail in tails.node.childNodes{
			
				tail.geometry?.firstMaterial?.multiply.contents = NSColor.white
			}
		}
	}
	
	func resettailcolor() {
		if let tails = self.entity?.component(ofType: TailComp.self) {
			for tail in tails.node.childNodes{
				tail.geometry?.firstMaterial?.multiply.contents = uinttocolor(str: tail.name!)
			}
		}
	}
	
	func setmaterial() {
		if let chord = entity?.component(ofType: NoteComp.self) {
//			let n = SCNNode()
//			make new nodes for the chord
			for note in chord.chord {
				let notenode = gemmaker.makegem(button: note)
				notenode.geometry?.materials = [gemmaker.addglow(btn: note)]
				node.addChildNode(notenode)
			}
			
//			set the position of the starnotes to the original chord
			node.position.z = chord.node.position.z
			stagemc.track.hwy.notes.addChildNode(node)
//			hide the original nodes
			chord.node.opacity = 0
		}
	}
}


private func uinttocolor(str: String) -> NSColor {
	switch str {
	case "0":
		return NSColor.rbGreen
	case "1":
		return NSColor.rbRed
	case "2":
		return NSColor.rbYellow
	case "3":
		return NSColor.rbBlue
	default:
		return NSColor.rbRed
	}
}
