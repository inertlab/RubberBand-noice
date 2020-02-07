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
	let stats = SKScene.init(fileNamed: "gameStats")
	var scorelabel:SKLabelNode {
		return stats?.childNode(withName: "score") as! SKLabelNode
	}
	
	var congratslabel:SKLabelNode {
		return stats?.childNode(withName: "congrats") as! SKLabelNode
	}
	
	var messagelabel:SKLabelNode {
		return stats?.childNode(withName: "message") as! SKLabelNode
	}
	
	
	var streaklabe:SKLabelNode {
		return stats?.childNode(withName: "streak") as! SKLabelNode
	}
	
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
	var multiplier 	= 1 {
		didSet {
			let value = self.multiplier * stagemc.track.sp.power
			stagemc.track.hwy.spherex.flow(multiplier: self.multiplier)
			
			if value == 1 {
				self.labelx.text = ""
				return
			}
			self.labelx.text = "x" + value.description
		}
	}
	
	var streak = 0
	
	/// note comborun, when it reaches 10, multiplier goes up 1
	var comborun = 0 {
		didSet {
			switch self.comborun {
			case 0:
				// combo broken
				if multiplier == 4 {
					stagemc.track.hwy.flow = false
					if let crowd = Jukebox.shared.players[.crowd] {
						crowd.setVolume(0, fadeDuration: 1)
					}
				}
				if oldValue > streak {
					streak = oldValue
				}
				multiplier = 1
			case 10:
				multiplier = 2
			case 20:
				multiplier = 3
			case 30:
				// flow achived
				multiplier = 4
				stagemc.track.hwy.flow = true
				if let crowd = Jukebox.shared.players[.crowd] {
					crowd.setVolume(1, fadeDuration: 1)
				}
			default:
				break;
			}
		}
	}
	
	/// score value of a successful note
	let pts 	= 30
	/// Score display on screen
	var label 	= scoregroup?.childNode(withName: "score"		) 	as! SKLabelNode
	var labelx 	= scoregroup?.childNode(withName: "multiplier"	) 	as! SKLabelNode
	var time 	= scoreDisplay?.childNode(withName: "time"		)	as! SKLabelNode
	
	
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
		Jukebox.shared.players[.drums]?.volume = 1
		total += Int32(self.multiplier * pts * stagemc.track.sp.power)
		
		if multiplier != 4 {
			stagemc.track.hwy.spherex.increment()
		}
		comborun += 1
	}
	
	/// resets score and streaks. only used when loading a new song
	func resetscore () {
		total 			= 0
		multiplier 		= 1
		comborun 		= 0
		streak 			= 0
	}
	
	/// deletes all stats for all players
	///
	/// notice stats cascades and deletes all scores too
	func deleteallstats() {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		let arr = try? pc.viewContext.fetch(stat)
		print("this is happening too")
		for s in arr! {
			pc.viewContext.delete(s)
			print("deleted", s)
		}
		try? pc.viewContext.save()
	}
	
	func printscores() {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		let arr = try? pc.viewContext.fetch(stat)
		for s in arr! {
			if s.prodrums != nil {
			}
		}
	}
	
	/// displays the stat screen when game song is done or stopped.
	///
	/// consolidate with update stats as there is too much crossover
	func displaystat() {
		// update combo one more time, because it only gets updated when streak fails
		if comborun > streak { streak = comborun}
		scorelabel.text = total.description
		streaklabe.text = "your longest streak was \(streak) notes"
		mainView.overlaySKScene?.run(SKAction.fadeOut(withDuration: 0.25)) {
			mainView.overlaySKScene = self.stats
		}
	}
	
	/// Updates user stats: Score, Playcount, etc
	///
	/// - Parameter song: The currently selected song
	///
	func updatestats(song: Song){
		
		if total == 0 {
			congratslabel.text = "No Score"
			var message = "There is no score set fot this song"
			if let statx = selectStat(song) {
				if let score = getscorebyinstrument(statx){
					message = "Your current High Score: \(score.score)"
				}
			}
			messagelabel.text = message
			// return without saving
			return
		}
		
		// there is a score to record, maybe
		if let statx = selectStat(song) {
			if let score = getscorebyinstrument(statx){
				// compare new socre to old score
				switch total - score.score {
				case 1...:
					congratslabel.text 	= "Congratz!"
					messagelabel.text 	= "You got a new High Score by \(total - score.score)!"
					savenewrecord(score)
				case 0:
					congratslabel.text 	= "Try Harder :("
					messagelabel.text 	= "you tied your last score"
					savescoreplaycount(score)
				default:
					congratslabel.text 	= "Try Harder :("
					messagelabel.text 	= "You need \(score.score - total) to beat the high score"
					savescoreplaycount(score)
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
	

	
	/// retrieves the score for the current user isntrument
	/// - Parameter stat: the Stat to the played Song
	func getscorebyinstrument(_ stat: Stats) -> Score? {
		switch User.current.instrument {
		case .drums:
			return stat.drums
		case .prodrums:
			return stat.prodrums
		default:
			return stat.guitar
		}
	}
	
	func selectStat (_ song: Song) -> Stats? {
		for stat in smanager.selected.song.stats as! Set<Stats> {
			if stat.pindex == User.current.player.index {
				return stat
			}
		}
		print("no stat found")
		return nil
	}
	
	func statcount () -> Int {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		return try! pc.viewContext.count(for: stat)
	}
	
	func deletestat () -> Int {
		
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		return try! pc.viewContext.count(for: stat)
	}
}


private extension ScoreKeeper {
	
	/// keep out - dead code
	///
	/// - Parameter song: Song() - curently selected song
	/// - Returns: brand spankin new Stats()
	func fetchstats(song: Song) -> Stats? {
		let fetstat:NSFetchRequest<Stats> = Stats.fetchRequest()
		let uuidp 	= NSPredicate(format: "songid == %@", song.uuid!.uuidString)
		let indexp 	= NSPredicate(format: "playerindex == %@", User.current.player.index.description)
		fetstat.predicate	= NSCompoundPredicate(andPredicateWithSubpredicates: [uuidp,indexp])
		do {
			let stats = try pc.viewContext.fetch(fetstat)
			return stats.first
		} catch let err as NSError {
			print(err)
		}
		return nil
	}
	
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
		switch User.current.instrument {
		case .drums:
			stat.drums 		= newscore
		case .prodrums:
			stat.prodrums 	= newscore
		case .bass:
			stat.bass 		= newscore
		case .keys:
			stat.keys		= newscore
		default:
			stat.guitar 	= newscore
		}
		
		savenewrecord(newscore)
		
		congratslabel.text 	= "New Score!"
		messagelabel.text 	= "This is the first High Score"
		
	}
	
	/// if there is a new record score set, saves and updates graphics
	/// - Parameter score: the current score to update
	func savenewrecord(_ score: Score) {
		score.score 		= total
		score.stars 		= starvalues!.stars
		score.difficulty 	= User.current.diff.rawValue
		TextureMover.shared.updateStars(score.stars, dif: score.difficulty)
		savescoreplaycount(score)
	}
	
	func savescoreplaycount(_ score: Score) {
		score.playcount += 1
		do {
			try pc.viewContext.save()
		} catch  {
			print(error)
		}
	}
}

/// instance of ScoreKeeper: tallies all the scores and updates score display
let scorekeeper = ScoreKeeper()

