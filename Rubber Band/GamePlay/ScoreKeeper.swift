//
//  ScoreKeeper.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/30/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SpriteKit
import SceneKit

let scoreDisplay = SKScene(fileNamed: "scoredisplay.sks")
fileprivate let scoregroup = scoreDisplay?.childNode(withName: "scoregroup")
/// tallies up the score and updates the score display on screen
class ScoreKeeper {
	/// score value of a successful note PRO drums
	var pts				= 25
	var streak:Int16 	= 0

	/// the cumulitive score
	var starvalues:Starvalues?
	
	var total:Int32 = 0 {
		didSet{
			self.label.text = String(self.total)
			self.starvalues?.updatestars(score: self.total)
		}
	}
	/// note value gets multiplied by this
	///
	/// issue: multiplier only changes the multipler number and flow of Orb
	var multiplier = 1 {
		didSet {
			updatexlabel()
		}
	}
	
	func updatexlabel() {
		let value = self.multiplier * stagemc.track.sp.power
		stagemc.track.hwy.spherex.flow(multiplier: self.multiplier)
		
		if value == 1 {
			self.labelx.text = ""
			return
		}
		self.labelx.text = "x" + value.description
	}
	
	/// note comborun, when it reaches 10, multiplier goes up 1
	var comborun: Int16 = 0 {
		didSet {
			switch self.comborun {
			case 0:
				// combo broken
				if multiplier == 4 || multiplier == 6{
					stagemc.track.hwy.flow = false
//					if let crowd = Jukebox.shared.players[.crowd] {
//						crowd.setVolume(0, fadeDuration: 1)
//					}
					Jukebox.shared.stopsinging()
				}
				if oldValue > streak {
					streak = oldValue
				}
				stagemc.track.backdrop.state(.idle)
				multiplier = 1
			case 10:
				multiplier = 2
				stagemc.track.backdrop.state(.combo2)
			case 20:
				multiplier = 3
				stagemc.track.backdrop.state(.combo3)
			case 30:
				// flow achived
				multiplier = 4
				if User.current.instrument == .bass {break}
				stagemc.track.hwy.flow = true
//				if let crowd = Jukebox.shared.players[.crowd] {
//					crowd.setVolume(Jukebox.shared.volume, fadeDuration: 1)
//				}
				Jukebox.shared.singalong()
				stagemc.track.backdrop.state(.combo4)
			case 40:
				if User.current.instrument == .bass {
					multiplier = 5
				}
			case 50:
				// flow achieved
				if User.current.instrument == .bass {
					multiplier = 6
					stagemc.track.hwy.flow = true
//					if let crowd = Jukebox.shared.players[.crowd] {
//						crowd.setVolume(Jukebox.shared.volume, fadeDuration: 1)
//					}
					Jukebox.shared.singalong()
				}
			default:
				break;
			}
		}
	}
	
	/// Score display on screen
	var label 	= scoregroup?.childNode(withName: "score"		) 	as! SKLabelNode
	var labelx 	= scoregroup?.childNode(withName: "multiplier"	) 	as! SKLabelNode
	var time 	= scoreDisplay?.childNode(withName: "time"		)	as! SKLabelNode
	
	init() {
		if User.current.instrument == .prodrums {self.pts = 30}
		self.labelx.text = ""
		self.label.text  = ""
	}
	/// resets all the multipliers to 1 when player breaks streak
	func scoreMiss () {
		// starpower is a seperate class that keeps track of changes in star power
		if stagemc.track.sp.segment {
			stagemc.track.sp.miss = true
		}
		
		Jukebox.shared.players[.drums]?.volume = 0
		
		if comborun != 0 {
			comborun = 0
		}
	}
	
	/// updates score when player hits a note
	func scoreOneUp () {
		Jukebox.shared.players[.drums]?.volume = Jukebox.shared.volume
		total += Int32(self.multiplier * pts * stagemc.track.sp.power)
		
		if multiplier != 4 {
			stagemc.track.hwy.spherex.increment()
		}
		comborun += 1
	}
}

