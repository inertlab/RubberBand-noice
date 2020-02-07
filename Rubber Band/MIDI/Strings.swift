//
//  BeatDrop.swift
//  RubberBand
//
//  Created by Fernando on 6/12/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit
import SceneKit



extension MusicSheet {
	
	/// creates gems out of midi track and places them on highway
	func layStringTrack() -> Int{

		let gemmaker 	= GemMaker() // turn this into a singleton

		stagemc.track.sp.resetvars() // reset vars from previous track
		
		layBeat()
		
		/// Sorted drum notes from midi sequence
		let guitarnotes = MusicSheet.shared.get5lanenotes()
		
		var starset		= 0
		let starnotes 	= stagemc.track.sp.starnotes
		let setcount	= starnotes.count - 1
		var starnote 	= starnotes[starset]
		var lastStar  	= StarNoteComp(0)

		for chord in guitarnotes {
			
			let entity 		= NoteEntity()
			
			let start		= CGFloat(chord.start * pace.fps_d)
			let notecomp 	= entity.component(ofType: NoteComp.self)!

			notecomp.chord = chord.btns
			notecomp.node.position.z = start
			
			stagemc.track.notesystem.addComponent(notecomp)
			
			for btn in chord.btns {
				let gem = gemmaker.makegem(btn: btn)
				notecomp.node.addChildNode(gem)
			}
			
			//	add tail component
			if chord.end > 0 {
				let end 	= CGFloat(chord.end * pace.fps_d)
				let len 	= end - start
				let tail 	= TailComp(len)
				tail.node.position.z = start
				let diffusescale = len * 0.05
//				print(len, diffusescale)
				for btn in chord.btns {
					let tailnode = gemmaker.givemetail(btn: btn)
//					tailnode.scale.y = len
					tailnode.geometry?.firstMaterial?.diffuse.contentsTransform.m22 = diffusescale
					tailnode.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = -0.9 * diffusescale
					tail.node.addChildNode(tailnode)
				}
				
				stagemc.track.hwy.notes.addChildNode(tail.node)
				entity.addComponent(tail)
				
			}
			// check to see if note is within star range, if it's beyond then start new range if possible
			if chord.start < starnote.end {
//				print("what")
				if chord.start >= starnote.start {
//					print(chord.start, "added ", chord.btns, "in set ", starset)
					lastStar = StarNoteComp(starset)
					entity.addComponent(lastStar)
					stagemc.track.starsystem.addComponent(foundIn: entity)
				}
			} else {
				lastStar.meta = true
				if starset < setcount {
					starset += 1
					starnote = starnotes[starset]
				}
			}
			
			stagemc.track.notes.insert(entity)
			stagemc.track.hwy.notes.addChildNode(notecomp.node)
		}

		print("star power sets = ", starset)
		print("this is my notes" ,stagemc.track.notesystem.components.count)
		
		return guitarnotes.count
	} // end of laytrack
}
