//
//  RandomPlay().swift
//  noice
//
//  Created by fernando on 4/10/23.
//  Copyright © 2023 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit



/// Displays the next random pic
///
/// does not manage or select songs. See SongManager for that
class RandomPlay {
	
	var randoml:SKLabelNode {
		return ScoreBoard.scene?.childNode(withName: "nextup/random") as! SKLabelNode
	}
	var artistl:SKLabelNode {
		return ScoreBoard.scene?.childNode(withName: "nextup/artist") as! SKLabelNode
	}
	
	func update() {
		randoml.text = smanager.nextrandom.song.artist! + " - " + smanager.nextrandom.song.title!
		artistl.text = smanager.nextbyArtist.song.artist! + " - " + smanager.nextbyArtist.song.title!
	}
}
