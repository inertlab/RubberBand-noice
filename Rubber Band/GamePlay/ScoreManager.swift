//
//  ScoreManager.swift
//  noice
//
//  Created by Fernando Zamora on 3/8/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import SpriteKit
import SceneKit


/// Retrieves exisiting Scores and Saves new ones
class ScoreManager {
	/// deletes all stats for all players
	///
	/// notice stats cascades and deletes all scores too
	static func deleteallstats() {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		let arr = try? pc.viewContext.fetch(stat)
		for s in arr! {
			pc.viewContext.delete(s)
			print("deleted", s)
		}
		try? pc.viewContext.save()
	}
	
	static func printscores() {
		for stat in User.current.player.stats as! Set<Stats> {
			for score in stat.scores as! Set<Score> {
				print("\(stat.song?.title! ?? "untitled") instrument \(score.instrument), score \(score.score)")
			}
		}
	}
	
	static func getscore(_ song: Song) -> Score? {
		if let stat = selectStat(song) {
			return User.current.instrument.getscore(stat)
		}
		return nil
	}
	
	static func selectStat (_ song: Song) -> Stats? {
		for stat in song.stats as! Set<Stats> {
			if stat.pindex == User.current.player.index {
				return stat
			}
		}
		return nil
	}
	
	static func statcount () -> Int {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		return try! pc.viewContext.count(for: stat)
	}
	
	static func deletestat () -> Int {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		return try! pc.viewContext.count(for: stat)
	}
}


private extension ScoreManager {
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
//		let newscore 		= Score(context: pc.viewContext)
//		newscore.instrument = User.current.instrument.rawValue
//		newscore.stat = stat
//		savenewrecord(newscore)
//
//		congratslabel.text 	= "New Score!"
//		messagelabel.text 	= "This is the first High Score"
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
