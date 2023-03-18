//
//  RewindState.swift
//  noice
//
//  Created by Fernando on 6/13/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit

class RewindState: GKState {
	let node 	= SCNNode()
	let sound 	= SCNAudioSource(named: "sounds/rewind_01.m4a")!

	
	override init() {
		sound.isPositional = false
		sound.volume = 1
		sound.load()
	}
	
	override func didEnter(from previousState: GKState?) {
		Jukebox.shared.rewind()
		stagemc.track.hwy.pista.runAction(SCNAction.move(to: SCNVector3(0, 0, CGFloat( Jukebox.shared.currenttime()! - 2) * pace.fps), duration: 1)) {
			stagemc.machine.enter(PlayState.self)
		}
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		switch stateClass {
		case is PlayState.Type, is DetailState.Type:
			return true
		default:
			return false
		}
	}
}
