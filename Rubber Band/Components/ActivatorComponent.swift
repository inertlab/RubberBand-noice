//
//  DrumSPComponent.swift
//  RubberBand
//
//  Created by Fernando on 7/10/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit


protocol hidable: GKComponent {
	func hide(_ limit: CGFloat)
	func show(_ limit: CGFloat)
}

extension hidable {
	func hide(_ limit: CGFloat) {
		if let note = self.entity?.component(ofType: NoteComp.self) {
			if note.node.position.z < limit {
				return
			}
			if let starcomp = self.entity?.component(ofType: StarNoteComp.self) {
				starcomp.node.opacity = 0
			}
			note.status = .skip
			note.node.opacity = 0
		}
	}
	
	func show(_ limit: CGFloat) {
		if let note = self.entity?.component(ofType: NoteComp.self) {
			if note.node.position.z < limit {return}
			note.status = .live
			note.node.opacity = 1
			if let starcomp = self.entity?.component(ofType: StarNoteComp.self) {
				starcomp.node.opacity = 1
				note.node.opacity = 0
			}
		}
	}
}

class ActivatorComp: GKComponent, hidable {
	override func didAddToEntity() {
		hide(0)
	}
}

class HiddenComp: GKComponent, hidable {

}
