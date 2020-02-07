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
		let list = upnextgroup?.childNode(withName: "nextlist")
		for node in list!.children as! [SKLabelNode] {
//			node.preferredMaxLayoutWidth = 50
//			node.numberOfLines = 1
//			node.lineBreakMode = .byTruncatingMiddle
			listnodes.append(node)
		}
	}
	
	let upnextgroup = menuOverlay?.childNode(withName: "upnext")
	var listnodes 	= [SKLabelNode]()
	// this doesn't work because there might only be 1 song total
	// it also doesn't work because the middle song is to be discarded
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


