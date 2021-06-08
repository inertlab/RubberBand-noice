//
//  MenuStates.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameKit

class MenuStates: GKState {
	let menu: SongMenu
	
	init(menu: SongMenu) {
		self.menu = menu
	}
}
