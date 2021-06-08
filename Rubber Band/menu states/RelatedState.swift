//
//  LhistoryState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameplayKit

class RelatedState: ListState {
	override func didEnter(from previousState: GKState?) {
		SongLister.shared.relatedsongs(smanager.selected.song.artist!)
		showlist()
	}
	
	override func willExit(to nextState: GKState) {
		fadeout(nextState)
	}
}
