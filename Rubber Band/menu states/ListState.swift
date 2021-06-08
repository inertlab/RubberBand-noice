//
//  ListState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameKit

class ListState: GKState {
	enum Screen {
		case menu, detail
	}
	static var screen = Screen.menu
	
	func showlist () {
		UpNext.shared.hide()
		Jukebox.shared.stop()
		smanager.selected.state = .othersongs
		rowcall.state = .off
		
		othersongsg?.run(Actions.shared.fadein, withKey: "listfade")
	}
	
	func fadeout(_ state: GKState?) {
		if state is HelpState {
			return
		}
		othersongsg?.run(Actions.shared.fadeout, withKey: "listfade")
		smanager.selected.cover.runAction(SCNAction.fadeOpacity(to: 1, duration: 0.25), forKey: "coveropacity")
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		switch stateClass {
		case is MenuState.Type, is DetailState.Type:
			return true
		default:
			return false
		}
	}
}
