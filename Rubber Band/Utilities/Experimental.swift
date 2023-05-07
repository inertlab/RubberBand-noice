//
//  Experimental.swift
//  noice
//
//  Created by fernando on 5/14/23.
//  Copyright © 2023 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit



/// Meant to store graphic styles. not really used except for screen size
///
/// delete or improve?
enum NCStyle {
	static let frame = CGSize(width: 640, height: 400)
	static func label(size: CGFloat) -> SKLabelNode {
		let node = SKLabelNode()
		node.fontSize = size
		
		return SKLabelNode()
	}
	static func basic() -> SKLabelNode {
		let node = SKLabelNode()
		node.fontName = "Hobo Std Medium"
		node.fontSize = 47
		return node
	}
}

/// NOT USED - Delete?
class Scorelabel {

	let scene 		= SKScene(size: NCStyle.frame)
	let score 		= SKLabelNode()
	let congrats 	= SKLabelNode()
	let message  	= SKLabelNode()
	let streak 	 	= SKLabelNode()
	
	init() {
		self.scene.addChild(score)
		self.scene.addChild(congrats)
		self.scene.addChild(message)
		self.scene.addChild(streak)
	}
}
