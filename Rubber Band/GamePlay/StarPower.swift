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
	var stars:Int16 = 0
	var goal:Int32 = 0
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
	var state 		= State.low
	/// an list of gems to hide when star power is active so they aren't double hit
	var tohide 		= [SCNNode]()
	/// gems that activate star power - Crash Cymbals
	let activators	= hwy.pista.childNode(withName: "starpower", recursively: false)!
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
		
		if index < self.timelist.count {	// keeps index from going out of range
			if !self.segment && time > self.timelist[index].0 { //star segment has began
				self.segment = true
				print("segment is on")
			}
			if self.segment {				// star segment is active
				if self.miss {				// star segement ends immediate if note is missed - failure
					self.powermissed()
//					self.success()
				} else if time > self.timelist[index].1 {	// star segment ended succesfully
					self.success()
				}
			}
		}
		
		switch self.state {
		case .countdown:
			
			if meter == 0 {
				self.state = .low
				self.power = 1
				if scorekeeper.multiplier == 4 {
					asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0.25
					
				}else{
					asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0
				}
				break
			}
			
			for beat in hwy.beatlines.childNodes {
				if beat.position.z < time {
					print(meter)
					meter -= 1
					beat.removeFromParentNode()
					break
				}
			}
		
			break
		case .low:
			break
		case .ready: // when ready, the triggers are displayed and tracked
			break
		}
	}
	
	/// resets all variables for new song
	func resetvars () {
		self.timelist.removeAll()
		self.powergems.removeAll()
		self.index 		= 0
		self.miss 		= false
		self.power 		= 1
		self.meter 		= 0
		self.segment 	= false
		starpower.tohide = []
		self.activators.opacity = 0
		self.state = .low
		for c in activators.childNodes {
			c.removeFromParentNode()
		}
	}
	
	/// Checks if note was present when trigger was hit
	///
	/// - Returns: returns true on success and false on fail
	func checkHit() -> Bool {
		let max = hwy.pista.position.z + pace.hitwindow
		let min = hwy.pista.position.z - pace.hitwindow
	
		for trigger in self.activators.childNodes {
			
			if trigger.position.z < max && trigger.position.z > min {
				// trigger was successful
				self.activetime = trigger.position.z
				self.power = 2
				self.state = .countdown
				
				if scorekeeper.multiplier == 4 {
					asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0.75
				}else{
					asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0.5
				}
				
				trigger.removeFromParentNode()
				activators.opacity = 0
				for gem in tohide {
					if gem.position.z < hwy.pista.position.z + 5 {
						gem.removeFromParentNode()
						continue
					}
					gem.isHidden = false
				}
				greenC.hit()
				
				for beat in hwy.beatlines.childNodes {
					if beat.position.z < self.activetime {
						beat.removeFromParentNode()
					}
				}
				print ("star power active")
				return true
			}
		}
		return false
	}
}


private extension StarPower {
	/// called when star notes are hit succesfully, implement animation here
	func success() {
		segment = false
		if meter < 32 || state == .countdown {
			meter 	+= 8
			index 	+= 1
			print("starpower acquired")
			
			flash(node: hwy.base)
		}
		if meter >= 16 && state != .countdown {
			state = .ready
			for trigger in activators.childNodes {
				if trigger.position.z < hwy.pista.position.z - 5 {
					trigger.removeFromParentNode()
					continue
				}
			}
			activators.opacity = 1
			for note in tohide {
				if note.position.z < hwy.pista.position.z + 5 {
					continue
				}
				note.isHidden = true
			}
		}
	}
	
	/// handles animations and score when player fails
	func powermissed () {	//
		self.segment 	= false
		self.miss 		= false
		for gem in self.powergems[index]{
			switch gem.categoryBitMask {
			case GemBit.red:
				gem.geometry?.firstMaterial = gems.m_red
			case GemBit.blue:
				gem.geometry?.firstMaterial = gems.m_blue
			case GemBit.green:
				gem.geometry?.firstMaterial = gems.m_green
			case GemBit.yellow:
				gem.geometry?.firstMaterial = gems.m_yellow
			case GemBit.orange:
				gem.geometry?.firstMaterial = gems.m_orange
				break
			default:
				gem.geometry?.firstMaterial = gems.m_cymbals
			}
		}
		self.index += 1
		print("segment failed")
	}
	
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

let starpower = StarPower()

enum State {
	case countdown
	case low
	case ready
}
