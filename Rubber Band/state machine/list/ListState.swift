//
//  ListState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameKit
import SwiftRPC

class ListState: GKState {
	enum Screen {
		case menu, detail
	}
	
	static var screen = Screen.menu
	
	var rp = RichPresence()
	
	func showlist() {
		showlist(details: "Browsing:", state: "resently added songs")
	}
	
	func showlist(details: String, state: String) {
		UpNext.shared.hide()
		Jukebox.shared.stop()
		smanager.selected.state = .othersongs
		rowcall.state = .off
		
		let fadein = SKAction.fadeAlpha(to: 1, duration: 1)
		fadein.timingMode = .easeIn
		
		SongLister.shared.node?.run(fadein, withKey: "listfade")
		
		if DiscordRP.rpc != nil {
			rp.details = details
			rp.state = state
			DiscordRP.rpc?.setPresence(rp)
		}
	}
	
	func fadeout(_ state: GKState?) {
		if state is HelpState {
			return
		}
		let fadeout = SKAction.fadeAlpha(to: 0, duration: 0.75)
		fadeout.timingMode = .easeOut
		SongLister.shared.node?.run(fadeout, withKey: "listfade")
		smanager.selected.cover.runAction(SCNAction.fadeOpacity(to: 1, duration: 0.25), forKey: "coveropacity")
	}
}
