//
//  ScoreBoard.swift
//  noice
//
//  Created by Fernando Zamora on 3/8/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import SpriteKit
import SceneKit




enum NCStyle {
	static let frame = CGSize(width: 640, height: 400)
	static func label(size: CGFloat) -> SKLabelNode {
		let node = SKLabelNode()
		node.fontSize = size
		
		return SKLabelNode()
	}
	static func basic() -> SKLabelNode {
		let node = SKLabelNode()
		node.fontName = "Hobo Std Medium"
		node.fontSize = 47
		return node
	}
}

class Scorelabel {
	let scene 		= SKScene(size: NCStyle.frame)
	let score 		= SKLabelNode()
	let congrats 	= SKLabelNode()
	let message  	= SKLabelNode()
	let streak 	 	= SKLabelNode()
	
	init() {
		self.scene.addChild(score)
		self.scene.addChild(congrats)
		self.scene.addChild(message)
		self.scene.addChild(streak)
	}
}


/// Display score stats on the Score Board screen
class ScoreBoard {
	let skscn = SKScene.init(fileNamed: "gameStats")
	var scorelabel:SKLabelNode {
		return skscn?.childNode(withName: "score") as! SKLabelNode
	}
	var congratslabel:SKLabelNode {
		return skscn?.childNode(withName: "congrats") as! SKLabelNode
	}
	var messagelabel:SKLabelNode {
		return skscn?.childNode(withName: "message") as! SKLabelNode
	}
	var streaklabel:SKLabelNode {
		return skscn?.childNode(withName: "streak") as! SKLabelNode
	}
	var streaknum:SKLabelNode {
		return skscn?.childNode(withName: "streaknumber") as! SKLabelNode
	}
	
	let sk:ScoreKeeper
	var fclabel:SKNode
//	let labels = Scorelabel()

	var fc:Int16 = -1

	init (scorekeeper: ScoreKeeper) {
		print("new scoreboard created")
		fclabel = (self.skscn?.childNode(withName: "fc"))!
		sk = scorekeeper

		if sk.combobreaks + sk.deadnotes == 0 && stagemc.track.notesystem.components.isEmpty {
//			all conditions are met for an FC
//			fc value is the same as the difficulty
			fc = User.current.diff.rawValue
		}
		if sk.comborun > sk.streak { sk.streak = sk.comborun }
	}
	/// displays the stat screen when game song is done or stopped
	/// - Parameter sk: ScoreKeeper instance with the current score values
	func displaystat() {
		updatestats(song: smanager.selected.song)
		scorelabel.text = sk.total.dec
		streaknum.text = sk.streak.dec
		scoreDisplay?.run(SKAction.fadeOut(withDuration: 0.25)) {
			if stagemc.track.state != .stats {
				return
			}
			mainView.overlaySKScene = self.skscn
		}
	}
	
	/// Updates user stats: Score, Playcount, etc
	///
	/// - Parameter song: The currently selected song
	func updatestats(song: Song){
		if sk.total <= 0 {
			congratslabel.text = "No Score"
			var message = "There is no score set for this song"
			if let statx = ScoreManager.selectStat(song) {
				if let score = User.current.instrument.getscore(statx){
					message = "Your current High Score: \(score.score.dec)"
					streaklabel.text = "your old streak was \(score.streak.dec) notes"
				}
			}
			messagelabel.text = message
			// return without saving
			return
		}
		
		if fc > -1 {
			fclabel.isHidden = false
		} else {
			fclabel.isHidden = true
		}
		
		// there is a score to record, maybe
		// if there is a stat proceed, else make a new one
		if let oldstat = ScoreManager.selectStat(song) {
			if let oldscore = User.current.instrument.getscore(oldstat){
				streaklabel.text = "your old streak was \(sk.oldstreak.dec) notes"
				// compare new socre to old score.
				switch sk.total - sk.oldscore {
				case 1...:
					// this works now but the other way should too. investigate
					congratslabel.text 	= "Congratz!"
					messagelabel.text 	= "You beat the old Score \(sk.oldscore.dec) by \((sk.total - sk.oldscore).dec)!"
					savenewrecord(oldscore)
				case 0:
					congratslabel.text 	= "Just Okay"
					messagelabel.text 	= "you tied the High Score \(sk.oldscore.dec)"
					saveplaycount(oldscore)
				default:
					congratslabel.text 	= "SAD!!! :("
					messagelabel.text 	= "You need \((sk.oldscore - sk.total).dec) to beat the HS \(oldscore.score.dec)"
					saveplaycount(oldscore)
				}
				
			} else {
				// no current score, make a new one
				newScore(oldstat)
			}
		} else {
			// no stat found, therefore no score found either
			// make a new stat
			newStat(song)
		}
	}
}


private extension ScoreBoard {
	/// creates a new stat where there was none, also created a new Record and attaches it to the correct instrument
	/// - Parameter song: a song to attach stat to
	func newStat (_ song: Song) {
		let stat = Stats(context: pc.viewContext)
		
		stat.setby 	= User.current.player
		stat.pindex = User.current.player.index
		stat.song 	= song
		stat.songid = song.uuid // not sure if this is really needed
		
		newScore(stat)
	}
	
	/// Makes a new record and saves it if no previous record was found
	/// - Parameter stat: the current song stat
	func newScore(_ stat: Stats) {
		let newscore 		= Score(context: pc.viewContext)
		newscore.instrument	= User.current.instrument.rawValue
		newscore.stat 		= stat
		savenewrecord(newscore)
		streaklabel.text 	= "This is your first streak"
		congratslabel.text 	= "New Score!"
		messagelabel.text 	= "This is the first High Score"
	}
	
	/// if there is a new record score set, saves and updates graphics
	/// - Parameter score: the current score to update
	func savenewrecord(_ score: Score) {
		score.score = sk.total
		
		if let skstars = sk.starvalues?.stars {
			if skstars > score.stars {
				score.stars = skstars
			}
		}
		score.difficulty = User.current.diff.rawValue
		TextureMover.shared.updateStars(score: score)
		saveplaycount(score)
	}
	
	func saveplaycount(_ score: Score) {
		score.playcount += 1
		score.stat?.playcount += 1
		score.stat?.date = Date()
		if	score.streak < sk.streak {
			score.streak = sk.streak
		}
		
		
	
		if fc > -1 {
			// new FC is achieved
			
			if fc == score.fc {
//				only count if it's the same difficulty
				score.fccount += 1
			}
			
			if fc > score.fc {
				// new fc is at greater difficulty than previous fc
				// save it and reset the count to 1
				score.fc = fc
				score.fccount = 1
			}
			print("new fc count ", score.fccount)
		}
		
		do {
			try pc.viewContext.save()
		} catch  {
			print(error)
		}
	}
}


