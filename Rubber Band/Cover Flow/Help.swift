//
//  Help.swift
//  noice
//
//  Created by Fernando Zamora on 5/27/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit


class Help {
	var state: SongMenu.State = .help
	let helpm = menuOverlay!.childNode(withName: "help")!
	let detail: SKNode
	let select: SKNode
	let list: SKNode
	
	init() {
		self.detail = helpm.childNode(withName: "detail")!
		self.select = helpm.childNode(withName: "select")!
		self.list = helpm.childNode(withName: "list")!
	}
	
	func showhelp(state: SongMenu.State) {
		showhelp(state: state, act: .songmenu)
	}
	
	func showhelp(state: SongMenu.State, act: StageManager.Act) {
		switch act {
		case .songmenu:
			self.state = state
			hideall()
			switch state {
			case .details:
				detail.alpha = 1
			case .start, .options, .help:
				return
			case .select:
				select.alpha = 1
			case .relatedsongs, .history:
				list.alpha = 1
			}
			self.helpm.run(SKAction.fadeIn(withDuration: 0.5))
		default:
			return
		}
	}
	
	func hidehelp() {
		helpm.removeAllActions()
		helpm.run(SKAction.fadeOut(withDuration: 0.2))
	}
}

private extension Help {
	func hideall() {
		helpm.removeAllActions()
		detail.alpha = 0
		select.alpha = 0
		list.alpha = 0
		helpm.alpha = 0
	}
}
