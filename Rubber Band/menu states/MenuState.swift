//
//  MenuState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameKit

class MenuState: GKState {
	
	override func didEnter(from previousState: GKState?) {
		ListState.screen = .menu
		smanager.selected.state = .selected
		rowcall.state = .menu
		UpNext.shared.show()
	}
}
