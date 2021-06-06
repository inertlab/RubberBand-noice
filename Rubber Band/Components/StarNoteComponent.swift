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
			chord.node.runAction(SCNAction.fadeIn(duration: 0.1))
			node.runAction(SCNAction.fadeOut(duration: 0.1))
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
	
	func setmaterial() {
		if let note = entity?.component(ofType: NoteComp.self) {
//			node = note.node.copy() as! SCNNode
			
			node 			= note.node.clone()
			node.geometry 	= note.node.geometry?.copy() as? SCNGeometry
			
			let c:Chord = [.blue_c, .green_c, .yellow_c]
			
			if c .contains(note.chord.first!) {
				node.geometry?.materials = [gems.m_cymbals_g]
			} else {
				node.geometry?.materials = [gems.m_white]
			}
			
			stagemc.track.hwy.notes.addChildNode(node)
			note.node.opacity = 0
		}
	}
}
