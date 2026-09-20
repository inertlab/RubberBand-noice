//
//  ScoreState.swift
//  noice
//
//  Created by Fernando on 6/12/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Cocoa
import GameplayKit
import SwiftRPC

let rpassets = [Instrument: [Difficulty: [String]]]()

class RPAssets {
	
}

class PlayState: GKState {
	// this shouldn't be here, this gets complicated if i want instrument specific images
	var rp = RichPresence()
	
	var images = ["play-1", "play-2"]
	
	override func didEnter(from previousState: GKState?) {
		stagemc.tc.show = false
		if previousState is RewindState {
			Jukebox.shared.resumePlay()
			
			if DiscordRP.rpc != nil {
				print(rp.timestamps.start!)
				rp.timestamps.start = Date()
				rp.timestamps.end = Date() + Jukebox.shared.timeremaining()
				DiscordRP.rpc?.setPresence(rp)
			}
			return
		}
		print("entered")
		Jukebox.shared.stop()
		stagemc.loadsong()
		
		if DiscordRP.rpc != nil {
			let song = smanager.selected.song
			rp.details = song.artist ?? "no artist?"
			rp.state = song.title ?? "unititled"
			rp.timestamps.start = Date()
			rp.timestamps.end = Date() + song.length
			rp.assets.largeImage = images.randomElement()
			rp.assets.largeText = "\(User.current.instrument.name()) on \(User.current.diff.text()) - charted by: \(song.charter ?? "unkown")"
			DiscordRP.rpc?.setPresence(rp)
		}
		if previousState is ScoreState {
			stagemc.tc.show = true
		}
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		switch stateClass {
		case is PausedState.Type, is ScoreState.Type:
			return true
		default:
			return false
		}
	}
}
