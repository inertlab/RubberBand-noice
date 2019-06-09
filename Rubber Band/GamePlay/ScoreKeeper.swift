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
	
	/// the cumulitive score
	var starvalues:Starvalues?
	
	var total:Int32 = 0 {
		didSet{
			self.label.text = String(self.total)
			self.starvalues?.updatestars(score: self.total)
		}
	}
	/// note value gets multiplied by this
	var multiplier 	= 1 {
		didSet {
			let val = self.multiplier * starpower.power
			hwy.sphereglow.removeAllActions()
			if val == 1 {
				self.labelx.text = ""
				hwy.sphereglow.opacity = 0
			} else {
				if self.multiplier == 4 {
					hwy.sphereglow.opacity = 0.1
					hwy.sphereglow.runAction(SCNAction.repeatForever(spinpulse))
				} else {
					hwy.sphereglow.geometry?.firstMaterial?.diffuse.contentsTransform.m41 += 0.5
					hwy.sphereglow.runAction(pulsequick)
				}
				self.labelx.text = "x" + val.description
			}
		}
	}
	/// note streak, when it reaches 10, multiplier goes up 1
	var submultiplier = 1
	/// score value of a successful note
	let pts 		= 30
	/// Score display on screen
	var label 	= scoregroup?.childNode(withName: "score"		) 	as! SKLabelNode
	var labelx 	= scoregroup?.childNode(withName: "multiplier"	) 	as! SKLabelNode
	var time 	= scoreDisplay?.childNode(withName: "time"		)	as! SKLabelNode
	
	
	/// resets all the multipliers to 1 when player breaks streak
	func scoreMiss () {
//		starpower is a seperate class that keeps track of changes in star power
		if starpower.segment {
			starpower.miss = true
		}
		self.submultiplier = 1
		hwy.spherex.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = 0
		if multiplier == 4 {
			asphalt?.addAnimation(lightdown, forKey: "mdiffuse")
			asphalt?.geometry?.firstMaterial?.multiply.intensity = 0.9
			if let c = Jukebox.shared.players[.crowd] {
				c.setVolume(0, fadeDuration: 1)
			}
			if starpower.state == .countdown {
				asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0.5
			}else{
				asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0
			}
		}
		self.multiplier = 1
	}
	
	/// updates score when player hits a note
	func scoreOneUp () {
		self.total += Int32(self.multiplier * pts * starpower.power)
		self.multiplierMath()
	}
	
	/// resets score and streaks. only used when loading a new song
	func resetscore () {
		total 			= 0
		multiplier 		= 1
		submultiplier 	= 1
		asphalt?.geometry?.firstMaterial?.multiply.intensity = 0.8
		asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0
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
//				print("player missign \(s.prodrums?.score, s.song?.title!, s.guitar?.score, s.playcount)")
			}
		}
	}
	
	func displaystat() {
		switchboard.updatestate(gamestate: .statsdisplay)
		scorelabel.text = scorekeeper.total.description
		mainView.overlaySKScene = stats
		TextureMover.shared.changeStars(scorekeeper.starvalues!.stars)
	}
	
	/// Updates user stats: Score, Playcount, etc
	///
	/// - Parameter song: The currently selected song
	func updatestats(song: Song){
		if scorekeeper.total > 0 {
			
			if selectedStat.prodrums == nil {
				let drums = Score(context: pc.viewContext)
				drums.score = scorekeeper.total
				selectedStat.prodrums = drums
				congratslabel.text = "New Score!"
				messagelabel.text = "This is the first recorded score on this song"
				
			} else if scorekeeper.total > selectedStat.prodrums!.score {
				congratslabel.text = "Congratulations!"
				messagelabel.text = "You set a new High Score by \(scorekeeper.total - selectedStat.prodrums!.score)!"
				selectedStat.prodrums?.score = scorekeeper.total
				selectedStat.prodrums?.stars = scorekeeper.starvalues!.stars
			} else {
				congratslabel.text = "Try Harder :("
				messagelabel.text = "You need \(selectedStat.prodrums!.score - scorekeeper.total) to beat your score"
				return
			}
			
			try? pc.viewContext.save()
		}
	}
	
	func spin()  {
		hwy.sphereglow.runAction(SCNAction.repeatForever( spinpulse))
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
		let indexp 	= NSPredicate(format: "playerindex == %@", User.current.player.index.description)
		fetstat.predicate	= NSCompoundPredicate(andPredicateWithSubpredicates: [uuidp,indexp])
		do {
			let stats = try pc.viewContext.fetch(fetstat)
			if stats.count > 0 {
				return stats[0]
			}
			return nil
		} catch let err as NSError {
			print(err)
		}
		return nil
	}

	/// keeps track of multiplier streak
	func multiplierMath(){
		if multiplier == 4 {
			return
		}
		self.submultiplier += 1

		hwy.spherex.geometry?.firstMaterial?.diffuse.contentsTransform.m41 += 0.025

		if self.submultiplier > 10 {
			
			self.submultiplier 	= 1
			self.multiplier 	+= 1
//			hwy.spherex.geometry?.firstMaterial?.transparent.contentsTransform.m41 -= 0.25
			// 4x multiplier reached, add groove animations and crowd sing along
			if multiplier == 4 {
				asphalt?.addAnimation(lightup, forKey: "selfIllumination")
				asphalt?.geometry?.firstMaterial?.multiply.intensity = 0.99
				if let c = Jukebox.shared.players[.crowd] {
					c.setVolume(1, fadeDuration: 1)
				}
				if starpower.state == .countdown {
					asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0.75
				}else{
					asphalt?.geometry?.firstMaterial?.selfIllumination.contentsTransform.m41 = 0.25
				}
			}
		}
	}
	
	/// lights up the asphalt
	var lightup:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.diffuse.intensity")
			animation.fromValue 	= 0.25
			animation.toValue 		= 1
			animation.duration 		= 0.5
			animation.fillMode 		= CAMediaTimingFillMode.forwards
			animation.repeatCount 	= 0
			animation.isRemovedOnCompletion = false
		return animation
	}
	
	/// turns light on asphalt off
	var lightdown:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.diffuse.intensity")
			animation.fromValue 	= 1
			animation.toValue 		= 0.25
			animation.duration 		= 0.25
			animation.autoreverses 	= false
			animation.fillMode 		= CAMediaTimingFillMode.forwards
			animation.repeatCount 	= 0
			animation.isRemovedOnCompletion = false
		return animation
	}
	
	/// pulse On then Off - once
	/// total duration should = spinpulse total duration
	var pulse:SCNAction {
		let pulsef 		= SCNAction.fadeOpacity(by: 0.9, duration: 0.5)
		let pulseb 		= SCNAction.fadeOpacity(by: -0.9, duration: 2.5)
		let sequence 	= SCNAction.sequence([pulsef, pulseb])
		return sequence
	}
	
	/// pulse On then Off - once
	/// total duration should = spinpulse total duration
	var pulsequick:SCNAction {
		let pulsef 		= SCNAction.fadeOpacity(by: 0.6, duration: 0.25)
		let pulseb 		= SCNAction.fadeOpacity(by: -0.6, duration: 0.75)
		let sequence 	= SCNAction.sequence([pulsef, pulseb])
		return sequence
	}
	
	/// spin and pulse forever
	var spinpulse:SCNAction {
		let spin 	= SCNAction.rotateBy(x: 0, y: 0, z: 0.75, duration: 3)
		let group 	= SCNAction.group([pulse, spin])
		return group
	}
}

/// instance of ScoreKeeper: tallies all the scores and updates score display
let scorekeeper = ScoreKeeper()

