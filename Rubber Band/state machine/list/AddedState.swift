//
//  LhistoryState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameplayKit

class AddedState: ListState {
	override func didEnter(from previousState: GKState?) {

		if User.current.player.stats?.count == 0 { return }
		
		SongLister.shared.recentlyadded()
		showlist()
	}
	
	override func willExit(to nextState: GKState) {
		fadeout(nextState)
	}
}
