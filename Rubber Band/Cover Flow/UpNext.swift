//
//  UpNext.swift
//  RubberBand
//
//  Created by Fernando Zamora on 1/23/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit



/// controls the list of songs in the main menu. currently crashes if there is less that 7 songs
final class UpNext {
	
	static let shared = UpNext()
	
	private init() {
		self.moreup 	= upnextgroup?.childNode(withName: "moreup") 	as! SKLabelNode
		self.moredown 	= upnextgroup?.childNode(withName: "moredown") 	as! SKLabelNode
		let list 		= upnextgroup?.childNode(withName: "nextlist")
		for node in list!.children as! [SKLabelNode] {
			listnodes.append(node)
		}
	}
	let moreup		:SKLabelNode
	let moredown	:SKLabelNode
	let upnextgroup = menuOverlay?.childNode(withName: "upnext")
	var listnodes 	= [SKLabelNode]()
	
	var list 		= ["","","","","","",""]
	
	func scrollup (title: String) {
		list.removeLast()
		list.insert(title, at: 0)
		updatenodes()
	}
	
	func scrolldown (title: String) {
		list.removeFirst()
		list.append(title)
		updatenodes()
	}
	
	func refreshlist (nexttitles: [String]) {
		list = nexttitles
		updatenodes()
	}
	
	func rowcount(count:Int, row:Int) {
		let above = row - 2
		if above > 0 {
			moreup.text = "…\(above)+"
		} else {
			moreup.text = ""
		}
		let below = count - 3 - row
		if below > 0 {
			moredown.text = "…\(below)+"
		} else {
			moredown.text = ""
		}
	}
	
	func show() {
		upnextgroup?.run(SKAction.fadeIn(withDuration: 0.25))
	}

	func hide() {
		upnextgroup?.run(SKAction.fadeOut(withDuration: 0.25))
	}

	private func updatenodes() {
		for i in 0...6 {
			if i == 3 {
				continue
			}
			listnodes[i].text = list[i]
		}
	}

}


