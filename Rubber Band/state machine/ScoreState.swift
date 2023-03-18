//
//  ScoreState.swift
//  noice
//
//  Created by Fernando on 6/12/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit
import SwordRPC

// this state does not contain a discord event because it requires too much info from ScoreBoard, so it's there instead.


class ScoreState: GKState {
	
	var rp = RichPresence()
	
	override func didEnter(from previousState: GKState?) {
		(stagemc.currentact as! Track).showstats()
		
		if DiscordRP.rpc != nil {
			rp.details = smanager.selected.song.artist
			rp.state = smanager.selected.song.title
			rp.assets.largeImage = "stars-\(stagemc.track.scorekeeper.starvalues?.stars ?? 0)-1"
			rp.assets.largeText = "scored \(stagemc.track.scorekeeper.total.dec) on \(User.current.diff.text())"
			DiscordRP.rpc?.setPresence(rp)
		}
	}
}
