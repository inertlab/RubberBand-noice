//
//  GuitarStage.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/14/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit



final class GuitarStage: Performing, Track, KeyUp {
	var tailsystem 	= GKComponentSystemCGF(componentClass: Tailanimate.self)
	var starsystem	: GKComponentSystem<StarNoteComp>
	var notesystem	: GKComponentSystem<NoteComp>
	var notes 		= Set<GKEntity>()

	var sp: StarPower
	
	let scn: SCNScene
	let hwy: HWY
	let triggers		:[Button: StringTrigger]
	var hand:Chord 		= []
	
	var state:Songstate = .playing
	var power = 2
	
	init() {
		self.notesystem 	= GKComponentSystem(componentClass: NoteComp.self)
		self.starsystem		= GKComponentSystem(componentClass: StarNoteComp.self)
		self.scn = SCNScene(named: "art.scnassets/scns/strings.scn")!
		self.hwy = HWY(self.scn)
		self.triggers = [
			Button.red: 	StringTrigger(note: .red, 	hwy: self.hwy)	,
			Button.blue: 	StringTrigger(note: .blue, 	hwy: self.hwy)	,
			Button.green: 	StringTrigger(note: .green,	hwy: self.hwy)	,
			Button.orange: 	StringTrigger(note: .orange, 	hwy: self.hwy)	,
			Button.yellow: 	StringTrigger(note: .yellow, 	hwy: self.hwy)	,
		]
		self.sp = StarPower(self.hwy)
		startparticle()
		if User.current.instrument == .bass {
			self.power = 4
		}
	}
	
	func handleevent(_ event: Button) {
		
		if state == .playing {
			switch event {
			case .strum, .up, .down:
				if hand.isEmpty {
					miss([event])
				} else {
					notecheck()
				}
			case .green, .red, .yellow, .blue, .orange:
				hand.insert(event)
				triggers[event]?.fretted()
				for case let tail as Tailanimate in tailsystem.components {
					tail.keydown(event)
				}
			case .plus:
				if sp.state == .ready {
					sp.activetime = hwy.pista.position.z
					sp.activateSP(power)
				}
			case .start:
				state = .stats
				showstats()
			default:
				break
			}
		} else {
			stagemc.loadstage()
		}
	}
	
	func handlekeyup(_ event: Button) {
		hand.remove(event)
		triggers[event]?.open()
		
		for case let tail as Tailanimate in tailsystem.components {
			tail.keyup(event)
		}
	}
	
	func laytrack() -> Int {
		return  MusicSheet.shared.layStringTrack()
	}
	
	func tracker(_ cgsongtime: CGFloat, _ hwytime: CGFloat) {
		hwy.asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = cgsongtime * pace.asphalt
		
		hwy.pista.position.z = hwytime
		
		sp.trackpower(time: hwytime)
		
		trackdeadnotes(hwytime: hwytime)
		tailsystem.update(hwytime)
	}
}



private extension GuitarStage {
	
	func trackdeadnotes(hwytime: CGFloat) {
		if notesystem.components.isEmpty { return }
		let note = notesystem.components[0]
		
		if note.node.position.z < hwytime - pace.hitwindow {
//			if note.status == .remove {
//				notes.remove(note.entity!)
//				return
//			}
			if note.status == .live {
				if let tail = note.entity?.component(ofType: TailComp.self){
					tail.maketailgray()
				}
				starmissed(note.entity!)
//				note.entity?.removeComponent(ofType: NoteComp.self)
				scorekeeper.scoreMiss()
//				notesystem.removeComponent(note)
				notes.remove(note.entity!)
			} else {
				// this entity will never be removed from notes.
				notesystem.removeComponent(note)
			}
		}
	}
	
	func notecheck() {
		
		let max = hwy.pista.position.z + pace.hitwindow
		
		for note in notesystem.components {
			if note.status == .live {
				// this note is inside the hitbox. if it's not hit then it's a miss
				if note.node.position.z < max {
					// mark for removall - this gets changed to skip if there is a tail component
					note.status = .remove
					// if there is only one note
					if note.chord.count == 1 {
						let first = hand.sorted {$0.rawValue > $1.rawValue}.first
						if first == note.chord.first {
							// check to see if entity has a tail if it does, start tail animation
							checktail(note.entity!)
							if starhit(note.entity!) {
							// show visuals for ready power
							}
							oneup(chord: note.chord)
							
							note.node.removeFromParentNode()
							break
						}
						// this is if there are multiple notes or chord
					} else {
						if hand == note.chord {
							// check to see if entity has a tail if it does, start tail animation
							checktail(note.entity!)
							if starhit(note.entity!) {
							// show visuals that it is ready
							}
							oneup(chord: note.chord)
							// note has been hit, remove from game
							note.node.removeFromParentNode()
							// checkstarhit(entity)
							break
						}
					}
				} else {
					// once a note is found outside the box we exit, all notes inside the hitbox have been checked
					// this might cause a bug when no more notes are found at end of song
					break
				}
				// this is the only time a miss is registered
				starmissed(note.entity!)
				notes.remove(note.entity!)
				scorekeeper.scoreMiss()
			}
			
		}
	}
	
	/// Checks to see if component has a tail, if it does, Tailanimate component
	/// - Parameter entity: NoteEntity
	///
	/// See Tailanimate.update() for further instructions
	func checktail (_ entity: GKEntity) {
		if let _ = entity.component(ofType: TailComp.self) {
			entity.addComponent(Tailanimate(Jukebox.shared.players[.guitar]!.currentTime))
			tailsystem.addComponent(foundIn: entity)
		}
	}
	
	func tracktails (_ tail: TailComp) {
		// func = timeremaining / lengh -1 * -1
		let time 			= CGFloat(Jukebox.shared.players[.guitar]!.currentTime) * pace.fps + tail.length
		var lapse:CGFloat 	= 0
		tail.node.childNodes[0].geometry?.firstMaterial?.transparent.contentsTransform.m42 = 0.5
		while lapse < 1 {
			let remain = time - ( CGFloat(Jukebox.shared.players[.guitar]!.currentTime) * pace.fps )
			lapse = ((remain / tail.length) - 1) * -1
			tail.node.childNodes[0].geometry?.firstMaterial?.transparent.contentsTransform.m42 = lapse
		}
		tail.node.removeFromParentNode()
	}
	
	func oneup(chord: Chord) {
		for c in chord {
			triggers[c]?.hit()
			scorekeeper.scoreOneUp()
		}
	}
	
	func miss(_ set: Chord) {
//		print("missed", set)
	}
}
