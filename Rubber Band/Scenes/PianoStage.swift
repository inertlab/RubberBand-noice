//
//  PianoStage.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/30/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//


// this is not used yet?

import Foundation
import GameplayKit


final class PianoStage: Performing, Track, KeyUp {
	let backdrop:Backdrop = Pentapuss()
	let scorekeeper = ScoreKeeper()

	var tailsystem 	= GKComponentSystemCGF(componentClass: Tailanimate.self)
	var starsystem	: GKComponentSystem<StarNoteComp>
	var notesystem	: GKComponentSystem<NoteComp>
	var notes 		= Set<GKEntity>()
	
	var sp: StarPower
	
	let scn: SCNScene
	let hwy: HWY
	let triggers:[Button: StringTrigger]
	var chords 		= [GKEntity]()
	var hand:Chord 	= []

	var state:Songstate = .playing
	
	init() {
		print("piano and shit")
		self.notesystem = GKComponentSystem(componentClass: NoteComp.self)
		self.starsystem	= GKComponentSystem(componentClass: StarNoteComp.self)
		self.scn = SCNScene(named: "art.scnassets/scns/strings.scn")!
		self.hwy = HWY(self.scn)
		self.triggers = [
			Button.red: 	StringTrigger(note: .red, 	hwy: self.hwy)	,
			Button.blue: 	StringTrigger(note: .blue, 	hwy: self.hwy)	,
			Button.green: 	StringTrigger(note: .green,	hwy: self.hwy)	,
			Button.orange: StringTrigger(note: .orange, hwy: self.hwy)	,
			Button.yellow: StringTrigger(note: .yellow, hwy: self.hwy)	,
		]
		self.sp = StarPower(self.hwy)
		startparticle()
	}
	
	
	func handleevent(_ event: Button) {
		
		if state == .playing {
			switch event {
			case .green, .red, .yellow, .blue, .orange:
				hand.insert(event)
				triggers[event]?.fretted()
			case .start:
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
	}
	
	func laytrack(){
		MusicSheet.shared.layStringTrack()
	}
	
	deinit {
//		deinitshit()
	}
}


private extension PianoStage {
	
	func notecheck() {
		
		let max = hwy.pista.position.z + pace.hitwindow
		
		for entity in self.chords {
			if let comp = entity.component(ofType: NoteComp.self) {
				
				// node is dead and of no use
				if comp.node.categoryBitMask == GemBit.dead {
					continue
				}
				// this is the node to check
				if comp.node.position.z < max {
					
					if comp.chord.count == 1 {
						let first = hand.sorted {$0.rawValue > $1.rawValue}.first
						if first == comp.chord.first {
							oneup(chord: comp.chord)
							comp.node.opacity = 0
							comp.node.categoryBitMask = GemBit.dead
						} else {
							miss(comp.chord)
						}
					} else {
						if hand == comp.chord {
							oneup(chord: comp.chord)
							comp.node.opacity = 0
							comp.node.categoryBitMask = GemBit.dead
						} else {
							miss(comp.chord)
						}
					}
					break
				}
			}
		}
	}
	
	func oneup(chord: Chord) {
		scorekeeper.comboup()
		for c in chord {
			triggers[c]?.hit()
			scorekeeper.scoreOneUp()
		}
		Jukebox.shared.unmuteinstrument(track: .keys)
	}
	
	func miss(_ set: Chord) {
		Jukebox.shared.muteinstrument(track: .keys)
		print("silencing keys")
		print("nothing pressed", set)
	}
}

