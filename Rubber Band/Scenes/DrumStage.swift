//
//  DrumStage.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/14/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit


final class DrumStage: Performing, Track {
	
	let backdrop:Backdrop = Pentapuss()
	
	let scorekeeper = ScoreKeeper()

	// MARK: - ECS
	var notes = Set<GKEntity>()
	var notesystem: GKComponentSystem<NoteComp>
	var tailsystem = GKComponentSystemCGF(componentClass: Tailanimate.self)
	var starsystem: GKComponentSystem<StarNoteComp> // not used here
	var activesystem = GKComponentSystem<ActivatorComp>(componentClass: ActivatorComp.self)
	var hidewithsp = Set<GKEntity>()
	var hiddensystem = GKComponentSystem<HiddenComp>(componentClass: HiddenComp.self)
	
	// MARK: - Vars
	// deprecated - use statemachine instead
	var state: Songstate = .playing
	let scn = SCNScene(named: "art.scnassets/scns/highway.scn")!
	let hwy: HWY
	let sp: StarPower
	var triggers: [Button: DrumTrigger]
	var songtrack: Jukebox.Track = .drums
	var deadindex = 0

	init() {
		self.notesystem = GKComponentSystem(componentClass: NoteComp.self)
		self.starsystem = GKComponentSystem(componentClass: StarNoteComp.self)
		self.hwy = HWY(self.scn)
		self.triggers = [
			.blue 	: DrumTrigger(btn: .blue, 	hwy: hwy),
			.green 	: DrumTrigger(btn: .green, 	hwy: hwy),
			.red	: DrumTrigger(btn: .red, 	hwy: hwy),
			.yellow : DrumTrigger(btn: .yellow, hwy: hwy),
			.orange	: DrumTrigger(btn: .orange, hwy: hwy)
		]
		self.sp = StarPower(self.hwy)
		startparticle()
	}
	
	//MARK: - Event Handler
	func handleevent(_ event: Button) {
		switch stagemc.machine.currentState {
		case is PlayState:
			switch event {
			case  .blue_c, .blue, .green, .green_c, .orange, .red, .yellow, .yellow_c:
				notecheck(event)
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
			switch event {
			case .yellow_c:
				smanager.makerandomnextselected()
			case .yellow:
//				refresh up next
//				to do: seperate functions into 2 seperate cases
				smanager.refreshnext()
			case .green_c:
//				play random song by previous Artist
				smanager.selectrandom(true)
				stagemc.machine.enter(PlayState.self)
			case .blue:
				// play random song
				smanager.selectrandom()
				fallthrough
			case .blue_c:
//				repeats song
				stagemc.machine.enter(PlayState.self)
			default:
				stagemc.machine.enter(DetailState.self)
			}
		default:
			return
		}
	}
	
	
	//MARK: - Functions, public
	func laytrack() {
		MusicSheet.shared.layDrumTrack(self)
		print(notesystem.components.count)
	}
	
	/// hides notes that overlap activator notes and shows activators
	func showsp() {
		let limit = hwy.pista.position.z + pace.fps
		for activator in activesystem.components {
			activator.show(limit)
		}
		for hide in hiddensystem.components{
			hide.hide(limit)
		}
	}
	
	/// shows notes that overlap activator notes and shows activators
	func hidesp() {
		let limit = hwy.pista.position.z + pace.fps
		for activator in activesystem.components {
			activator.hide(limit)
		}
		for hide in self.hiddensystem.components {
			hide.show(limit)
		}
	}
	
	/// Checks and removes the first note in notesystem per frame
	/// - Parameter hwytime: The song time in HWY units
	/// - Note: Nothing gets removed, only note.status gets updated
	/// - checknote() hides Hit notes
	func trackdeadnotes(hwytime: CGFloat) {
		
		for i in deadindex..<notesystem.components.count {
			let note = notesystem.components[i]

			if note.node.position.z < hwytime - pace.hitwindow {
				deadindex += 1
				if note.status == .live {
					note.status = .remove
					if sp.state == .ready {
						if note.chord == [.green_c, .green] {
							continue
						}
					}
					starmissed(note)
					scorekeeper.deadnote()
				}
			} else {
				return
			}
		}
	}
	
	func robot(hwytime: CGFloat) {
		if notesystem.components.isEmpty { return }
		
		if deadindex == notesystem.components.count - 1 {return}
		
		for i in deadindex..<notesystem.components.count {
			let note = notesystem.components[i]
			if note.node.position.z <= hwytime {
			if note.status != .live {continue}
			notecheck(note.chord.first!)
			} else {
				return
			}
		}
	}
}

//MARK: - Private
private extension DrumStage {
	
	/// Checks to see if triggered note matches the entities
	/// - Parameter btn: button press on keyboard or game controller or instrument
	///
	/// This is different from Strings in that we have to check the first four NoteEntities not just the first
	func notecheck(_ btn : Button) {
		
		for i in deadindex..<notesystem.components.count{
			let note = notesystem.components[i]

			if note.status == .live {
				if note.node.position.z < hwy.pista.position.z + pace.hitwindow {
					if note.chord.contains(btn) {
						note.status = .remove
//						[.green, .green_c] is the starpower trigger
						if note.chord == [.green, .green_c] {
							sp.activateSP(note.node.position.z)
							hidesp()
						}

						oneup(btn)
						
//						checks if a starrun has been completed
						if checkpowerchain2(note) {
							sp.starruncompleted()
							if sp.state == .ready {
								showsp()
							}
						}
						note.node.isHidden = true
						break
					}
				} else {
					if sp.segment {
						sp.segment = false
						starmissed(note)
					}
					miss(btn)
					break
				}
			}
		}
	}
	
	func oneup(_ btn: Button) {
		scorekeeper.comboup()
		scorekeeper.scoreOneUp()
		switch btn {
		case .blue_c:
			triggers[.blue]?.hit()
		case .green_c:
			triggers[.green]?.hit()
		case .yellow_c:
			triggers[.yellow]?.hit()
		default:
			triggers[btn]?.hit()
		}
	}
	
	func miss(_ btn: Button) {
		scorekeeper.scoreMiss()
		switch btn {
		case .blue_c:
			triggers[.blue]?.miss()
		case .green_c:
			triggers[.green]?.miss()
		case .yellow_c:
			triggers[.yellow]?.miss()
		default:
			triggers[btn]?.miss()
		}
	}
	
	func resumegame (_ input: Button){
		switch input {
		case .green:
			stagemc.machine.enter(RewindState.self)
		default:
			break;
		}
	}
}
