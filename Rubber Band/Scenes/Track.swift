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
protocol Track: class {
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
	
	func handleBasicEvents(_ btn: Button) {
		
	}

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

		scoreboard.displaystat()
		hwy.base.removeAllActions()
		hwy.base.runAction(SCNAction.move(to: SCNVector3(0, -11, 1.5), duration: 0.75)) {
			Jukebox.shared.stop()
		}
	}
	
	func startparticle () {
		let box 			= SCNNode()
		box.name 			= "box"
		box.position.z 		= -22
		box.position.y 		= 2
		box.renderingOrder 	= -2
		box.addParticleSystem(spartiscle!)
//		spartiscle?.blendMode = .alpha
		self.hwy.base.parent?.addChildNode(box)
	}
	
	func crankup () {
		self.hwy.base.position.y = -11
		self.hwy.base.position.z = 1.5
		self.hwy.base.runAction(SCNAction.move(to: SCNVector3(0, 0, 0), duration: 1))
	}
	
	//MARK: - Star Hit Test
	func starmissed (_ entity: GKEntity) {
		if let star = entity.component(ofType: StarNoteComp.self) {
			
			for comp in starsystem.components {
				if comp.set == star.set {
					comp.starmissed()
					comp.entity?.removeComponent(ofType: StarNoteComp.self)
				}
			}
		}
	}
	
	/// checks if note was a starnote
	/// - Parameter entity: the entity of the current component
	/// - Return: If starpower is ready to activate it returns true
	///
	/// The return is handled differently by each instrument
	func starhit (_ entity: GKEntity) -> Bool {
		var success = false
		if let star = entity.component(ofType: StarNoteComp.self) {
			print("checking star")
			if star.meta {
				sp.starruncompleted()
				if sp.state == .ready {
					success = true
				}
			}
			star.node.opacity = 0
			entity.removeComponent(ofType: StarNoteComp.self)
		}
		return success
	}
	
}

fileprivate let spartiscle = SCNParticleSystem(named: "sparticle.scnp", inDirectory: particleDir)
