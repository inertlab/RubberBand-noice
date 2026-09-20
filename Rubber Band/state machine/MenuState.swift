//
//  MenuState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameKit
import SwiftRPC

class MenuState: GKState {
	
	var rp = RichPresence()
	var imgs = ["splash-1", "splash-2", "splash-3" ,"splash-4" ,"splash-5"]
	
	override func didEnter(from previousState: GKState?) {
		ListState.screen = .menu
		smanager.selected.state = .selected
		rowcall.state = .menu
		UpNext.shared.show()
		
		if previousState is ListState {
			TextureMover.shared.updatechartericon(icon: smanager.selected.song.icon ?? "")
		}
		
		if DiscordRP.rpc != nil {
			rp.details = "Browsing Record Collection"
			rp.state = "\(smanager.songcount) songs, wow!"
			rp.assets.largeImage = "menu-\(smanager.sortkeypath.rawValue)"
			rp.assets.largeText = "sorted by \(smanager.sortkeypath.rawValue)"
			DiscordRP.rpc?.setPresence(rp)
		}
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		switch stateClass {
		case is PlayState.Type, is ScoreState.Type, is PausedState.Type, is RelatedState.Type:
			return false
		default:
			return true
		}
	}
}
