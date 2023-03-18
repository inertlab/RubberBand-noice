//
//  titlecredit.swift
//  noice
//
//  Created by fernando on 1/17/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit

/// displays song title at the start of gameplay
/// only called when playing random song
class TitleCredit {
	var show = false
	let songnode = scoreDisplay?.childNode(withName: "song")
	let artist = scoreDisplay?.childNode(withName: "song/artist") as! SKLabelNode
	let title = scoreDisplay?.childNode(withName: "song/title") as! SKLabelNode
	
	private func updatesong (_ song: Song) {
		artist.text = song.artist
		title.text = song.title
	}
	
	func display(_ song: Song) {
		songnode?.removeAllActions()
		updatesong(song)
		songnode?.alpha = 1
		songnode?.run(SKAction.wait(forDuration: 2.5))  {
			self.songnode?.run(SKAction.fadeOut(withDuration: 1.5))
		}
	}
}
