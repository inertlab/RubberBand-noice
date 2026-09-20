//
//  PausedState.swift
//  noice
//
//  Created by Fernando on 6/12/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit
import SwiftRPC


class PausedState: GKState {
	
	var rp = RichPresence()
	
	override func didEnter(from previousState: GKState?) {
		Jukebox.shared.pauseMusic()
		
		if DiscordRP.rpc != nil {
			rp.details = "Taking A Break"
			rp.state = "will be right back…"
			DiscordRP.rpc?.setPresence(rp)
		}
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		switch stateClass {
		case is RewindState.Type, is DetailState.Type:
			return true
		default:
			return false
		}
	}
}
