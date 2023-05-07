//
//  Stars.swift
//  noice
//
//  Created by fernando on 4/12/23.
//  Copyright © 2023 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit

/// displaces the Star coin in the scoreboard display
class Stars {
	/// the sprite representing the star
	private let node 	= ScoreBoard.scene?.childNode(withName: "stars") as! SKSpriteNode
	private let light 	= ScoreBoard.scene?.childNode(withName: "light")
	private	let images 	= SKTextureAtlas(named: "stars")
	private let normals = SKTextureAtlas(named: "starnormals")

	
	/// not currently used
	private var moveout:SKAction {
		let action = SKAction.moveTo(x: -360, duration: 3)
		action.timingMode = .easeIn
		return action
	}
	
	func update(_ stars: String) {
		ScoreBoard.scene?.isPaused = false
		
//		let string = stars.description
		
		node.texture = images.textureNamed("star-" + stars)
		node.normalTexture = normals.textureNamed("star-normal-" + stars)

		light?.position = .init(x: 100, y: 100)
//		starlight is defined in action.sks
		light?.run(SKAction(named: "starlight")!, withKey: "move")
	}
	
	func exit() {
		light?.run(moveout, withKey: "move")
	}
	
}
