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

struct StarCut{
	static let s1  	= 0.06
	static let s2 	= 0.12
	static let s3  	= 0.20
	static let s4 	= 0.45
	static let s5 	= 0.75
	static let sG 	= 1.09
}

struct Starvalues {
	let label = scoreDisplay?.childNode(withName: "stars") as! SKLabelNode
	var stars		:Int16 	= 0
	var goal		:Int32
	var basescore	:Double
	var goldcutoff	:Double
	
	init (sets: Int, beats: Int, basescore: Double) {

		self.basescore = basescore

//		base/beats = possible pts per beat
		let ptsperbeat 	= basescore / Double(beats)
		let bonus 		= Double(sets) * 4 * ptsperbeat
		self.goldcutoff = bonus + basescore
		self.goal 		= Int32(basescore * StarCut.s1)
		self.label.text = "0*"
		
		
		print("gold cutoff, ", goldcutoff)
	}
	
	mutating func updatestars (score: Int32) {
		if score >= goal {
			stars += 1
			switch stars {
			case 1:
				goal = Int32(basescore * StarCut.s2)
				label.text = "1*"
			case 2:
				goal = Int32(basescore * StarCut.s3)
				label.text = "2*"
			case 3:
				goal = Int32(basescore * StarCut.s4)
				label.text = "3*"
			case 4:
				goal = Int32(basescore * StarCut.s5)
				label.text = "4*"
			case 5:
				goal = Int32(goldcutoff)
				// gold stars should only be achieved on expert
				if User.current.diff != .expert {
					goal *= 2
				}
				label.text = "5*"
			case 6:
				goal = Int32(100000000)
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
	
	let hwy			:HWY
	/// gems that activate star power - Crash Cymbals
	let activators	:SCNNode
	let portal 		:SCNNode
	let party 		:SCNParticleSystem
	var GH = false
	
	init(_ hwy: HWY) {
		self.hwy 		= hwy
		self.activators	= hwy.pista.childNode(withName: "starpower", recursively: false)!
		self.portal 	= hwy.base.parent!.childNode(withName: "portal", recursively: true)!
		self.party 		= portal.particleSystems![0]
		self.portal.removeAllParticleSystems()
//		if there are no activator nodes, then this sogn is a guitar hero song. activate SP when it hits 4
		if activators.childNodes.isEmpty {
			self.GH = true
		}
	}
	 
	var state 		= State.low
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
	private var activated 	= false
	
	/// Keeps track of streak during SP segment used in timefunction
	///
	/// - Parameter time: current play time from the midi file
	func trackpower (time: CGFloat){
		if state == .activated {
			if meter == 0 {
				portal.removeAllParticleSystems()
				self.state 		= .low
				self.power 		= 1
				hwy.starpower 	= false
				return
			}
			
			for beat in hwy.beatlines.childNodes {
				if beat.position.z < time {
					meter -= 1
					portal.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = meter * 0.025
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
		self.activators.opacity = 0
		self.state 		= .low
		for node in activators.childNodes {
			node.removeFromParentNode()
		}
	}
	
	/// Activate Star Power - Begins countdown
	/// - Parameter power: the power multiple. 3x for Bass, 2x for other instruments
	func activateSP (_ noteZPos: CGFloat) {
		
		if state != .ready { return }
		power = 2
		
		state = .activated
		portal.addParticleSystem(party)
		hwy.starpower = true
		
		// clean out all the beats in front of activator to start count
		for beat in hwy.beatlines.childNodes {
			if beat.position.z < noteZPos {
				beat.removeFromParentNode()
			}
		}
		print ("star power active")
	}
	
	/// called when star notes section is completed succesfully, implement animation here
	func starruncompleted() {
		segment = false
		// add to star meter
		if meter < 32 || state == .activated {
			meter 	+= 8
			index 	+= 1
			
			portal.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = meter * 0.025
			print("starpower acquired")
			portal.addAnimation(shinedown, forKey: "shine")
			flash(node: hwy.base)
		}
		// add to star meter
		if meter >= 16 && state != .activated {
			state = .ready
		}
//		if this is a guitar hero track, activate starpower as soon as you hit 32
		if GH && meter >= 32 {
			activateSP(Jukebox.shared.currenttime()! * pace.fps)
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
		node.runAction(SCNAction.wait(duration: 0.10)){
			mat?.diffuse.contents =  NSColor.gray
		}
	}
	
	/// turns light on asphalt off
	var shinedown:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.transparent.contentsTransform.m11")
			animation.fromValue 	= 1
			animation.toValue 		= 1.5
			animation.duration 		= 0.5
			animation.repeatCount 	= 0
		return animation
	}
}


