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
	var notes   		= Set<GKEntity>()
	var notesystem		: GKComponentSystem<NoteComp>
	var tailsystem 		= GKComponentSystemCGF(componentClass: Tailanimate.self)
	var starsystem		: GKComponentSystem<StarNoteComp> // not used here
	var activesystem 	= GKComponentSystem<ActivatorComp>(componentClass: ActivatorComp.self)
	var hidewithsp 		= Set<GKEntity>()
	var hiddensystem 	= GKComponentSystem<HiddenComp>(componentClass: HiddenComp.self)
	
	// MARK: - Vars
	// deprecated - use statemachine instead
	var state:Songstate = .playing
	let scn 		= SCNScene(named: "art.scnassets/scns/highway.scn")!
	let hwy			: HWY
	let sp			: StarPower
	var triggers 	: [Button: DrumTrigger]
	var songtrack: Jukebox.Track = .drums

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
			case .blue:
				smanager.selected.getcolumn().unhilight()
				smanager.selectrandom(smanager.selected.song.artist!)
				stagemc.machine.enter(PlayState.self)
				stagemc.loadsong()
			case .green_c:
				// play random song
				smanager.selected.getcolumn().unhilight()
				smanager.selectrandom()
				print("playing random")
				fallthrough
			case .blue_c:
				stagemc.machine.enter(PlayState.self)
				stagemc.loadsong()
			default:
				stagemc.machine.enter(DetailState.self)
				stagemc.loadmenu()
			}
		default:
			return
		}
	}
	
	func tracker(_ cgsongtime: CGFloat, _ hwytime: CGFloat) {
		hwy.asphalt.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = cgsongtime * pace.asphalt
		
		hwy.pista.position.z = hwytime
		
		sp.trackpower(time: hwytime)
		trackdeadnotes(hwytime: hwytime)
	}
	
	//MARK: - Functions, public
	func laytrack() {
		MusicSheet.shared.layDrumTrack(self)
	}
	
	/// hides notes that overlap activator notes and shows activators
	func showsp () {
		let limit = hwy.pista.position.z + pace.fps
		for activator in activesystem.components {
			activator.show(limit)
		}
		for hide in hiddensystem.components{
			hide.hide(limit)
		}
	}
	
	/// shows notes that overlap activator notes and shows activators
	func hidesp () {
		let limit = hwy.pista.position.z + pace.fps
		for activator in activesystem.components {
			activator.hide(limit)
		}
		for hide in self.hiddensystem.components {
			hide.show(limit)
		}
	}	
}

//MARK: - Private
private extension DrumStage {

	/// Checks and removes the first note in notesystem per frame
	/// - Parameter hwytime: The song time in HWY units
	///
	/// This only removes one note per frame which might affect accuracy, might need to change it to 3 notes per frame
	///
	/// Also, when an entity is removed, the scnnode is not removed. cycle though scnnodes to remove dead notes
	func trackdeadnotes(hwytime: CGFloat) {
		if notesystem.components.isEmpty { return }
		let note = notesystem.components[0]
		
		if note.node.position.z < hwytime - pace.hitwindow {
			if note.status == .live {
				if sp.state == .ready {
					if note.chord == [.green_c, .green] {
						notes.remove(note.entity!)
						return
					}
				}
				starmissed(note)
				scorekeeper.deadnote()
				Jukebox.shared.muteinstrument(track: .drums)
			}
			// removing entity from one set will not remove the entity completely - DUH!
			notes.remove(note.entity!)
		}
	}

	/// Checks to see if triggered note matches the entities
	/// - Parameter btn: button press on keyboard or game controller or instrument
	///
	/// This is different from Strings in that we have to check the first four NoteEntities not just the first
	func notecheck(_ btn : Button) {

		let max = hwy.pista.position.z + pace.hitwindow
		var checkcount = 0
		
		for note in notesystem.components {
			if note.status == .live {
				checkcount += 1
				if note.node.position.z < max {
					if note.chord.contains(btn) {
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

						note.node.removeFromParentNode()
						note.status = .remove
						break
					}
					if checkcount > 5 { break }
					continue
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
		Jukebox.shared.unmuteinstrument(track: .drums)
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
		Jukebox.shared.muteinstrument(track: .drums)
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
