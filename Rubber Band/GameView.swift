//
//  GameView.swift
//  Rubber Band
//
//  Created by Fernando on 2/8/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SceneKit
import MIKMIDI
import SpriteKit
import AVFoundation




var beat: TimeInterval = 0


var playa = URL(string: "")
//var midiplayer = AVMIDIPlayer()

var totaltime = 0.0
var asphalt = hwy.base.childNode(withName: "asphalt", recursively: false)

class GameView: SCNView {

	
	
	override func keyDown (with event: NSEvent) {
		
		if event.modifierFlags.rawValue == 1048840 {
			switchboard.checkkey(keymodified: event.keyCode)
		}else{
			switchboard.checkkey(keypad: event.keyCode)
		}
	}
	
	override func viewDidHide() {
		
	}
}

//let format = DateComponentsFormatter()
var format:DateComponentsFormatter{
	let form = DateComponentsFormatter()
	form.allowedUnits = [.minute, .second]
//	form.includesTimeRemainingPhrase = true
//	form.unitsStyle = .short
	return form
}

extension GameViewController: SCNSceneRendererDelegate {
	
	
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		
		if switchboard.gamestate == .drumsPlaying {
			
			let songtime	= OggNo.sharedInstance.players[playa!]?.currentTime
			let midiframe 	= CGFloat(songtime!)
			let beatframe 	= midiframe * pace.fps
			
			hwy.pista.position.z = beatframe
			
			trackdeadnotes(time: beatframe)
			starpower.trackpower(time: beatframe)
			// asphat animation
			asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m42 = midiframe * pace.asphalt
			if time >= beat {
//				let timers = Int(totaltime - songtime!)
				
				scorekeeper.time.text = format.string(from: totaltime - songtime!)
				/// empty action to keep game from pausing
//				hwy.pista.runAction(emptyaction)
				beat = time + TimeInterval(1)
			}
		}
    }
}

///empty action to keep gameview from pausing
let emptyaction = SCNAction.customAction(duration: 60, action: { (node, loc) in })


func trackdeadnotes (time: CGFloat) {
	var count = 0
	for gem in hwy.gems.childNodes {
		count += 1
		if gem.isHidden {
			continue
		}
		if gem.position.z < time - 10 {
			gem.removeFromParentNode()
			continue
		}
		if gem.categoryBitMask == GemBit.dead {
			continue
		}
		if gem.position.z < time - pace.hitwindow   {
			gem.categoryBitMask = GemBit.dead
//			gem.geometry?.firstMaterial?.selfIllumination.contents = NSColor.black
			scorekeeper.scoreMiss()
//			coun-t += 1
			continue
		}
		if count > 24 {
			break
		}
	}
	
}



