//
//  ColumnComp.swift
//  noice
//
//  Created by fernando on 1/23/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit


/// Column node entity belongs to
class ColumnComp: GKComponent {
	let posx	: CGFloat
	let node	: SCNNode
	var letter 	= SCNNode()
	var index 	= 0
	init(column: CGFloat, node: SCNNode){
		self.posx = column
		self.node = node
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func highlight() {
		letter.runAction(SCNAction.fadeIn(duration: 0.5), forKey: "letterfade")
		letter.position.z = 0.25
	}
	
	func unhilight() {
		node.position.z = 0
		letter.runAction(SCNAction.fadeOpacity(to: 0.15, duration: 0.35), forKey: "letterfade")
		letter.position.z = 0.01
	}
	
	func addletter(char: String) {
		if let textnode = albumscn.rootNode.childNode(withName: "colnum", recursively: false){
			letter = textnode.clone()
			letter.geometry = textnode.geometry?.copy() as! SCNText
			(letter.geometry as! SCNText).string = char
//			scenekit text has no justification. use this to center align text
			let center = (letter.geometry!.boundingBox.max.x - letter.geometry!.boundingBox.min.x) * 0.007
			letter.position.x = posx - center
			letter.position.y = -1.58
			letter.position.z = 0.01
			covernode.addChildNode(self.letter)
			unhilight()
		}
	}
}
