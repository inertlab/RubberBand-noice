//
//  Presentation.swift
//  RubberBand
//
//  Created by Fernando Zamora on 5/13/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit


/// loads the highway scene to play a song
func loadGamePlay(){
	Jukebox.shared.stop()
	
	Jukebox.shared.getsongfiles(folder: selectedSong.folder!)

	hwy.base.position.y = -10
	scorekeeper.resetscore()
	mainView.prepare(drumScene, shouldAbortBlock: {return true})
	
	let midiUrl = selectedSong.folder!.appendingPathComponent("notes.mid")
	MusicSheet.shared.setSeq(url: midiUrl, drumsExpert)
//	let fzmik = try! FZMIK(fileAt: midiUrl, convertMIDIChannelsToTracks: false)
	
	let timecop = TimeCode(seq: MusicSheet.shared.seq)
	let _ = MusicSheet.shared.averagetempo()
	let notecount = MusicSheet.shared.laytrack(tc: timecop)
	
	scorekeeper.starvalues = Starvalues(notecount: Double(notecount))
	let vocalist = Vocalist(track: MusicSheet.shared.getvocals(), tc: timecop)
	vocalist.updatecoach(coach: vocalcoach)
	
	mainView.present(drumScene, with: .crossFade(withDuration: 1), incomingPointOfView: nil) {

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ){
			hwy.base.runAction(crankup)
			Jukebox.shared.play()
			switchboard.updatestate(gamestate: .drumsPlaying)

			Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
				let timeup = Jukebox.shared.players[.guitar]!.duration - Jukebox.shared.players[.guitar]!.currentTime
	
				scorekeeper.time.text = format.string(from: timeup)
				if timeup < 1 {
					timer.invalidate()
					presentmenu()
				}
			}
		}
	}
	
	mainView.overlaySKScene = scoreDisplay
	scoreDisplay?.scaleMode = .aspectFit
}


func presentmenu() {
	switchboard.updatestate(gamestate: .songSelection)
	menuOverlay?.isPaused = false

		mainView.present(menuScene, with: .crossFade(withDuration: 1), incomingPointOfView: nil, completionHandler: nil)
		mainView.overlaySKScene = menuOverlay
		menuOverlay?.scaleMode = .aspectFit
		
		switchboard.unhidecovers()
}

func presentstats() {
	scorekeeper.updatestats(song: selectedSong)
	scorekeeper.displaystat()
	
	box.particleSystems?.first?.reset()
	
	for c in hwy.notes.childNodes{
		c.removeFromParentNode()
	}
	
	hwy.base.runAction(crankdown) {
		starpower.resetvars()

		menuOverlay?.scaleMode = .aspectFit
		
		Jukebox.shared.stop()
		
		for c in hwy.beatlines.childNodes{
			c.removeFromParentNode()
		}
	}
}

func presentmainmenu() {
	mainView.present(menuScene, with: .crossFade(withDuration: 2), incomingPointOfView: nil, completionHandler: nil)
	mainView.overlaySKScene = menuOverlay
	menuOverlay?.scaleMode = .aspectFit
}


let crankup 	= SCNAction.move(to: SCNVector3(0, 0, 0), duration: 0.75)
let crankdown 	= SCNAction.move(to: SCNVector3(0, -10, 0), duration: 0.75)

func startparticle () -> SCNNode{
	let box = SCNNode()
	drumScene.rootNode.addChildNode(box)
	box.name = "box"
	box.position.z = -22
	box.position.y = 2
	box.renderingOrder = -2
	box.addParticleSystem(spartiscle!)
	return box
}
