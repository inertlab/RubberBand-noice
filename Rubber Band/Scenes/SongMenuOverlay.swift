//
//  SongMenuOverlay.swift
//  RubberBand
//
//  Created by Fernando on 6/13/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit

final class SongMenuOverlay {
	static let shared = SongMenuOverlay()
	let scn 	= SKScene(fileNamed: "titleDisplay")
	let title	:SKLabelNode
	let details	:SKNode
	private init() {
		self.title 		= scn?.childNode(withName: "name") as! SKLabelNode
		self.details 	= (scn?.childNode(withName: "details"))!
	}
}



