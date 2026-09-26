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
	let backdrop: Backdrop = Pentapuss()
	let scorekeeper = ScoreKeeper()
	
	var tailsystem = GKComponentSystemCGF(componentClass: Tailanimate.self)
	var starsystem: GKComponentSystem<StarNoteComp>
	var notesystem: GKComponentSystem<NoteComp>
	var notes = Set<GKEntity>()

	var sp: StarPower
	
	let scn: SCNScene
	let hwy: HWY
	let triggers:[Button: StringTrigger]
	var hand: Chord = []
	
	var state: Songstate = .playing
	var power = 2

	var songtrack: Jukebox.Track = .guitar

	init() {
		self.notesystem = GKComponentSystem(componentClass: NoteComp.self)
		self.starsystem	= GKComponentSystem(componentClass: StarNoteComp.self)
		self.scn = SCNScene(named: "art.scnassets/scns/strings.scn")!
		self.hwy = HWY(self.scn)
		self.triggers = [
			Button.red		: StringTrigger(note: .red, 	hwy: self.hwy),
			Button.blue		: StringTrigger(note: .blue, 	hwy: self.hwy),
			Button.green	: StringTrigger(note: .green,	hwy: self.hwy),
			Button.orange	: StringTrigger(note: .orange, 	hwy: self.hwy),
			Button.yellow	: StringTrigger(note: .yellow, 	hwy: self.hwy),
		]
		self.sp = StarPower(self.hwy)

		if User.current.instrument == .bass {
			self.power = 4
			self.songtrack = .rhythm
		}
		startparticle()
	}
	
	func handleevent(_ event: Button) {
		switch stagemc.machine.currentState {
		case is PlayState:
			switch event {
			case .strum, .up, .down:
				if hand.isEmpty {
					allmissed()
				} else {
//					inhere write logic for when hand is empty
					notecheck()
				}
			case .left, .right:
				sp.activateSP(hwy.pista.position.z)
			case .green, .red, .yellow, .blue, .orange:
				hand.insert(event)
				triggers[event]?.fretted()
				
				for case let tail as Tailanimate in tailsystem.components {
					tail.keydown(event)
				}
			case .start:
				stagemc.machine.enter(ScoreState.self)
			case .plus:
				stagemc.machine.enter(PausedState.self)
			default:
				break
			}
		case is PausedState:
			stagemc.machine.enter(RewindState.self)
		case is ScoreState:
//			this events don't use the strum bar - maybe change it?
//			??? why is this orange?
			switch event {
			case .left, .right:
				smanager.makerandomnextselected()
			case .down, .up:
				smanager.refreshnext()
			case .orange:
//				play random song by previously played artist
				smanager.selectrandom(true)
				stagemc.machine.enter(PlayState.self)
			case .blue:
				// play random song
				smanager.selectrandom()
				fallthrough
			case .yellow:
//				replay current song
				stagemc.machine.enter(PlayState.self)
			default:
				stagemc.machine.enter(DetailState.self)
			}
		default:
			break
		}
	}
	
	func handlekeyup(_ event: Button) {
		hand.remove(event)
		triggers[event]?.open()
		
		for case let tail as Tailanimate in tailsystem.components {
			tail.keyup(event)
		}
	}
	
	func laytrack() {
		MusicSheet.shared.layStringTrack()
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
	
//	MARK: Note Checking/Tracking
	func trackdeadnotes(hwytime: CGFloat) {
		if notesystem.components.isEmpty { return }
		
		if let note = notesystem.components.first {
			
			if note.node.position.z < hwytime - pace.hitwindow {
				
				if note.status == .live {
					if let tail = note.entity?.component(ofType: TailComp.self){
						tail.maketailgray()
					}
					
					starmissed(note)
					miss()
					
					scorekeeper.deadnote()
					notes.remove(note.entity!)
				} else {
					// if entity contains a tailcomp, it will not removeit from the notesystem, if not it will remove it from notes.
					if let _ = note.entity?.component(ofType: TailComp.self) {
						notesystem.removeComponent(note)
					} else {
//						if note.entity is removed, all components get removed including tails and they won't animate
						notes.remove(note.entity!)
					}
				}
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
					// if there is only one note, more than one fret can be pressed
					if note.chord.count == 1 {
						let first = hand.sorted {$0.rawValue > $1.rawValue}.first
						if first == note.chord.first {
							
							notecheck(note: note)
//							unlike drums, do not mark note for removal or else the tail gets removed too
							break
						}
						// this is if there are multiple notes or chord
					} else {
						if hand == note.chord {
							
							notecheck(note: note)
							
							break
						}
					}
				} else {
					// once a note is found outside the box we exit, all notes inside the hitbox have been checked
					// this might cause a bug when no more notes are found at end of song
					miss(chord: hand)
					for case let tail as Tailanimate in tailsystem.components {
						tail.keydown(.yellow_c)
					}
					scorekeeper.scoreMiss()
					break
				}
				// this is the only time a miss is registered
				starmissed(note)
				miss(chord: note.chord)
				scorekeeper.scoreMiss()
			}
		}
	}
	
	func notecheck(note: NoteComp) {
		
		oneup(chord: note.chord)
		// check to see if entity has a tail if it does, start tail animation
		checktail(note)
		
		//	checks if a starrun has been completed
		if checkpowerchain2(note) {
			sp.starruncompleted()
		}
		
		note.node.removeFromParentNode()
	}
	
	/// Checks to see if component has a tail, if it does, Tailanimate component
	/// - Parameter entity: NoteEntity
	///
	/// See Tailanimate.update() for further instructions
	func checktail (_ note: NoteComp) {
		if let entidy = note.entity {
			if let _ = entidy.component(ofType: TailComp.self) {
				let tail = Tailanimate()
//				this works!!!
				tail.delegate = self
				tail.scoredel = scorekeeper
				entidy.addComponent(tail)
				tailsystem.addComponent(foundIn: entidy)

				for c in note.chord {
					triggers[c]?.burn()
				}
			}
		}
	}
	
	/// deprecated - do not use?
	func tracktails (_ tail: TailComp) {
		let time = CGFloat(Jukebox.shared.currenttime() ?? 0) * pace.fps + tail.length
		var lapse:CGFloat = 0
		tail.node.childNodes[0].geometry?.firstMaterial?.transparent.contentsTransform.m42 = 0.5
		while lapse < 1 {
			let remain = time - (CGFloat(Jukebox.shared.currenttime() ?? 0) * pace.fps)
			lapse = ((remain / tail.length) - 1) * -1
			tail.node.childNodes[0].geometry?.firstMaterial?.transparent.contentsTransform.m42 = lapse
		}
		tail.node.removeFromParentNode()
	}
	
	func oneup(chord: Chord) {
		scorekeeper.comboup()
		for c in chord {
			triggers[c]?.hit()
			scorekeeper.scoreOneUp()
		}
	}
	
	func miss(chord: Chord = []) {
		for c in chord {
			triggers[c]?.miss()
		}
	}
	
	/// this is all wrong
	func allmissed() {
		for t in triggers {
			t.value.miss()
		}
	}
}


extension GuitarStage: TriggerDelegate {
	func tailended() {
		for t in triggers {
			t.value.node.removeAllParticleSystems()
		}
	}
}
