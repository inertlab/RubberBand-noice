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
	var state:Songstate = .playing
	let scn 			= SCNScene(named: "art.scnassets/scns/highway.scn")!
	let hwy				:HWY
	let sp				:StarPower

	var triggers 		: [Button: DrumTrigger]

	init() {
		self.notesystem = GKComponentSystem(componentClass: NoteComp.self)
		self.starsystem	= GKComponentSystem(componentClass: StarNoteComp.self)
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
		switch state  {
		case .playing:
			switch event {
			case  .blue_c, .blue, .green, .green_c, .orange, .red, .yellow, .yellow_c:
				notecheck(event)
			case .start:
				showstats()
			case .plus:
				Jukebox.shared.pauseMusic()
				state = .paused
			default:
				break
			}
		case .paused:
			state = .playing
			resumegame(event)
		case .stats:
			if event == .green_c {
				// play random song
				stagemc.onstage = .songmenu
				smanager.selectrandom()
				stagemc.loadstage()
				print("playing random")
				break
			}
			if event == .blue_c {
				// play song again
				stagemc.onstage = .songmenu
				stagemc.loadstage()
				break
			}
			stagemc.loadstage()
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
	
	func showsp () {
		activatorsOn(true)
		for hide in hiddensystem.components{
			hide.hide()
		}
	}
	
	func hidesp () {
		DispatchQueue.main.asyncAfter(deadline: .now() + 1 ){
			self.activatorsOn(false)
			
			for hide in self.hiddensystem.components {
				hide.show()
			}
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
				starmissed(note.entity!)
				scorekeeper.scoreMiss()
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
//		checking = true
		let max = hwy.pista.position.z + pace.hitwindow
		
		var checkcount = 0
		
		for note in notesystem.components {
			if note.status == .live {
				checkcount += 1
				if note.node.position.z < max {
					if note.chord.contains(btn) {
						
						if note.chord == [.green, .green_c] {
							sp.activetime = note.node.position.z
							sp.activateSP(2)
							hidesp()
						}
						
						oneup(btn)
						
						if let ent = note.entity {
							
							if starhit(ent) {
								showsp()
							}
						}
						
						note.node.removeFromParentNode()
						note.status = .remove
						break
					}
					if checkcount > 6 { break }
					continue
				} else {
					starmissed(note.entity!)
					miss(btn)
					break
				}
			}
		}
	}
	
	func oneup(_ btn: Button) {
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
	
	func activatorsOn (_ on: Bool) {
		for activator in activesystem.components {
			activator.on = on
		}
	}
	
	func resumegame (_ input: Button){
		switch input {
		case .green:
			OggNo.sharedInstance.resumePlay()
			state = .playing
		default:
			break;
		}
	}
}
