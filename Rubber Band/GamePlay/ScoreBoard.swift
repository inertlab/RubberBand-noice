//
//  ScoreBoard.swift
//  noice
//
//  Created by Fernando Zamora on 3/8/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import SpriteKit
import SceneKit


/// Display score stats on the Score Board overlay
///
/// Does not keep track of score. See ScoreKeeper for that
class ScoreBoard {
	//skscn is dupicate of gamestats and it is not used.
	static let scene = SKScene.init(fileNamed: "gameStats")
	
	var scorelabel:SKLabelNode {
		return ScoreBoard.scene?.childNode(withName: "score/score") as! SKLabelNode
	}
	var congratslabel:SKLabelNode {
		return ScoreBoard.scene?.childNode(withName: "score/congrats") as! SKLabelNode
	}
	var messagelabel:SKLabelNode {
		return ScoreBoard.scene?.childNode(withName: "score/message") as! SKLabelNode
	}
	var streaklabel:SKLabelNode {
		return ScoreBoard.scene?.childNode(withName: "score/streak") as! SKLabelNode
	}
	var streaknum:SKLabelNode {
		return ScoreBoard.scene?.childNode(withName: "score/streaknumber") as! SKLabelNode
	}
	var screener: SKNode
	
	let sk:ScoreKeeper
	let stars = Stars()

	var fc:Int16 = -1

	init (scorekeeper: ScoreKeeper) {
		print("new scoreboard created")
		self.screener = ScoreBoard.scene!.childNode(withName: "screen")!
		ScoreBoard.scene?.shouldRasterize = false
		self.sk = scorekeeper
		
//		change the layout for the score
		ScoreBoard.scene?.scene?.scaleMode = .aspectFit

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
		self.screener.alpha = 0
		
		updatestats(song: smanager.selected.song)
		if fc == 3 {
//			3 is the difficulty, only Expert displays FC
			stars.update("7")
		} else {
			stars.update(sk.starvalues!.stars.description)
		}
		scorelabel.text = sk.total.dec
		streaknum.text = sk.streak.dec
		scoreDisplay?.run(SKAction.fadeOut(withDuration: 0.25)) {
			if stagemc.track.state != .stats {
				return
			}
			mainView.overlaySKScene = ScoreBoard.scene
			self.screener.run(SKAction.fadeIn(withDuration: 1))
		}
	}
	
	/// Updates user stats: Score, Playcount, etc
	///
	/// - Parameter song: The currently selected song
	func updatestats(song: Song){
		if sk.total <= 0 {
			congratslabel.text = NSLocalizedString("No Score", comment: "")
			var message = NSLocalizedString("There is no score set for this song", comment: "")
			if let statx = ScoreManager.selectStat(song) {
				if let score = User.current.instrument.getscore(statx){
					message = NSLocalizedString("Your current High Score", comment: "current score message") + ": \(score.score.dec)"
					streaklabel.text = NSLocalizedString("Your old streak", comment: "old streeak message") + ": \(score.streak.dec)"
				}
			}
			messagelabel.text = message
			// return without saving
			return
		}
		
		
		// there is a score to record, maybe
		// if there is a stat proceed, else make a new one
		if let oldstat = ScoreManager.selectStat(song) {
			if let oldscore = User.current.instrument.getscore(oldstat){
				streaklabel.text = NSLocalizedString("Your old streak", comment: "old streeak message") + ": \(sk.oldstreak.dec)"
				// compare new socre to old score.
				switch sk.total - sk.oldscore {
				case 1...:
					// this works now but the other way should too. investigate
					congratslabel.text 	= NSLocalizedString("Congratz!", comment: "high score achieved")
					messagelabel.text 	= NSLocalizedString("You beat your old Score", comment: "beat score message") + ": \(sk.oldscore.dec) by \((sk.total - sk.oldscore).dec)!"
					savenewrecord(oldscore)
				case 0:
					congratslabel.text 	= NSLocalizedString("Just Okay", comment: "score tied")
					messagelabel.text 	= NSLocalizedString("you tied the High Score", comment: "score tied message") + ": \(sk.oldscore.dec)"
					saveplaycount(oldscore)
				default:
					congratslabel.text 	= NSLocalizedString("SAD!!! :(", comment: "when the score is too low")
					messagelabel.text 	= NSLocalizedString("Your current High Score", comment: "current score message") + ": \(oldscore.score.dec)"

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
		streaklabel.text 	= NSLocalizedString("This is your first streak", comment: "")

		congratslabel.text 	= NSLocalizedString("New Score!", comment: "")
		messagelabel.text 	= NSLocalizedString("This is the first High Score", comment: "")
	}
	
	/// if there is a New Record score set, saves and updates graphics
	/// - Parameter score: the current score to update
	func savenewrecord(_ score: Score) {
		score.score = sk.total

		if let skstars = sk.starvalues?.stars {
			score.stars = skstars
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
				if score.fccount == 0 {
					score.fccount += 1
				}
//				only count if it's the same difficulty
				score.fccount += 1
			}
			
			if fc > score.fc {
				// new fc is at greater difficulty than previous fc
				// save it and reset the count to 1
				score.fc = fc
				score.fccount = 1
			}
		}
		
		do {
			try pc.viewContext.save()
		} catch  {
			print(error)
		}
	}
}
