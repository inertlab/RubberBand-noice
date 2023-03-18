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
		letter.position.z = 0.5
	}
	
	func unhilight() {
		node.position.z = 0
		letter.runAction(SCNAction.fadeOpacity(to: 0.15, duration: 0.35), forKey: "letterfade")
		letter.position.z = 0.25
	}
	
	func addletter(char: String) {
		if let textnode = albumscn.rootNode.childNode(withName: "colnum", recursively: false){
			letter = textnode.clone()
			letter.geometry = textnode.geometry?.copy() as! SCNText
			(letter.geometry as! SCNText).string = char
			letter.position.x = posx
			covernode.addChildNode(self.letter)
			unhilight()
		}
	}
}
