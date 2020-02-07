//
//  StageManager.swift
//  RubberBand
//
//  Created by Fernando on 6/13/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit


let stagemc = StageManager()

final class StageManager:NSObject,  SCNSceneRendererDelegate {
	
	let songmenu 	= SongMenu()
	var vocalcoach 	= Vocalcoach()
	
	enum Act {
		case guitar, drums, piano, songmenu, preshow
	}
	/// the scene that will be loaded upon exiting current scene
	var onstage:Act 				= .preshow
	var currentact:Performing
	var track:Track

	override init() {
		self.currentact = songmenu
		self.track 		= DrumStage()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func loadstage()  {
		
		if onstage == .preshow {
			onstage = .songmenu
			presentmenu()
			(currentact as! SongMenu).state = .options
			return
		}
		
		if onstage == .songmenu {
			// alwys check user instrument before loading gameplay
			switch User.current.instrument {
			case .drums, .prodrums:
				onstage 	= .drums
				currentact 	= DrumStage()
			case .keys:
				onstage 	= .piano
				currentact 	= GuitarStage()
			default:
				onstage 	= .guitar
				currentact 	= GuitarStage()
			}
			track 			= currentact as! Track
			mainView.delegate 	= self
//			print("this is happening")
			loadGamePlay()
		} else {
			onstage 			= .songmenu
			currentact 			= songmenu
			mainView.delegate 	= nil
			presentmenu()
		}
	}


	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if track.state == .playing {

			if let songtime = Jukebox.shared.players[.guitar]?.currentTime {
			
				/// songtime cast as CGFloat - not altered
				let cgsongtime 	= CGFloat(songtime)
				/// CGFloat representing seconds as distance on HWY
				let hwytime 	= cgsongtime * pace.fps
				
				vocalcoach.tracklyrics(songtime: songtime)
				
				track.tracker(cgsongtime, hwytime)
			} else {
				print(Error.Type.self)
			}
		}
	}
}

private extension StageManager {
	
	func presentmenu() {
		menuOverlay?.isPaused = false
		mainView.overlaySKScene = menuOverlay
		mainView.overlaySKScene?.alpha = 0
		mainView.overlaySKScene?.run(SKAction.fadeIn(withDuration: 1.5))
		mainView.present(currentact.scn, with: .crossFade(withDuration: 1.5), incomingPointOfView: nil) {
			scorekeeper.resetscore()
		}
	
		(currentact as! SongMenu).state = .details
	}
	
	/// resets track scenes to initial state
	func reset() {
		self.track.hwy.reset()
		// this stops the preview song from playing
		Jukebox.shared.stop()
		Jukebox.shared.getsongfiles(folder: smanager.selected.song.folder!)
	}
	
	func loadGamePlay(){
		reset()
		mainView.prepare(currentact.scn, shouldAbortBlock: {return true})
	
		let midiUrl = smanager.selected.song.folder!.appendingPathComponent("notes.mid")
		MusicSheet.shared.setSeq(url: midiUrl)
	
		let _ = MusicSheet.shared.averagetempo()
		
		let notecount = self.track.laytrack()
	
		scorekeeper.starvalues = Starvalues(notecount: Double(notecount))
		// initiate new vocal coach
		vocalcoach = Vocalcoach()
		let vocalist = Vocalist()
		vocalist.updatecoach(coach: vocalcoach)
		
		mainView.present(currentact.scn, with: .crossFade(withDuration: 1), incomingPointOfView: nil) {
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ){
				self.track.crankup()
				Jukebox.shared.play()

				Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
					let timeup = Jukebox.shared.players[.guitar]!.duration - Jukebox.shared.players[.guitar]!.currentTime
					
					scorekeeper.time.text = format.string(from: timeup)
					if timeup < 1 {
						timer.invalidate()
						self.track.showstats()
					}
				}
			}
		}
		
		mainView.overlaySKScene = scoreDisplay
		mainView.overlaySKScene?.run(SKAction.fadeIn(withDuration: 1))
		scoreDisplay?.scaleMode = .aspectFit
	}
}
