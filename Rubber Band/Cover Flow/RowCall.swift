//
//  RowCall.swift
//  RubberBand
//
//  Created by Fernando Zamora on 2/9/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import Foundation
import SceneKit


/// controls the position of CoverArt, doe not control the individual column animations
///
/// pos in the x direction is always a negative number
/// column.posx is always positive
class RowCall {
	/// The state of CoverFlow - position
	enum CFState {
		case off, menu, detail
		func z () -> CGFloat {
			switch self {
			case .off:
				return -1
			case .detail:
				return -1.25
			default:
				return 0
			}
		}
	}
	
	let node 	= menuScene.rootNode.childNode(withName: "coverflow", recursively: true)!
	var state:CFState = .off {
		didSet {
			updatezposition()
		}
	}
	
	var posx:CGFloat = 0 {
		didSet {
			let offset:CGFloat = posx - oldValue
			switch offset {
			case 0:
				updatezposition()
			case 9...:
				wraparoundright()
			case ...(-9):
				wraparoundleft()
			default:
				movetox()
				break
			}
		}
	}	
}

private extension RowCall {
	
	/// only triggers if pos z is the only change
	func updatezposition() {
		if node.position.z != state.z() {
			if state == .detail {
				movetox(0.5)
			} else {
				movetox(0.4)
			}
		}
	}
	
	func wraparoundleft() {
		//needs to travel to the end (move left)
		// first go off scren to the rigt
		node.runAction(
		SCNAction.move(to: SCNVector3(x: 5 , y: 0, z: state.z()), duration: 0.15)
		) {
			// then move everything all the way to the left to slide in gracefully
			self.node.position.x = -CGFloat(smanager.colsystem.components.count + 1)
			self.movetox(0.15)
		}
	}
	
	func wraparoundright() {
		// needs to travel to begining
		node.runAction(
		SCNAction.move(to:
			SCNVector3(x: -CGFloat(smanager.colsystem.components.count + 1) , y: 0, z: self.state.z()), duration: 0.10
			)
		){
			self.node.position.x = 5
			// covernode has to moved sideways so update index
			self.movetox(0.20)
		}
	}
	
	func movetox() {
		movetox(0.25)
	}
	
	func movetox (_ speed: TimeInterval) {
		node.runAction(
			SCNAction.move(to: SCNVector3(x: posx , y: 0, z: state.z()), duration: speed),
		forKey: "movetox")
	}
}

let rowcall = RowCall()
