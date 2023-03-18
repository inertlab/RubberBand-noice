//
//  DetailState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameplayKit
import SwordRPC


class DetailState: GKState {
	
	let octo: Octopus
	let details = SongDetails()
	
	var rp = RichPresence()
	var imgs = ["splash-1", "splash-2", "splash-3" ,"splash-4" ,"splash-5"]
	
	init(octo: Octopus) {
		self.octo = octo
	}

	override func didEnter(from previousState: GKState?) {
		switch previousState {
		case is HelpState:
			return
		case is ScoreState:
//			if this stays in string menu, it gets forced cast to keyup and crashes
			stagemc.onstage = .songmenu
			details.update(smanager.selected)
		case is ListState:
				TextureMover.shared.updatechartericon(icon: smanager.selected.song.icon ?? "")
			fallthrough
		default:
			if DiscordRP.rpc != nil {
				let song = smanager.selected.song
				if let album = song.trackOf {
					rp.details = "Pick'd up '\(album.name!)'"
				} else {
					rp.details = "uknown album"
				}
				rp.assets.largeImage = imgs.randomElement()
				rp.state = "by: \(song.artist!)"
				rp.assets.largeText = song.phrase ?? "\(song.title ?? "unknown") charted by: \(song.charter ?? "unkown")"
				DiscordRP.rpc?.setPresence(rp)
			}
			
			ListState.screen = .detail
			octo.comein()
			details.update(smanager.selected)
			details.show()
			UpNext.shared.hide()
			rowcall.state = .detail
		}
	}
	
	override func willExit(to nextState: GKState) {
		switch nextState {
		case is HelpState, is PlayState:
			return
		default:
			octo.leave()
			details.hide()
			rowcall.state = .off
		}
	}
}
