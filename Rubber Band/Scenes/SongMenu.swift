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

	func updatestate() {
		self.state = .details
	}
	
	let scn: SCNScene

	enum State {
		case start, select, details, options, relatedsongs
	}
	
	init(){
		self.scn = menuScene
	}
	
	var state:State = .select
	
	func handleevent(_ event: Button) {
		switch state {
		case .select:
			songselect(event)
		case .details:
			songoptions(event)
		case .relatedsongs:
			relatedsongoptions(event)
		default:
//			hideoptions()
			switch event {
			case .left, .right, .down, .up, .blue, .yellow:
				if smanager.selectfirstsong() {
					self.state = .select
					covernode.runAction(SCNAction.move(to: SCNVector3(0, 0, 0), duration: 0.25))
					UpNext.shared.refreshlist(nexttitles: smanager.songrange(index: 0))
				}
			default:
				break
			}
			break
		}
	}
	
	func backtosongmenu () {
		UpNext.shared.show()
		state = .select
//		let neon = menuScene.rootNode.childNode(withName: "neon", recursively: false)
		labeldetails!.run(Actions.shared.fadeout)
		covernode.runAction(SCNAction.moveBy(x: 0, y: 0, z: 1.25, duration: 0.5))
//		smanager.selected.cover.runAction(SCNAction.moveBy(x: 0, y: 0, z: -1.25, duration: 0.5))
		smanager.selected.state = .selected
//		neon?.runAction(SCNAction.moveBy(x: 0, y: 0, z: -4, duration:0.5))

	}
	
}

private extension SongMenu {
	// MARK: - event handlers
	
	func songselect (_ event: Button) {
		if !smanager.songenties.isEmpty {
			switch event {
			case .minus:
				smanager.reflow(sortedBy: .artist)
			case .green, .start:
				gotodetailview()
			case .plus:
				displayoptions()
			case .select:
				smanager.reflow(sortedBy: .song)
			case .blue_c, .left:
				smanager.moveselect(direction: .left)
			case .green_c, .right:
				smanager.moveselect(direction: .right)
			case .blue, .down:
				smanager.moveselect(direction: .down)
			case .yellow, .up:
				smanager.moveselect(direction: .up)
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
	func songoptions(_ input: Button)  {
		switch input {
		case .red: // go back to menu
			backtosongmenu()
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
		case .left:
			User.current.instrument.previous()
		case .minus:
			scorekeeper.deleteallstats()
		case .yellow_c:
			showrelatedsongmenu()
		default:
//			print(input)
			break;
		}
	}
	
	/// event handler for "related song" menu
	/// - Parameter event: Button press
	func relatedsongoptions(_ event: Button) {
		switch event {
		case .blue, .down:
			RelatedSongs.share.scrollup()
		case .yellow, .up:
			RelatedSongs.share.scrolldown()
//			scrolldown()
		case .green, .start:
			hiderelatedsongmenu()
			if let song = smanager.songsystem.components.first(where: {$0.song == RelatedSongs.share.list[RelatedSongs.share.index]}){
				smanager.updatesongselection(newsong: song, state: .detailview)
				UpNext.shared.refreshlist(nexttitles: smanager.songrange(index: song.index))
				let covers = mainView.nodesInsideFrustum(of: frustum!)
				smanager.revealcoverart(covers: covers)
			}
		default:
			smanager.selected.state = .detailview
			hiderelatedsongmenu()
		}
	}
	
	// MARK: - functions
	
	/// scroll song list up
	func scrollup() {
		//scroll up
		print("scrolling up")
	}
	
	/// scroll song list down
	func scrolldown() {
		//scroll down
		print("scrolling down")
	}
	
	func gotodetailview () {
		UpNext.shared.hide()
		state 				= .details
		labelphrase.text 	= smanager.selected.song.phrase
		labelcharter.text 	= smanager.selected.song.charter
		labelyear.text 		= smanager.selected.song.year.description
		labelalbum.text		= smanager.selected.song.trackOf?.name
		labelgenre.text 	= smanager.selected.song.genre
//		let neon = menuScene.rootNode.childNode(withName: "neon", recursively: false)
		labeldetails!.run(Actions.shared.fadein)
		covernode.runAction(SCNAction.moveBy(x: 0, y: 0, z: -1.25, duration: 0.5))
		smanager.selected.state = .detailview
		
		let countlabel = labeldetails?.childNode(withName: "morelabel") as! SKLabelNode
		let morecount = RelatedSongs.share.loadlist(artistsong: smanager.selected.song)
		if morecount > 1 {
			countlabel.text = "…\(morecount)+"
		} else {
			countlabel.text = ""
		}
	}
	
	
	/// displays other songs by the same artist if any
	func showrelatedsongmenu () {
		// if there are related songs this happens next
		if RelatedSongs.share.list.count > 1 {
			Jukebox.shared.stop()
			state = .relatedsongs
			smanager.selected.state = .othersongs
			labeldetails!.removeAllActions()
			labeldetails!.run(SKAction.fadeOut(withDuration: 0.35))
			othersongsg?.run(SKAction.fadeIn(withDuration: 0.75))
			RelatedSongs.share.makesonglist(artist: smanager.selected.song.artist!)
		}
	}
	
	/// hides the list of other songs by the same artist
	func hiderelatedsongmenu () {
		smanager.selected.cover.runAction(SCNAction.fadeOpacity(to: 1, duration: 0.25))
		state = .details
		othersongsg?.run(SKAction.fadeOut(withDuration: 0.4))
		
		labeldetails!.run(SKAction.fadeIn(withDuration: 0.5))
	}
	
	
	func displayoptions () {
		state = .options
		let optiondisplay = SKScene(fileNamed: "optionmenu.sks")
		let bg 			= optiondisplay?.childNode(withName: "bg") as! SKSpriteNode
		let snap 		= mainView.snapshot()
		let snapdata 	= snap.tiffRepresentation
		let ciimage 	= CIImage(data: snapdata!)
		let filt 		= CIFilter(name: "CIGaussianBlur", parameters: [  "inputImage": ciimage!, "inputRadius" : 10])
		
		var image 	= filt?.outputImage!
		let filt2 	= CIFilter(name: "CICMYKHalftone", parameters: ["inputImage" : image!, "inputWidth": 16, "inputSharpness": 1])
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

fileprivate let context = CIContext()
