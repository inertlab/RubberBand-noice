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


class ActivatorComp: GKComponent {
	
	var on 	= false {
		didSet {
			if on {
				updatestatus(.live)
				changeopacity(1)
			} else {
				updatestatus(.skip)
				changeopacity(0)
			}
		}
	}

	override func didAddToEntity() {
		changeopacity(0)
		updatestatus(.skip)
	}
}

private extension ActivatorComp {
	func updatestatus(_ status: Status) {
		if let note = self.entity?.component(ofType: NoteComp.self) {
			note.status = status
		}
	}
	
	func changeopacity(_ opacity: CGFloat) {
		if let notecomp = entity?.component(ofType: NoteComp.self) {
			notecomp.node.opacity = opacity
		}
	}
}


class HiddenComp: GKComponent {
	func hide() {
		if let note = self.entity?.component(ofType: NoteComp.self) {
			note.status = .skip
			note.node.opacity = 0
		}
	}
	
	func show() {
		if let note = self.entity?.component(ofType: NoteComp.self) {
			note.status = .live
			note.node.opacity = 1
		}
	}
}
