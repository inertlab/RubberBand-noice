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


fileprivate var beat: TimeInterval = 0

var totaltime 	= 0.0
var asphalt 	= hwy.base.childNode(withName: "asphalt", recursively: false)

let frustum = menuScene.rootNode.childNode(withName: "frustum", recursively: false)

class GameView: SCNView {

	override func keyDown (with event: NSEvent) {
		if let key = keycode[event.keyCode] {
			switchboard.checkinput(key)
		}
	}
}

//let format = DateComponentsFormatter()
var format:DateComponentsFormatter{
	let form = DateComponentsFormatter()
	form.allowedUnits = [.minute, .second]
	return form
}

extension GameViewController: SCNSceneRendererDelegate {
	
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		
		if switchboard.gamestate == .drumsPlaying {
			
			let songtime 	= Jukebox.shared.players[.guitar]?.currentTime
//			let songtime	= OggNo.sharedInstance.players[playa!]?.currentTime
			let midiframe 	= CGFloat(songtime!)
			let beatframe 	= midiframe * pace.fps
			
			hwy.pista.position.z = beatframe
			
			vocalcoach.tracklyrics(time: songtime!)
			trackdeadnotes(time: beatframe)
			starpower.trackpower(time: beatframe)
			// asphat animation
			asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m42 = midiframe * pace.asphalt
		}
    }
}

func trackdeadnotes (time: CGFloat) {
	var count = 0
	for gem in hwy.notes.childNodes {
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
		if gem.position.z < time - pace.hitwindow {
		
			gem.categoryBitMask = GemBit.dead
//			gem.geometry?.firstMaterial?.selfIllumination.contents = NSColor.black
			scorekeeper.scoreMiss()
			break
		}
		if count > 12 {
			break
		}
	}
}



