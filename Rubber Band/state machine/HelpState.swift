//
//  HelpState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit
import SwiftRPC


class HelpState: GKState {
	
	let help = Help()
	static var previous:GKState? = MenuState()
	
	var rp = RichPresence()
	
	override func didEnter(from previousState: GKState?) {
		HelpState.previous = previousState
		switch previousState {
		case is RelatedState, is HistoryState, is AddedState:
			help.showhelp(state: .history)
		case is DetailState:
			help.showhelp(state: .details)
		default:
			help.showhelp(state: .select)
		}
		
		if DiscordRP.rpc != nil {
			rp.details = "A little lost,"
			rp.state = "checking out the manual"
			DiscordRP.rpc?.setPresence(rp)
		}
	}
	
	override func willExit(to nextState: GKState) {
//		this can potentially crash on quit. not a big deal
		help.hidehelp()
	}
}
