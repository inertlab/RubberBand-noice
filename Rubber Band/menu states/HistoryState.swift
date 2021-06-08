//
//  LhistoryState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameplayKit

class HistoryState: ListState {
	override func didEnter(from previousState: GKState?) {
		
		// there is no history do nothing
		if User.current.player.stats?.count == 0 { return }
		SongLister.shared.songhistory()
		showlist()
	}
	
	override func willExit(to nextState: GKState) {
		fadeout(nextState)
	
	}
}
