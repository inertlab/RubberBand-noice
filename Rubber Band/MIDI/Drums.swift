//
//  Drums.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/9/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit
import SceneKit

struct SPCount {
	let base:Double
	let bonus:Double
}

/// Drums defers from Strings in that it does not contain duration
//class Drums {
extension MusicSheet {
	/// creates gems out of midi track and places them on highway
	func layDrumTrack(_ stage: DrumStage) {
		
		var activatortimes 	= [CGFloat]()
	
//		let gemmaker 		= GemMaker() // turn this into a singleton
		
		gemmaker.loadgems(type: .drums)
		
		let beats = layBeat()
		
		/// Sorted drum notes from midi sequence
		let drumNotes = getDrumNotes()
		
		var starset		= 0
		var starnotes 	= stage.sp.starnotes
		// if there is no starpower notes, add 1 so it doesn't crash
		if starnotes.count == 0 {
			starnotes.append(([.plus], 0, 0, nil))
		}
		let setcount	= starnotes.count - 1

		var starnote 	= starnotes[starset]
		var lastStar  	= StarNoteComp(0)
		
		var basescore = 0
		var notecount = 0
		var multiplier = 1
		var pts = 30
		
		if User.current.diff != .expert {
			pts = 25
		}

		for note in drumNotes {

			let entity 		= NoteEntity()
			let start		= CGFloat(note.start * pace.fps_d)
			let notecomp	= entity.component(ofType: NoteComp.self)!
			
			notecount += 1
			
			switch notecount {
			case 10:
				multiplier = 2
			case 20:
				multiplier = 3
			case 40:
				multiplier = 4
			default:
				break;
			}
			
			notecomp.node = gemmaker.makegem(button: note.btn)
			notecomp.chord.insert(note.btn)
			notecomp.node.position.z = start
			if note.btn == .plus {
				// this is anx activator button
				let activator 	= ActivatorComp()
				notecomp.chord = [.green, .green_c]
				entity.addComponent(activator)
				activatortimes.append(notecomp.node.position.z)
				stage.activesystem.addComponent(activator)
				notecomp.status = .skip
				notecomp.node.addChildNode(gemmaker.drumtail!.clone())
			} else {
//				the else omits activatorcomps from getting included in starnotes
//				check to see if note is within star range, if it's beyond then start new range if possible
				if note.start < starnote.end {
					if note.start >= starnote.start {
						lastStar = StarNoteComp(starset)
						entity.addComponent(lastStar)
						stage.starsystem.addComponent(foundIn: entity)
					}
				} else {
					lastStar.meta = true
					if starset < setcount {
						starset += 1
						starnote = starnotes[starset]
					}
				}
				basescore += pts * multiplier
			}
			
			stage.notesystem.addComponent(notecomp)
			// if you remove reference to an entity none of the components exist. 
			stage.notes.insert(entity)
			
			stage.hwy.notes.addChildNode(notecomp.node)
		}
		
		print("star power sets = ", starnotes.count)
		
		var hidden = 0
		for time in activatortimes {
			for note in stage.notesystem.components {
				// if it's a kick, we don't hide it. in the future, make and optional state so it doesn't have to be hit
				if note.chord.contains(.orange) {continue}
				if let _ = note.entity?.component(ofType: ActivatorComp.self) {continue}
	
				if note.node.position.z > time - 0.1 && note.node.position.z < time + 0.1  {
					let hide = HiddenComp()
					note.entity?.addComponent(hide)
					stage.hiddensystem.addComponent(hide)
					hidden += 1
				}
			}
		}
		let count = drumNotes.count - stage.activesystem.components.count
		print("allnotes = ", drumNotes.count, " all hidden = ", hidden)
		print("the count is ", count)
		print("the base score is ", basescore)
		stage.scorekeeper.starvalues = Starvalues(sets: starnotes.count, beats: beats, basescore: Double(basescore))
	}
}
