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
import CoreImage

fileprivate let context = CIContext()

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
		case .drumsPlaying:
			playdrums(input)
		case .songSelection:
			selectsong(input)
		case .gamePaused:
			gameispaused(input)
		case .optionMenu:
			selectoptions(input)
		case .songoptions:
			songoptions(input)
		case .statsdisplay:
			presentmenu()
		}
	}
	
	func unhidecovers () {
		gamestate = .songSelection
		labeldetails!.run(Actions.shared.fadeout)
		covernode.runAction(SCNAction.moveBy(x: 0, y: 0, z: 4, duration: 0.5))
		lastnode.runAction(SCNAction.moveBy(x: 0, y: 0, z: -4, duration: 0.5))
	}
}

private extension SwitchBoard {
	
	func selectsong(_ input: Button)  {
		if smanager.columns.count > 0 {
			switch input {
			case .minus:
				smanager.reflow(sortedBy: .artist)
			case .green, .start:
				hidecovers()
			case .red:
				// in future this should go back to main menu
				smanager.reflow(sortedBy: .tier)
			case .plus:
				displayoptions()
			case .select:
				smanager.reflow(sortedBy: .song)
			case .blue_c:
				trackDirection(d: .left)
			case .green_c:
				trackDirection(d: .right)
			case .blue:
				trackDirection(d: .down)
			case .yellow:
				trackDirection(d: .up)
			case .yellow_c:
				smanager.reflow(sortedBy: .stars)
			default:
				break;
			}
		} else {
			if input == .start {
				smanager.deleteCatalog()
				let sfinder = SongFinder()
				sfinder.catalogSongs()
				smanager.coverflow()
			}
		}
	}
	
	func selectoptions(_ input: Button)  {
		if smanager.columns.count > 0 {
			switch input {
			case .red:
				hideoptions()
			default:
				break;
			}
		}
	}
	
	func playdrums(_ note: Button) {
		switch note {
		case .red: // key: J
			snare.checkHit()
		case .yellow_c:
			yellowC.checkHit()
		case .blue_c:
			blueC.checkHit()
		case .green_c:
			if starpower.state == .ready {
				if !starpower.checkHit() {
					greenC.checkHit()
				}
				break
			}
			greenC.checkHit()
		case .yellow:
			yellowT.checkHit()
		case .blue:
			blueT.checkHit()
		case .green:
			greenT.checkHit()
		case .orange:
			kick.checkHit()
		case .start:
			presentstats()
		case .plus:
			Jukebox.shared.pauseSounds()
			self.gamestate = .gamePaused
		default:
			break;
		}
	}
	
	func gameispaused(_ input: Button){
		switch input {
		case .green:
			OggNo.sharedInstance.resumePlay()
			self.gamestate = .drumsPlaying
		default:
			break;
		}
	}
	

	func songoptions(_ input: Button)  {
		switch input {
		case .red: // red pad
			//rotate camera
			unhidecovers()
		case .green, .start: // green pad
			if selectedSong.tier?.drums != nil && selectedSong.tier?.drums != -1{
				loadGamePlay()
			}
		case .yellow_c:
			User.current.diff.next()
		default:
			break;
		}
	}
	
	func displayoptions () {
		gamestate = .optionMenu
		
		let optiondisplay = SKScene(fileNamed: "optionmenu.sks")
		let bg 			= optiondisplay?.childNode(withName: "bg") as! SKSpriteNode
		let snap 		= mainView.snapshot()
		let snapdata 	= snap.tiffRepresentation
		let ciimage 	= CIImage(data: snapdata!)
		let filt 		= CIFilter(name: "CIGaussianBlur", parameters: [  "inputImage": ciimage!, "inputRadius" : 10])
	
		var image 	= filt?.outputImage!
		let filt2 	= CIFilter(name: "CICMYKHalftone", parameters: ["inputImage" : image!, "inputWidth": 16, "inputSharpness": 1])
		image 		= filt2?.outputImage!
		let final 	= context.createCGImage(image!, from: ciimage!.extent)
		bg.texture 	= SKTexture(cgImage: final!)

		mainView.overlaySKScene 	= optiondisplay
		optiondisplay?.scaleMode 	= .fill
		//		cam?.camera?.vignettingIntensity 	= 0.75
		//		cam?.camera?.colorFringeIntensity 	= 2
		//		cam?.camera?.saturation 			= 0.25
	}
	
	func rotatecamera () {
		let cam = menuScene.rootNode.childNode(withName: "menucam", recursively: true)
		cam?.addChildNode(lastnode)
		lastnode.position.x = -1.6
		lastnode.position.y	= 0
		lastnode.position.z = -4
		cam?.runAction(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 0.5))
	}
	
	func hidecovers () {
		gamestate 			= .songoptions
		labelphrase.text 	= selectedSong.phrase
		labelcharter.text 	= selectedSong.charter
		labelyear.text 		= selectedSong.year.description
		labelalbum.text		= selectedSong.trackOf?.name
		labelgenre.text 	= selectedSong.genre
		
		labeldetails!.run(Actions.shared.fadein)
		covernode.runAction(SCNAction.moveBy(x: 0, y: 0, z: -4, duration: 1))
		lastnode.runAction(SCNAction.moveBy(x: 0, y: 0, z: 4, duration: 1))
	}

	func hideoptions () {
		gamestate 	= .songSelection
		let cam 	= menuScene.rootNode.childNode(withName: "menucam", recursively: true)

		mainView.overlaySKScene = menuOverlay
		cam?.camera?.vignettingIntensity 	= 0
		cam?.camera?.colorFringeIntensity 	= 0
		cam?.camera?.saturation 			= 1
	}
}

let switchboard = SwitchBoard()

