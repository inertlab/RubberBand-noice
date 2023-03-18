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
	
	let machine		:GKStateMachine
	
	var bg 			= true
	var sub 		: SCNView?
	let songmenu 	= SongMenu()
	var vocalcoach 	= Vocalcoach()
	let tc 			= TitleCredit()
	
	enum Mode {
		case choose, random
	}
	/// the instrument mode currently playing onstage
	enum Act {
		case guitar, drums, piano, songmenu, preshow
	}
	/// the scene that will be loaded upon exiting current scene
	var onstage		:Act = .preshow
	var currentact	:Performing
	var track		:Track
	
	override init() {
		self.currentact = songmenu
		self.track 		= DrumStage()
		machine		 	= GKStateMachine(states: [MenuState(),
												  HistoryState(),
												  RelatedState(),
												  AddedState(),
												  HelpState(),
												  DetailState(octo: songmenu.octopus),
												  PlayState(),
												  RewindState(),
												  ScoreState(),
												  PausedState(),
												 ])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func loadmenu() {
		currentact = songmenu
		presentmenu()
	}
	func loadstage() {
		
	}
	
	func loadsong()  {
		switch User.current.instrument {
		case .guitar, .bass:
			onstage 	= .guitar
			currentact 	= GuitarStage()
		case .keys:
			onstage 	= .piano
			currentact 	= GuitarStage()
		default:
			onstage 	= .drums
			currentact 	= DrumStage()
		}
		track = currentact as! Track
		mainView.delegate = self
		
		loadGamePlay()
	}

	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if machine.currentState is PlayState {
//		if track.state == .playing {
			if let songtime = Jukebox.shared.currenttime() {
				/// songtime cast as CGFloat - not altered
				let cgsongtime = CGFloat(songtime)
				/// CGFloat representing seconds as distance on HWY
				let hwytime = cgsongtime * pace.fps
				
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
		Jukebox.shared.stop()
		menuOverlay?.isPaused 			= false
		mainView.overlaySKScene		 	= menuOverlay
		mainView.overlaySKScene?.alpha 	= 0
		mainView.overlaySKScene?.run(SKAction.fadeIn(withDuration: 1.5))
		mainView.present(currentact.scn, with: .crossFade(withDuration: 1.5), incomingPointOfView: nil) {
		}
		mainView.autoenablesDefaultLighting = false
	}
	
	/// resets track scenes to initial state
	func reset() {
		self.track.hwy.reset()
		// this stops the preview song from playing
		// when playing oggs, stop removes the file from the player. do not use after getting song files
		Jukebox.shared.stop()
		Jukebox.shared.getsongfiles(folder: smanager.selected.song.folder!)
	}
	
	func loadGamePlay(){
		reset()
		
//		remove songs from shuffled
		smanager.removefromshuffle()
		
		track.scorekeeper.loadoldscore(smanager.selected.song)
		
		mainView.prepare(currentact.scn, shouldAbortBlock: {return true})
	
		let midiUrl = smanager.selected.song.folder!.appendingPathComponent("notes.mid")
		MusicSheet.shared.setSeq(url: midiUrl)
	
		let _ = MusicSheet.shared.averagetempo()
		
		self.track.laytrack()
		
		// initiate new vocal coach
		vocalcoach 		= Vocalcoach()
		let vocalist 	= Vocalist()
			vocalist.updatecoach(coach: vocalcoach)
		
		Anal.shared.event()

		if bg {
			if let octo = currentact.scn.rootNode.childNode(withName: "octo", recursively: false) {
				(octo as! SCNReferenceNode).load()
				mainView.autoenablesDefaultLighting = true
				track.backdrop.setnode(node: octo)
			}
		}

//		Jukebox.shared.stop()
		mainView.present(currentact.scn, with: .crossFade(withDuration: 1), incomingPointOfView: nil) {
			mainView.overlaySKScene?.removeAllActions()
			mainView.overlaySKScene = scoreDisplay
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ){
				if self.track.state != .playing { return }
				mainView.overlaySKScene?.run(SKAction.fadeIn(withDuration: 1))
				self.track.crankup()
				self.track.backdrop.state(.start)
				
				Jukebox.shared.play()
				
				if self.tc.show {
					self.tc.display(smanager.selected.song)
				}
				
				NotificationCenter.default.addObserver(forName: .player_playbackCompleted, object: nil, queue: OperationQueue.main) {
					(player) in
					print(player)

					NotificationCenter.default.removeObserver(self)
					return
				}
				Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
					if self.track.state != .playing {timer.invalidate()}
					let timeup = Jukebox.shared.timeremaining()
					
					self.track.scorekeeper.time.text = format.string(from: timeup)
					if timeup < 1 {
						timer.invalidate()
						print("song ended presenting stuff")
						self.machine.enter(ScoreState.self)
					}
				}
			}
		}
		scoreDisplay?.scaleMode = .aspectFit
	}
	
	/// creates subview and assigns currentact to it's scene
	/// this is unused
	func subview() {
		currentact.scn.background.contents = .none
		sub = SCNView(frame: mainView.visibleRect)
		sub?.autoresizingMask = [.height, .width]
		sub?.scene = self.currentact.scn
		sub?.backgroundColor = .clear
		mainView.addSubview(sub!)
		mainView.overlaySKScene?.run(SKAction.fadeOut(withDuration: 1))
		sub?.overlaySKScene = scoreDisplay
		sub?.overlaySKScene?.run(SKAction.fadeIn(withDuration: 1))
	}
}
