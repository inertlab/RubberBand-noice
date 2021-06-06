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
	
		let gemmaker 		= GemMaker() // turn this into a singleton
		
		let beats = layBeat()
		
		/// Sorted drum notes from midi sequence
		let drumNotes = getDrumNotes()
		
		var starset		= 0
		var starnotes 	= stage.sp.starnotes
		// if there is no starpower notes, add 1 so it doesn't crash
		if starnotes.count == 0 {
			starnotes.append(([.plus], 0, 0))
		}
		let setcount	= starnotes.count - 1

		var starnote 	= starnotes[starset]
		var lastStar  	= StarNoteComp(0)

		for note in drumNotes {
			let entity 		= NoteEntity()
			let start		= CGFloat(note.start * pace.fps_d)
			let notecomp	= entity.component(ofType: NoteComp.self)!
			
			notecomp.node = gemmaker.makegem(controller: note.btn)
			notecomp.chord.insert(note.btn)
			notecomp.node.position.z = start
			
			if note.btn == .plus {
				// this is an activator button
				let activator 	= ActivatorComp()
				notecomp.chord 	= [.green, .green_c]
				entity.addComponent(activator)
				activatortimes.append(notecomp.node.position.z)
				stage.activesystem.addComponent(activator)
				notecomp.status = .skip
				notecomp.node.addChildNode(gems.crash_tail.clone())
			}
			// check to see if note is within star range, if it's beyond then start new range if possible
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
			
			stage.notesystem.addComponent(notecomp)
			// if you remove reference to an entity none of the components exist. 
			stage.notes.insert(entity)
			
			stage.hwy.notes.addChildNode(notecomp.node)
		}
		
		print("star power sets = ", starnotes.count)

		for time in activatortimes {
			for note in stage.notesystem.components {
				// if it's a kick, we don't hide it. in the future, make and optional state so it doesn't have to be hit
				if note.chord.contains(.orange) {continue}
				if let _ = note.entity?.component(ofType: ActivatorComp.self) {continue}
				
				if note.node.position.z > time - 0.1 && note.node.position.z < time + 0.1  {
					let hide = HiddenComp()
					note.entity?.addComponent(hide)
					stage.hiddensystem.addComponent(hide)
				}
			}
		}
		let count = drumNotes.count - stage.activesystem.components.count
		print("allnotes = ", drumNotes.count)
		print("the count is ", count)
		stage.scorekeeper.starvalues = Starvalues(count: count, sets: starnotes.count, beats: beats)
	}
}
