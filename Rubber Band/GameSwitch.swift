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
}

protocol GameSwitchable: AnyObject {
	var gamestate: GameState {get set}
	func updatestate (gamestate: GameState)
	func checkkey (keypad: UInt16)
	func checkkey (drumpad: UInt8)
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
	
	/// registers keypresses and pipes to the proper method depending on game state mode
	///
	/// - Parameter keypad: the pressed key on the kaypad
	func checkkey(keypad: UInt16) {
		switch self.gamestate {
		case .drumsPlaying:
			playdrums(keypad: keypad)
		case .songSelection:
			selectsong(keypad: keypad)
		case .gamePaused:
			gameispaused(keypad: keypad)
		case .optionMenu:
			selectoptions(keypad: keypad)
		case .songoptions:
			songoptions(keypad: keypad)
		}
	}
	
	func checkkey(keymodified: UInt16) {
		switch self.gamestate {
		case .drumsPlaying:
			break
		case .songSelection:
			selectsong(keymodified: keymodified)
		case .gamePaused:
			break
		case .optionMenu:
			break
		case .songoptions:
			break
		}
	}
	
	/// registers Drum Kit notes and pipes to the proper method depending on game state mode
	///
	/// - Parameter drumpad: the hit Drum on the Drumkit
	func checkkey(drumpad: UInt8) {
		switch self.gamestate {
		case .drumsPlaying:
			playdrums(drumpad: drumpad)
		case .songSelection:
			selectsong(drumpad: drumpad)
		case .gamePaused:
			print("nothing to do here")
		case .optionMenu:
			print("nothing to do here")
		case .songoptions:
			songoptions(keypad: 16)
		}
	}
	
	func unhidecovers () {
		gamestate = .songSelection
		covernode.runAction(SCNAction.moveBy(x: 0, y: 0, z: 4, duration: 0.5))
		lastnode.runAction(SCNAction.moveBy(x: 0, y: 0, z: -4, duration: 0.5))
//		lastnode.addChildNode(menutext.detailnode!)
//		menutext.detailnode?.runAction(SCNAction.moveBy(x: 0, y: 0, z: 2, duration: 0.5))
	}
}

private extension SwitchBoard {
	func selectsong(keypad: UInt16)  {
		if smanager.columns.count > 0 {
			switch keypad {
			
			case 0: // key: A
				smanager.reflow(category: "artist")
			case 2: // key: D
				//rotate camera
				hidecovers()
			case 3: // key: F
				//rotate camera
				unhidecovers()
			case 20: // key: 3
				scorekeeper.deleteallstats()
			case 24: // key: + -
				displayoptions()
			case 17: // key: T
				smanager.reflow(category: "title")
			case 51: // key: delete
				smanager.deleteCatalog()
			case 123: // key: left
				trackDirection(d: Direction.left)
			case 124: // key: right
				trackDirection(d: Direction.right)
			case 125: // key: down
				trackDirection(d: Direction.down)
			case 126: // key: up
				trackDirection(d: Direction.up)
			case 36: // key: return
				hidecovers()
//				if selectedSong.tier?.drums != nil && selectedSong.tier?.drums != -1{
//					loadGamePlay()
////					switchboard.updatestate(gamestate: .drumsPlaying)
//				}
			default:
				break;
			}
		} else {
			// key: c
			if keypad == 8 {
				smanager.deleteCatalog()
				let sfinder = SongFinder()
				sfinder.catalogSongs()
				smanager.coverflow()
			}
			
		}
	}
	
	func selectsong(keymodified: UInt16)  {
		if smanager.columns.count > 0 {
			switch keymodified {
			case 44: // key: ?
				scorekeeper.printscores()
			default:
				break;
			}
		}
	}

	func selectsong(drumpad: UInt8)  {
		if smanager.columns.count > 0 {
			switch drumpad {
			case 36:
				smanager.reflow(category: "artist")
			case 49:
				smanager.reflow(category: "title")
			case 46:
				trackDirection(d: Direction.left)
			case 51:
				trackDirection(d: Direction.right)
			case 45:
				trackDirection(d: Direction.down)
			case 48:
				trackDirection(d: Direction.up)
			case 41:
				if selectedSong.tier?.drums != nil && selectedSong.tier?.drums != -1{
					loadGamePlay()
				}
			default:
				break;
			}
		}
	}

	func selectoptions(keypad: UInt16)  {
		if smanager.columns.count > 0 {
			switch keypad {
			case 24:
				hideoptions()
			default:
				break;
			}
		}
	}
	
	func playdrums(keypad: UInt16){
		switch keypad {
		case 24:
			OggNo.sharedInstance.pauseSounds()
			self.gamestate = .gamePaused
		case 38: // key: J
			snare.checkHit()
		case 40:
			yellowC.checkHit()
		case 37:
			blueC.checkHit()
		case 41:
			if starpower.state == .ready {
				if !starpower.checkHit() {
					greenC.checkHit()
				}
				break
			}
			greenC.checkHit()
		case 34:
			yellowT.checkHit()
		case 31:
			blueT.checkHit()
		case 35:
			greenT.checkHit()
		case 49: // key: SpaceBar
			kick.checkHit()
		case 36:
			presentmenu()
		default:
			break;
		}
	}
	
	func gameispaused(keypad: UInt16){
		switch keypad {
		case 24:
			OggNo.sharedInstance.resumePlay()
			self.gamestate = .drumsPlaying
		default:
			break;
		}
	}
	
	func playdrums(drumpad: UInt8){
		switch drumpad {
		case 36:
			kick.notify()
		case 38:
			snare.notify()
		case 46:
			yellowC.notify()
		case 41:
			greenT.notify()
		case 45:
			blueT.notify()
		case 48:
			yellowT.notify()
		case 49:
			if starpower.state == .ready {
				starpower.checkHit()
				break
			}
			greenC.notify()
		case 51:
			blueC.notify()
		default:
			break;
		}
	}
	
	func songoptions(keypad: UInt16)  {
			switch keypad {
			case 0: // key: A
				smanager.reflow(category: "artist")
			case 2: // key: D
				//rotate camera
				hidecovers()
			case 3: // key: F
				//rotate camera
				unhidecovers()
			case 20: // key: 3
				scorekeeper.deleteallstats()
			case 36: // key: return
				if selectedSong.tier?.drums != nil && selectedSong.tier?.drums != -1{
					loadGamePlay()
					//					switchboard.updatestate(gamestate: .drumsPlaying)
				}
			case 38: // key: J
				unhidecovers()
			default:
				break;
			}
	}
	
	func displayoptions () {
		let optiondisplay = SKScene(fileNamed: "optionmenu.sks")
		let cam = menuScene.rootNode.childNode(withName: "menucam", recursively: true)
		gamestate = .optionMenu
		
		mainView.overlaySKScene 	= optiondisplay
		optiondisplay?.scaleMode 	= .aspectFit
		cam?.camera?.vignettingIntensity 	= 0.75
		cam?.camera?.colorFringeIntensity 	= 2
		cam?.camera?.saturation 			= 0.25
	}
	
	func rotatecamera () {
//		let optiondisplay = SKScene(fileNamed: "optionmenu.sks")
		let cam = menuScene.rootNode.childNode(withName: "menucam", recursively: true)
		cam?.addChildNode(lastnode)
		lastnode.position.x = -1.6
		lastnode.position.y	= 0
		lastnode.position.z = -4
//		gamestate = .optionMenu
		cam?.runAction(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 0.5))
	}
	
	func hidecovers () {
		gamestate = .songoptions
		covernode.runAction(SCNAction.moveBy(x: 0, y: 0, z: -4, duration: 1))
		lastnode.runAction(SCNAction.moveBy(x: 0, y: 0, z: 4, duration: 1))
//		menutext.detailnode?.runAction(SCNAction.moveBy(x: 0, y: 0, z: -2, duration: 0.5))
	}

	func hideoptions () {
		gamestate = .songSelection
		let cam = menuScene.rootNode.childNode(withName: "menucam", recursively: true)

		mainView.overlaySKScene = menuOverlay
		cam?.camera?.vignettingIntensity 	= 0
		cam?.camera?.colorFringeIntensity 	= 0
		cam?.camera?.saturation 			= 1
	
	}
}


let switchboard = SwitchBoard()

