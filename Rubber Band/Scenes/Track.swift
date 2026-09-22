//
//  Track.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/29/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit

enum Songstate {
	case playing, stats, paused
}

/// confroms to hwy track animation
protocol Track: AnyObject {
//	var particle: SCNNode {get}
	var backdrop 	:Backdrop {get}
	var scorekeeper :ScoreKeeper {get}
	var hwy			:HWY  {get}
	var sp			:StarPower {get}
	var state		:Songstate {get set}
	var starsystem	:GKComponentSystem<StarNoteComp> {get}
	var notesystem	:GKComponentSystem<NoteComp> {get}
	var tailsystem	:GKComponentSystemCGF {get}
	var notes 		:Set<GKEntity> {get set}

	func tracker(_ cgsongtime: CGFloat, _ hwytime: CGFloat)
	func showstats()
	/// convenience method for laying track
	func laytrack()
}

extension Track {
	
	func handleBasicEvents(_ btn: Button) { }

	/// moves the hwy track animation
	/// - Parameter cgsongtime: Song current play time cast as CGFloat
	/// - Parameter beatframe: Song current play time converted to HWY units
	func tracker(_ cgsongtime: CGFloat, _ hwytime: CGFloat) {
		
		self.hwy.asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = cgsongtime * pace.asphalt
		
		self.hwy.pista.position.z = hwytime
		
		self.sp.trackpower(time: hwytime)
	}
	
	/// Displays the score of the current song before going back to main menu
	///
	/// options to replay song should be added here
	func showstats() {
		self.state = .stats
		let scoreboard = ScoreBoard(scorekeeper: self.scorekeeper)
		
		smanager.refreshnext()

		scoreboard.displaystat()
		hwy.base.removeAllActions()
		hwy.base.runAction(SCNAction.move(to: SCNVector3(0, -11, 1.5), duration: 0.75)) {
			Jukebox.shared.stop()
		}
	}
	
	func startparticle() {
		let box 			= SCNNode()
		box.name 			= "box"
		box.position.z 		= -9
		box.position.y 		= 3
		box.addParticleSystem(spartiscle!)
		self.hwy.base.parent?.addChildNode(box)
	}
	
	func crankup() {
		self.hwy.base.position.y = -11
		self.hwy.base.position.z = 1.5
		self.hwy.base.runAction(SCNAction.move(to: SCNVector3(0, 0, 0), duration: 1))
	}
	
	//MARK: - Star Hit Test
	func starmissed(_ note: NoteComp) {
		if let star = note.entity?.component(ofType: StarNoteComp.self) {
			for comp in starsystem.components {
				if comp.set == star.set {
					comp.starmissed()
					comp.entity?.removeComponent(ofType: StarNoteComp.self)
				}
			}
		}
	}
	
	/// checks if note was a starnote
	/// - Parameter star: starnotecomp
	/// - Return: If starpower is ready to activate it returns true
	///
	/// The return is handled differently by each instrument
	func starhit(_ star: StarNoteComp) -> Bool {
		var success = false
		sp.segment = true
		if star.meta {
			sp.starruncompleted()
			if sp.state == .ready {
				success = true
			}
		}
		star.node.opacity = 0
		star.entity?.removeComponent(ofType: StarNoteComp.self)
		return success
	}
	
	func checkpowerchain(_ note: NoteComp) -> Bool {
		var success = false
		if let starcomp = note.entity?.component(ofType: StarNoteComp.self) {
			sp.segment = true
//			this checks if starcomp is the last in the batch but it doesnt always work
			if starcomp.meta {
				sp.starruncompleted()
				if sp.state == .ready {
					success = true
				}
			}
			starcomp.node.opacity = 0
			starcomp.entity?.removeComponent(ofType: StarNoteComp.self)
		}
		return success
	}
	
	func checkpowerchain2(_ note: NoteComp) -> Bool {
		if let starcomp = note.entity?.component(ofType: StarNoteComp.self) {
			sp.segment = true
			starcomp.node.opacity = 0
			starcomp.entity?.removeComponent(ofType: StarNoteComp.self)
//			check to see if this is the last starnote in the set, completes the chain
			if let nextnote = starsystem.components.first {
				if starcomp.set != nextnote.set {
					return true
				}
			} else {
				return true
			}
		}
		return false
	}
}


let spartiscle = SCNParticleSystem(named: "sparticle.scnp", inDirectory: particleDir)
