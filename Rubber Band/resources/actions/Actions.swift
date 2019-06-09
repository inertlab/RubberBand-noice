//
//  Actions.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/2/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import SpriteKit

class Actions {
	static let shared = Actions()
//	let fadeout = SKAction.fadeAlpha(to: 0, duration: 1)
	var fadeout:SKAction{
		let act = SKAction.fadeAlpha(to: 0, duration: 1)
		act.timingMode = .easeOut
		return act
	}
	var fadein:SKAction{
		let act = SKAction.fadeAlpha(to: 1, duration: 2)
		act.timingMode = .easeIn
		return act
	}
}
