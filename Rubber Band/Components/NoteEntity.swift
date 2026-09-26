//
//  String Components.swift
//  RubberBand
//
//  Created by Fernando on 7/5/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit


typealias Chord = Set<Button>
//typealias ChordSet = Set<Button>

enum Status: Int {
	case live, skip, remove
}

/// Note entity can contain a NoteComp which contains a 'chord' used for both strings and drums
/// drums uses just the first note of the chord
class NoteEntity: GKEntity {
//	var status = Status.live
	override init() {
		super.init()
		self.addComponent(NoteComp())
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class NoteComp: GKComponent {
	var status = Status.live
	var chord = Chord()
	var node = SCNNode()
}
