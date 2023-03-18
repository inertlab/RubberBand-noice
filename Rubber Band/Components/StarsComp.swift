//
//  StarsComp.swift
//  noice
//
//  Created by fernando on 1/23/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit

class StarsComp: GKComponent {
	let node = menuScene.rootNode.childNode(withName: "details", recursively: false)!

	override func didAddToEntity() {
		let song = self.entity?.component(ofType: SongComp.self)
			song?.cover.addChildNode(self.node)
	}
}
