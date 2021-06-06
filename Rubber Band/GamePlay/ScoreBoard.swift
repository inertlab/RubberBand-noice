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
//		node.fontName = "SF Compact Text Medium Italic"
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
	var streaklabe:SKLabelNode {
		return skscn?.childNode(withName: "streak") as! SKLabelNode
	}
	
	var streaknum:SKLabelNode {
		return skscn?.childNode(withName: "streaknumber") as! SKLabelNode
	}
	
	let labels = Scorelabel()
	
	var total	:Int32
	var stars	:Int16
	var streak	:Int16
	
	init (scorekeeper sk: ScoreKeeper) {
		self.total 	= sk.total
		self.stars 	= sk.starvalues?.stars ?? 0
		if sk.comborun > sk.streak { streak = sk.comborun}
		self.streak = sk.streak
	}
	/// displays the stat screen when game song is done or stopped
	/// - Parameter sk: ScoreKeeper instance with the current score values
	func displaystat() {
		updatestats(song: smanager.selected.song)
		scorelabel.text = total.description
		streaknum.text = streak.description
		scoreDisplay?.run(SKAction.fadeOut(withDuration: 0.25)) {
			if stagemc.track.state != .stats {
				print("not right")
				return
			}
			mainView.overlaySKScene = self.skscn
		}
	}
	
	/// Updates user stats: Score, Playcount, etc
	///
	/// - Parameter song: The currently selected song
	func updatestats(song: Song){
		if total == 0 {
			congratslabel.text = "No Score"
			var message = "There is no score set fot this song"
			if let statx = ScoreManager.selectStat(song) {
				if let score = User.current.instrument.getscore(statx){
					message = "Your current High Score: \(score.score)"
					streaklabe.text = "your old streak was \(score.streak) notes"
				}
			}
			messagelabel.text = message
			// return without saving
			return
		}
		
		// there is a score to record, maybe
		if let statx = ScoreManager.selectStat(song) {
			if let score = User.current.instrument.getscore(statx){
				streaklabe.text = "your old streak was \(score.streak) notes"
				// compare new socre to old score
				switch total - score.score {
				case 1...:
					congratslabel.text 	= "Congratz!"
					messagelabel.text 	= "You beat the old Score \(score.score) by \(total - score.score)!"
					savenewrecord(score)
				case 0:
					print ("score ", score.score)
					congratslabel.text 	= "Just Okay"
					messagelabel.text 	= "you tied the High Score \(score.score)"
					saveplaycount(score)
				default:
					congratslabel.text 	= "SAD!!! :("
					messagelabel.text 	= "You need \(score.score - total) to beat the HS \(score.score)"
					saveplaycount(score)
				}
				
			} else {
				// no current score, make a new one
				newScore(statx)
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
		newscore.instrument = User.current.instrument.rawValue
		newscore.stat 		= stat
		savenewrecord(newscore)
		streaklabe.text = "This is your first streak"
		congratslabel.text 	= "New Score!"
		messagelabel.text 	= "This is the first High Score"
	}
	
	/// if there is a new record score set, saves and updates graphics
	/// - Parameter score: the current score to update
	func savenewrecord(_ score: Score) {
		score.score 		= total
		score.stars 		= stars
		score.difficulty 	= User.current.diff.rawValue
		if	score.streak < streak {
			score.streak = streak
		}
		TextureMover.shared.updateStars(score: score)
		saveplaycount(score)
	}
	
	func saveplaycount(_ score: Score) {
		score.playcount += 1
		score.stat?.playcount += 1
		score.stat?.date = Date()
		do {
			try pc.viewContext.save()
		} catch  {
			print(error)
		}
	}
}
