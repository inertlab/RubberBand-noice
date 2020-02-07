//
//  GameSwitch.swift
//  RubberBand
//
//  Created by Fernando on 7/9/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit




enum GameState {
	case drumsPlaying
	case songSelection
	case gamePaused
	case optionMenu
	case songoptions
	case statsdisplay
}

protocol GameSwitchable: AnyObject {
	var gamestate: GameState {get set}
	func updatestate (gamestate: GameState)
	func checkinput (_ input: Button)
}

extension GameSwitchable {
	func updatestate(gamestate: GameState)  {
		self.gamestate = gamestate
	}
}

/// Controls the game state and what controllers / buttons are active during current state
class SwitchBoard: GameSwitchable {
	/// the current state of the game - is it paused, is it playing, etc
	var gamestate = GameState.songSelection

	func checkinput (_ input: Button) {
		switch self.gamestate {
		case .gamePaused:
			gameispaused(input)
		case .statsdisplay:
			stagemc.loadstage()
		default:
			break;
		}
	}
}

private extension SwitchBoard {
	
	func gameispaused(_ input: Button){
		switch input {
		case .green:
			OggNo.sharedInstance.resumePlay()
			self.gamestate = .drumsPlaying
		default:
			break;
		}
	}
	
	func rotatecamera () {
		let cam = menuScene.rootNode.childNode(withName: "menucam", recursively: true)
		cam?.addChildNode(lastnode)
		lastnode.position.x = -1.6
		lastnode.position.y	= 0
		lastnode.position.z = -4
		cam?.runAction(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 0.5))
	}
}

let switchboard = SwitchBoard()

