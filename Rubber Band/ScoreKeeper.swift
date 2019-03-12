//
//  ScoreKeeper.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/30/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SpriteKit


/// tallies up the score and updates the score display on screen
class ScoreKeeper {
	/// the cumulitive score
	var total:Int32 = 0
	/// note value gets multiplied by this
	var multiplier 	= 1
	/// note streak, when it reaches 10, multiplier goes up 1
	var submultiplier = 1
	/// score value of a successful note
	let pts 		= 25
	
	/// Score display on screen
	var label 	= scoreDisplay?.childNode(withName: "score"		) as! SKLabelNode
	var labelx 	= scoreDisplay?.childNode(withName: "multiplier") as! SKLabelNode
	var time 	= scoreDisplay?.childNode(withName: "time"		) as! SKLabelNode
	
	/// resets all the multipliers to 1 when player breaks streak
	func scoreMiss () {
//		starpower is a seperate class that keeps track of changes in star power
		if starpower.segment {
			starpower.miss = true
		}
		self.submultiplier = 1
		
		if multiplier == 4{
			asphalt?.addAnimation(lightdown, forKey: "mdiffuse")
			asphalt?.geometry?.firstMaterial?.multiply.intensity = 0.75
		}
		
		self.multiplier 	= 1
		self.labelx.text 	= String(self.multiplier * starpower.power)
	}
	
	/// updates score when player hits a note
	func scoreOneUp () {
		self.total += Int32(self.multiplier * pts * starpower.power)
		self.multiplierMath()
		self.label.text = String(self.total)
	}
	
	/// resets score and streaks. only used when laoding a new song
	func resetscore () {
		self.total 			= 0
		self.multiplier 	= 1
		self.submultiplier 	= 1
		self.label.text 	= "0"
		self.labelx.text 	= "1"
	}
	
	
	/// deletes all stats for all players
	///
	/// notice stats cascades and deletes all scores too
	func deleteallstats() {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		let arr = try? pc.viewContext.fetch(stat)
		for s in arr! {
			pc.viewContext.delete(s)
		}
		try? pc.viewContext.save()
	}
	
	func printscores() {
		let stat:NSFetchRequest<Stats> = Stats.fetchRequest()
		let arr = try? pc.viewContext.fetch(stat)
		for s in arr! {
			if s.prodrums != nil {
				
				print("player missign \(s.prodrums?.score, s.song?.title!, s.guitar?.score, s.playcount)")
			}
		}
	}
	
	/// Updates user stats: Score, Playcount, etc
	///
	/// - Parameter song: The currently selected song
	func updatestats(song: Song){
		if scorekeeper.total > 0 {	// don't do notting if player didn't hit a single note
			// if no score is found for current instrument, make a new Score
			// replace this with a switch statement in future to determin which instrument to update
			if selectedStat.prodrums == nil {
				let drums = Score(context: pc.viewContext)
				drums.score = scorekeeper.total
				selectedStat.prodrums = drums
			} else {
				if scorekeeper.total > selectedStat.prodrums!.score {
					selectedStat.prodrums?.score = scorekeeper.total
				} else {
					// nothing is updated or saved
					print("you did not beat your old score")
					return
				}
			}
			
			try? pc.viewContext.save()

			print("congrats! you beat your high score")
		}
	}
}

private extension ScoreKeeper {
	
	func newscore () -> Score {
		let score = Score(context: pc.viewContext)
		return score
	}
	
	/// keep out - dead code
	///
	/// - Parameter song: Song() - curently selected song
	/// - Returns: brand spankin new Stats()
	func fetchstats(song: Song) -> Stats? {
		let fetstat:NSFetchRequest<Stats> = Stats.fetchRequest()
		let uuidp 	= NSPredicate(format: "songid == %@", song.uuid!.uuidString)
		let indexp 	= NSPredicate(format: "playerindex == %@", userdef.player.index.description)
		fetstat.predicate	= NSCompoundPredicate(andPredicateWithSubpredicates: [uuidp,indexp])
		do {
			let stats = try pc.viewContext.fetch(fetstat)
			if stats.count > 0 {
				return stats[0]
			}
			return nil
		}catch let err as NSError {
			print(err)
		}
		return nil
	}

	/// keeps track of multiplier streak
	func multiplierMath(){
		self.submultiplier += 1
		if self.submultiplier > 5 && self.multiplier < 4{
			self.submultiplier 	= 1
			self.multiplier 	+= 1
			self.labelx.text 	= String(self.multiplier * starpower.power)
			if multiplier == 4 {
				print("yes")
				asphalt?.addAnimation(lightup, forKey: "selfIllumination")
				asphalt?.geometry?.firstMaterial?.multiply.intensity = 0.96
			}
		}
	}
	
	/// lights up the asphalt
	var lightup:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.selfIllumination.intensity")
			animation.fromValue 	= 0.25
			animation.toValue 		= 1.5
			animation.duration 		= 0.5
			animation.fillMode 		= kCAFillModeForwards
			animation.repeatCount 	= 0
			animation.isRemovedOnCompletion = false
		return animation
	}
	
	/// turns light on asphalt off
	var lightdown:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.selfIllumination.intensity")
			animation.fromValue 	= 1.5
			animation.toValue 		= 0.25
			animation.duration 		= 0.25
			animation.autoreverses 	= false
			animation.fillMode 		= kCAFillModeForwards
			animation.repeatCount 	= 0
			animation.isRemovedOnCompletion = false
		return animation
	}
}

/// instance of ScoreKeeper: tallies all the scores and updates score display
let scorekeeper = ScoreKeeper()
