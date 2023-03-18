//
//  RecordComp.swift
//  noice
//
//  Created by fernando on 1/23/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit

//MARK: - Record
class RecordComp: GKComponent {
	let node = menuScene.rootNode.childNode(withName: "record", recursively: false)!

	override func didAddToEntity() {
		reset()
		let song = self.entity?.component(ofType: SongComp.self)
		song?.cover.addChildNode(self.node)
		self.node.runAction(SCNAction.move(to: SCNVector3(0.53, 0, -0.01 ), duration: 0.5))
		self.node.runAction(SCNAction.rotateTo(x: 0, y: 0, z: -0.25, duration: 0.5))
	}
}

private extension RecordComp {
	func reset() {
		node.removeAllActions()
		node.position.x = 0
		node.rotation.z = 1
		node.rotation.w = 1.5
	}
}
