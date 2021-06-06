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

// stars ☆􀋆􀋅

class SelectState: GKState {
	override func didEnter(from previousState: GKState?) {
		print("entering state")
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		return stateClass is ListState.Type
	}
	
	override func willExit(to nextState: GKState) {
		print("exisitng ", self.description)
	}
}

class ListState: GKState {
	override func didEnter(from previousState: GKState?) {
		print("entering list state")
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		return stateClass is SelectState.Type
	}
}


final class SongMenu: Performing {
	
	let machine = GKStateMachine(states: [ListState(), SelectState()])
	
	let octopus: Octopus
	let help = Help()
	
	let score = Scorelabel()
	
	func updatestate() {
		self.state = .details
		updatedetails()
	}
	
	let scn: SCNScene

	enum State {
		case start, select, details, options, relatedsongs, history, help
	}
	

	init(){
		self.octopus = Octopus(arm: SCNScene(named: "art.scnassets/scns/tentacle1.scn")!.rootNode)
		self.scn = menuScene
		
		octopus.updatearms()
		machine.enter(SelectState.self)
	}
	
	var state:State = .select {
		didSet {
			// if nothing changed bail
			if oldValue == state { return }
			if state 	== .help {
				help.showhelp(state: oldValue)
				return
			}
			// hide old stuff
			switch oldValue {
			case .details:
				labeldetails?.removeAllActions()
				labeldetails?.run(Actions.shared.fadeout)
				octopus.leave()
			case .history, .relatedsongs:
				othersongsg?.removeAllActions()
				othersongsg?.run(Actions.shared.fadeout)
			case .select:
				UpNext.shared.hide()
			default:
				break
			}

			// show new shit
			switch state {
			case .start, .options:
				rowcall.state = .off
			case .history:
				rowcall.state = .off
				othersongsg?.run(Actions.shared.fadein)
			case .select:
				rowcall.state = .neutral
				UpNext.shared.show()
			case .relatedsongs:
				rowcall.state = .detail
				othersongsg?.run(Actions.shared.fadein)
			default:
				rowcall.state = .detail
				labeldetails?.run(Actions.shared.fadein)
				octopus.comein()
			}
			rowcall.updatezposition()
		}
	}
	
	func handleevent(_ event: Button) {
		switch state {
		case .select:
			songselect(event)
		case .details:
			detailsoptions(event)
		case .relatedsongs:
			relatedsongoptions(event)
		case .history:
			historyoptions(event)
		case .help:
			state = help.hidehelp()
		default:
			switch event {
			case .left, .right, .down, .up, .blue, .yellow:
				if smanager.selectfirstsong() {
					self.state = .select
					rowcall.posx = 0
					UpNext.shared.refreshlist(nexttitles: smanager.songrange(index: 0))
				}
			default:
				break
			}
			break
		}
	}
	
	func songmenuview () {
		_ = ["st", "fdk"]
		state = .select
		smanager.selected.state = .selected
		UpNext.shared.show()
	}
}

private extension SongMenu {
	// MARK: - event handlers
	
	func songselect (_ event: Button) {
		machine.enter(ListState.self)
		if !smanager.songenties.isEmpty {
			switch event {
			case .minus:
				showhistory()
			case .plus:
				showrecentlyadded()
			case .green, .start:
				updatedetails()
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
				state = .help
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
	func detailsoptions(_ input: Button)  {
		if state == .help {
			state = help.hidehelp()
			return
		}
		switch input {
		case .minus:
			showhistory()
		case .plus:
			showrecentlyadded()
		case .red: // go back to menu
			// if songs are sorted by tier, revert current instrument to previous instrument
			songmenuview()
		case .green, .start:
			if User.current.instrument.gettier() != -1 {
				stagemc.loadstage()
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
			showrelatedsongmenu()
		case .orange :
			state = .help
		default:
			break;
		}
	}
	
	/// event handler for "related song" menu
	/// - Parameter event: Button press
	func relatedsongoptions(_ event: Button) {
		if state == .help {
			state = help.hidehelp()
			return
		}
		switch event {
		case .orange:
			state = .help
		case .blue, .down:
			SongLister.shared.scrollup()
		case .yellow, .up:
			SongLister.shared.scrolldown()
		case .green, .start:
			hiderelatedsongmenu()
			if let song = smanager.songsystem.components.first(
				where: {
					$0.song == SongLister.shared.song
			}){
				smanager.updatesongselection(newsong: song, state: .detailview)
				UpNext.shared.refreshlist(nexttitles: smanager.songrange(index: song.index))
				smanager.frustrumreveal()
				updatedetails()
			}
		default:
			smanager.selected.state = .detailview
			hiderelatedsongmenu()
		}
	}
	
	/// event handler for "Hisotry List" menu
	/// - Parameter event: Button press
	///
	/// this is almost idential to "Related Song List"
	func historyoptions(_ event: Button) {
		if state == .help {
			state = help.hidehelp()
			return
		}
		switch event {
		case .orange:
			state = .help
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
				smanager.frustrumreveal()
			}
			updatedetails()
		default:
			songmenuview()
		}
	}
	
	// MARK: - functions
	
	/// updates and displays details view and sets the states. does not control other view labels
	///
	/// detail view can come from menu view, or other song views
	func updatedetails () {
		smanager.selected.state = .detailview
		state 				= .details
		labelphrase.text 	= smanager.selected.song.phrase
		labelcharter.text 	= smanager.selected.song.charter
		labelyear.text 		= smanager.selected.song.year.description
		labelalbum.text		= smanager.selected.song.trackOf?.name
		labelgenre.text 	= smanager.selected.song.genre
		
		let countlabel = labeldetails?.childNode(withName: "morelabel") as! SKLabelNode
		let morecount =  SongLister.shared.loadreleatedsongs(artistsong: smanager.selected.song)
		if morecount > 1 {
			countlabel.text = "…\(morecount)+"
		} else {
			countlabel.text = ""
		}
	}
	
	/// displays other songs by the same artist if any
	///
	/// this is only accessible from Details, so it's a good place to hide details from here
	func showrelatedsongmenu () {
		// if there are related songs this happens next
		if SongLister.shared.songs.count > 1 {
			Jukebox.shared.stop()
			state = .relatedsongs
			smanager.selected.state = .othersongs
			SongLister.shared.relatedsongs(smanager.selected.song.artist!)
		}
	}
	
	/// displays History List
	///
	/// only shown from menu list
	func showhistory() {
		if User.current.player.stats?.count == 0 { return }
		Jukebox.shared.stop()
		UpNext.shared.hide()
		state = .history
		smanager.selected.state = .notselected
		SongLister.shared.songhistory()
	}
	
	/// displays Recently Added List
	///
	/// only shown from menu list
	func showrecentlyadded() {
		Jukebox.shared.stop()
		UpNext.shared.hide()
		state = .history
		smanager.selected.state = .notselected
		SongLister.shared.recentlyadded()
	}
	
	/// hides the list of other songs by the same artist
	///
	/// always goes into details view so set the view here
	func hiderelatedsongmenu() {
		state = .details
		smanager.selected.cover.runAction(SCNAction.fadeOpacity(to: 1, duration: 0.25))
	}
	
	func displayoptions() {
		state = .options
		let optiondisplay = SKScene(fileNamed: "optionmenu.sks")
		let bg 			= optiondisplay?.childNode(withName: "bg") as! SKSpriteNode
		let snap 		= mainView.snapshot()
		let snapdata 	= snap.tiffRepresentation
		let ciimage 	= CIImage(data: snapdata!)
		let filt 		= CIFilter(
			name: "CIGaussianBlur",
			parameters: [  "inputImage": ciimage!, "inputRadius" : 10]
		)
		
		var image 	= filt?.outputImage!
		let filt2 	= CIFilter(
			name: "CICMYKHalftone",
			parameters: ["inputImage" : image!, "inputWidth": 16, "inputSharpness": 1]
		)
		image 		= filt2?.outputImage!
		let final 	= context.createCGImage(image!, from: ciimage!.extent)
		bg.texture 	= SKTexture(cgImage: final!)
		
		mainView.overlaySKScene 	= optiondisplay
		optiondisplay?.scaleMode 	= .aspectFit
	}
	
	func hideoptions () {
		state 		= .select
		let cam 	= menuScene.rootNode.childNode(withName: "menucam", recursively: true)
		
		mainView.overlaySKScene = menuOverlay
		cam?.camera?.vignettingIntensity 	= 0
		cam?.camera?.colorFringeIntensity 	= 0
		cam?.camera?.saturation 			= 1
	}
}


let frustum = menuScene.rootNode.childNode(withName: "frustum", recursively: false)
fileprivate let context = CIContext()
