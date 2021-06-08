//
//  HelpState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit

class HelpState: GKState {
	
	let help = Help()
	static var previous:GKState? = MenuState()
	
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
	}
	
	override func willExit(to nextState: GKState) {
		help.hidehelp()
	}
}
