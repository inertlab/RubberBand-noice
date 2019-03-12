//
//  File.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/22/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit



/// texture for gems
let gem_diffuse = #imageLiteral(resourceName: "gem_diff.jpg")
let cym_diffuse = #imageLiteral(resourceName: "cymbals.jpg")

/// Keeps track of StarPower notes and streaks
class StarPower {
	var state 	= State.low
	/// an list of gems to hide when star power is active so they aren't double hit
	var tohide 	= [SCNNode]()
	/// gems that activare star power - Crash Cymbals
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
	var meter 		= 0
	private var activated = false
	
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
				} else if time > self.timelist[index].1 {	// star segment ended succesfully
					self.success()
				}
			}
		}
		
		switch self.state {
		case .countdown:
			if meter > 0 {
				for b in hwy.beatlines.childNodes {
					if b.position.z < time - 11 {
						b.removeFromParentNode()
						continue
					}
					if b.position.z < time - 10 {
						b.removeFromParentNode()
						meter -= 1
						break
					}
				}
			} else {
				self.state = .low
				self.power = 1
				scorekeeper.labelx.text = "1"
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
			
				self.power = 2
				self.state = .countdown
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
				print ("star pwer active")
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
		if meter < 100 {
			meter 	+= 50
			index 	+= 1
			print("starpower aquired")
			
			flash(node: hwy.base)
		}
		if meter >= 50 && state != .countdown {
			state = .ready
			for trigger in activators.childNodes {
				if trigger.position.z < hwy.pista.position.z + 5 {
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

