//
//  File.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/22/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

struct Starvalues {
	let label = scoreDisplay?.childNode(withName: "stars") as! SKLabelNode
	var gold:Double
	var stars:Int16 	= 0
	var goal:Int32 		= 0
	init (notecount: Double ) {
		self.gold = (notecount - 30) * 140
		self.goal = Int32(self.gold * 0.055)
		self.label.text = "0*"
	}
	
	mutating func updatestars (score: Int32) {
		if score >= goal {
			stars += 1
			switch stars {
			case 1:
				goal = Int32(gold * 0.11)
				label.text = "1*"
			case 2:
				goal = Int32(gold * 0.185)
				label.text = "2*"
			case 3:
				goal = Int32(gold * 0.41)
				label.text = "3*"
			case 4:
				goal = Int32(gold * 0.68)
				label.text = "4*"
			case 5:
				goal = Int32(gold * 0.185)
				label.text = "5*"
			case 6:
				goal = Int32(gold)
				label.text = "5 gold *"
			default:
				goal = 100000000
			}
		}
	}
}

/// Keeps track of StarPower notes and streaks
class StarPower {
	
	enum State {
		case activated
		case low
		case ready
	}
	
	let hwy: HWY
	/// gems that activate star power - Crash Cymbals
	let activators: SCNNode
//	let powerx: Int
	
	init(_ hwy: HWY) {
		self.hwy = hwy
		self.activators	= hwy.pista.childNode(withName: "starpower", recursively: false)!
//		if bass { self.powerx = 3 } else {self.powerx = 2}
	}
	
	var state 		= State.low
	/// an list of gems to hide when star power is active so they aren't double hit
//	var tohide 		= [SCNNode]()

	var starnotes 	= MusicSheet.ChordList()

	/// time frame for the segments of starpower notes
	var timelist 	= [(CGFloat,CGFloat)]()
	/// all the nodes with star power
	var powergems 	= [[SCNNode]]()
	/// the sp segement
	var index 		= 0
	/// is player in starpower segment?
	var segment 	= false
	/// did player miss notes while in starpower segement
	var miss		= false
	/// note value is multiplied by this. when starpower is activated this value = 2
	var power		= 1
	/// start power acquired max value is 4. player needs at least 2 to activate sp
	var meter:CGFloat 		= 0
	var activetime:CGFloat 	= 0
	private var activated 	= false
	
	/// Keeps track of streak during SP segment used in timefunction
	///
	/// - Parameter time: current play time from the midi file
	func trackpower (time: CGFloat){
		
		if state == .activated {
			if meter == 0 {
				self.state 		= .low
				self.power 		= 1
				hwy.starpower 	= false
				return
			}
			
			for beat in hwy.beatlines.childNodes {
				if beat.position.z < time {
					print(meter)
					meter -= 1
					beat.removeFromParentNode()
					break
				}
			}
		}
	}
	
	/// resets all variables for new song
	///
	/// this is not needed if SP get initiated everytime
	func resetvars () {
		self.timelist.removeAll()
		self.powergems.removeAll()
		self.index 		= 0
		self.miss 		= false
		self.power 		= 1
		self.meter 		= 0
		self.segment 	= false
//		self.tohide 	= []
		self.activators.opacity = 0
		self.state 		= .low
		for node in activators.childNodes {
			node.removeFromParentNode()
		}
	}
	
	/// Activate Star Power - Begins countdown
	/// - Parameter power: the power multiple. 3x for Bass, 2x for other instruments
	func activateSP (_ power: Int) {

		self.power = power
		self.state = .activated
		
		hwy.starpower = true
		
		// clean out all the beats in front of activator to start count
		for beat in hwy.beatlines.childNodes {
			if beat.position.z < self.activetime {
				beat.removeFromParentNode()
//				print(beat)
			}
		}
		print ("star power active")
	}
	
	/// called when star notes section is completed succesfully, implement animation here
	func starruncompleted() {
//		var ready = false
		segment = false
		// add to star meter
		if meter < 32 || state == .activated {
			meter 	+= 8
			index 	+= 1
			
			print("starpower acquired")
			
			flash(node: hwy.base)
		}
		// add to star meter
		if meter >= 16 && state != .activated {
			state = .ready
			// todo
			// show activators
			// hide notes that line up with activators
		}
	}
}


private extension StarPower {
	
	/// animate meter back to zero
	func resetmeter () {
		self.index 	= 0
		self.meter 	= 0
		self.miss 	= false
		self.power 	= 1
	}
	
	func flash (node: SCNNode) {
		let track 	= hwy.base.childNode(withName: "track", recursively: false)
		let mat 	= track?.geometry?.firstMaterial
		mat?.diffuse.contents = NSColor.white
		node.runAction(waitflash){
			mat?.diffuse.contents =  NSColor.gray
		}
	}
}


