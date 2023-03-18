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
//fileprivate let scoregroup = scoreDisplay?.childNode(withName: "scoregroup")
/// tallies up the score and updates the score display on screen
class ScoreKeeper {
	/// score value of a successful note PRO drums
	var pts				= 25
	var streak:Int16 	= 0
	var combobreaks  	= 0
	var deadnotes 		= 0
	var highscore:Int32 = 0
	var oldscore:Int32 	= 0
	var oldstreak:Int16	= 0
	/// keeps score of tail sustains
	var tickcount:Int32 = 100 {
		willSet {
//			if new value is negative, it might show in the counter
			if newValue < 0 {return}
//			if new value is the same as old, don't change the UI
			if newValue == tickcount {return}
			label.text = (total + newValue).dec
//			this doesn't work because it changes with early/late hits.
//			it is also affected by FPS
//			total += 1
		}
	}

	/// the cumulitive score
	var starvalues:Starvalues?
	
	var total:Int32 = 0 {
		didSet {
			self.label.text = String(self.total.dec)
			self.starvalues?.updatestars(score: self.total)
			if !labelh.isHidden {
				let add = highscore + total
				labelh.text = (add).description
				if add > 0 {
					labelh.fontColor = .rbBlue
				}
			}
		}
	}
	/// note value gets multiplied by this
	///
	/// NOTE: the note that sets the multiplier, also gets multiplied
	/// issue: multiplier only changes the multipler number and flow of Orb
	var multiplier = 1 {
		didSet {
			updatexlabel()
		}
	}
	
	func updatexlabel() {
		let value = multiplier * stagemc.track.sp.power
		stagemc.track.hwy.spherex.flow(multiplier: multiplier)
		
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
//				this is here to avoid calling on every hit
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
					Jukebox.shared.singalong()
				}
			default:
				break;
			}
		}
	}
	
	/// Score display on screen
	var label 	= scoreDisplay?.childNode(withName: "scoregroup/score") as! SKLabelNode
	var labelx 	= scoreDisplay?.childNode(withName: "scoregroup/multiplier") as! SKLabelNode
	var labelh 	= scoreDisplay?.childNode(withName: "scoregroup/highscore") as! SKLabelNode
	var time 	= scoreDisplay?.childNode(withName: "time") as! SKLabelNode
	
	init() {
		if User.current.instrument == .prodrums {self.pts = 30}
		labelx.text 	= ""
		label.text  	= "0"
		labelh.isHidden = true
		labelh.fontColor = .rbOrange
	}
	/// resets all the multipliers to 1 when player breaks streak
	func scoreMiss() {
		if comborun != 0 {
			combobreaks += 1
			comborun = 0
		}
	}
	
	func deadnote() {
		deadnotes += 1
		scoreMiss()
	}
	
	/// updates score when player hits a note
	func scoreOneUp() {
		total += Int32(multiplier * pts * stagemc.track.sp.power)
	}
	
	/// increments comborun by 1
	///
	/// Needs to run before score total + 1
	func comboup() {
		comborun += 1
		
		if multiplier != 4 {
			stagemc.track.hwy.spherex.increment()
		}
	}
	
	func loadoldscore(_ song: Song) {
		if let score = ScoreManager.getscore(song) {
			labelh.isHidden = false
			highscore 	= score.score * -1
			oldscore 	= score.score
			oldstreak 	= score.streak
			labelh.text = highscore.description
		}
	}
}


protocol ScoreDelegate {
	func tailupdate(_ ticks: Double)
	func taildidend(_ ticks: Double?)
}

extension ScoreKeeper: ScoreDelegate {
	func tailupdate(_ ticks: Double) {
		tickcount = Int32(Int(ticks.rounded()) * multiplier)
	}
	
	/// adds the final score from tails to the total
	/// - Parameter ticks: the total amount of beats sustained
	func taildidend(_ ticks: Double?) {
//		total doesn't get updated during sustain, only the display score. i know right?
		if let beats = ticks {
			// this doesn't work if multiplier changes
			total += Int32(Int(beats.rounded()) * multiplier)
			return
		}
		total += tickcount
	}
}
