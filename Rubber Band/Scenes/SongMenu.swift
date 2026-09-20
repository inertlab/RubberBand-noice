//
//  SongMenu.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/14/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit
import CoreImage
import GameplayKit


final class SongMenu: Performing {
	
//	menu labels
	
	let octopus: Octopus
	let help = Help()
	
//	let score = Scorelabel()
	
	let scn: SCNScene
	var screen = Screen.menu
	
	enum Screen {
		case detail, menu
	}

	enum State {
		case start, select, details, options, relatedsongs, history, help
	}
	let sound = SCNAudioSource(fileNamed: "sounds/rewind_01.m4a")!
	
	init(){
		sound.volume = 20
		sound.isPositional = false
		sound.load()
		octopus = Octopus(arm: SCNScene(named: "art.scnassets/scns/tentacle1.scn")!.rootNode)
		scn = menuScene
		octopus.updatearms()
	}
	
	var state:State = .select
	
	
	func handleevent(_ event: Button) {
		switch stagemc.machine.currentState {
		case is MenuState:
			menuevents(event)
		case is HelpState:
			switch HelpState.previous {
			case is MenuState:
				stagemc.machine.enter(MenuState.self)
			case is DetailState:
				stagemc.machine.enter(DetailState.self)
			case is RelatedState:
				stagemc.machine.enter(RelatedState.self)
			case is AddedState:
				stagemc.machine.enter(AddedState.self)
			default:
				stagemc.machine.enter(HistoryState.self)
			}
		case is DetailState:
			detailevents(event)
		case is HistoryState, is AddedState, is RelatedState:
			historyevents(event)
		default:
			if smanager.selectfirstsong() {
				rowcall.state = .menu
				stagemc.machine.enter(MenuState.self)
				rowcall.posx = 0
				UpNext.shared.refreshlist(nexttitles: smanager.songrange(index: 0))
			}
		}
	}
}

private extension SongMenu {
	// MARK: - event handlers
	
	func menuevents (_ event: Button) {
		if !smanager.songenties.isEmpty {
			switch event {
			case .minus:
				stagemc.machine.enter(HistoryState.self)
			case .plus:
				stagemc.machine.enter(AddedState.self)
			case .green, .start:
				stagemc.machine.enter(DetailState.self)
			case .select:
				smanager.reflow(sortedBy: .song)
			case .blue_c, .left:
				smanager.moveselector(direction: .left)
			case .green_c, .right:
				smanager.moveselector(direction: .right)
			case .blue, .down:
				smanager.moveselector(direction: .down)
			case .yellow, .up:
				smanager.moveselector(direction: .up)
			case .orange:
				stagemc.machine.enter(HelpState.self)
			default:
				break;
			}
		} else {
			if event == .start {
				smanager.deleteCatalog()
				let sfinder = SongFinder()
				sfinder.catalogSongs()
				smanager.coverflow()
			}
		}
	}
	
	/// Active when the details screen is displayed for a song
	/// - Parameter input: The button input - this changes with instrument, kida messy.
	func detailevents(_ input: Button)  {
		switch input {
		case .minus:
			stagemc.machine.enter(HistoryState.self)
		case .plus:
			stagemc.machine.enter(AddedState.self)
		case .red: // go back to menu
			stagemc.machine.enter(MenuState.self)
		case .green, .start:
			if User.current.instrument.gettier() != -1 {
				stagemc.machine.enter(PlayState.self)
				print("done")
			} else {
				print("no can do buckaroo")
			}
		case .up, .yellow:
			User.current.diff.next()
		case .down, .blue:
			User.current.diff.previous()
		case .right:
			User.current.instrument.next()
			octopus.updatearms()
		case .left:
			User.current.instrument.previous()
			octopus.updatearms()
		case .yellow_c:
			if SongLister.shared.ready {
				stagemc.machine.enter(RelatedState.self)
			}
		case .orange :
			stagemc.machine.enter(HelpState.self)
		default:
			break;
		}
	}

	/// event handler for "History List" menu
	/// - Parameter event: Button press
	///
	/// this is almost idential to "Related Song List"
	func historyevents(_ event: Button) {
		switch event {
		case .orange:
			stagemc.machine.enter(HelpState.self)
		case .blue, .down:
			SongLister.shared.scrollup()
		case .yellow, .up:
			SongLister.shared.scrolldown()
		case .green, .start:
			if let song = smanager.songsystem.components.first(
				where: {
					$0.song == SongLister.shared.song
			}){
				smanager.updatesongselection(newsong: song, state: .detailview)
				UpNext.shared.refreshlist(nexttitles: smanager.songrange(index: song.index))
				smanager.frustrumreveal(after: 0.25)
			}
			stagemc.machine.enter(DetailState.self)
		default:
			// i need to find out the previous state of the machine
			if ListState.screen == .detail {
				stagemc.machine.enter(DetailState.self)
				return
			}
			stagemc.machine.enter(MenuState.self)
		}
	}
}


let frustum = menuScene.rootNode.childNode(withName: "frustum", recursively: false)
