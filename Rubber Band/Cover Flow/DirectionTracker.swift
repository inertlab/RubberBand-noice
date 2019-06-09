//
//  DirectionTracker.swift
//  RubberBand
//
//  Created by Fernando Zamora on 8/5/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit

/// Directions the player press to navigate menu
///
/// - left: player pressed left
/// - right: player pressed right
/// - up: player pressed up
/// - down: player pressed down
enum Direction {
	case left, right, up, down
}

//var timer:Timer?
/// current cover selection (column number, [row, number of rows])
var coverindex = (Int(0), Array(repeating: 0, count: smanager.columns.count))

/// When player moves menu selection this updates menu animations and coverindex
///
/// - Parameter d: direction the player pressed, enum:Direction
func trackDirection (d: Direction) {

	/// currently selected column
	var column = smanager.columns[coverindex.0]
	
	switch d {
	case .left:
		resetcovers()
		if coverindex.0 > 0 {
			coverindex.0 			-= 1
			column 					= smanager.columns[coverindex.0]
			covernode.runAction(slideleft)
		}else{
			coverindex.0 			= smanager.columns.count - 1
			column 					= smanager.columns[coverindex.0]
			covernode.position.x 	= -CGFloat(coverindex.0)
		}
		animatecover (column: column)
	case .right:
		resetcovers()
		if coverindex.0 < smanager.cols {
			coverindex.0 			+= 1
			column 					= smanager.columns[coverindex.0]
			covernode.runAction (slideright)
		}else{
			coverindex.0 			= 0
			column 					= smanager.columns[coverindex.0]
			covernode.position.x 	= -CGFloat(coverindex.0)
		}
		animatecover (column: column)
	case .up:
		if coverindex.1[coverindex.0] > 0 {
			column.runAction(slidedown)
			coverindex.1[coverindex.0] -= 1
			animatecover (column: column)
		}else{
			// this only sets the position of the cover
			if coverindex.0 > 0 {
				let i 			= coverindex.0 - 1
				let col 		= smanager.columns[i]		// col is the destination col
				col.position.y 	= -(col.childNodes.last?.position.y)!
				coverindex.1[i] = col.childNodes.count - 1	//set the las cover on the column
			}else{
				let col 		= smanager.columns.last!
				col.position.y 	= -(col.childNodes.last?.position.y)!
				coverindex.1[smanager.columns.count - 1] = col.childNodes.count - 1
			}
			trackDirection(d: .left)						// this will change and track position of the column
		}
	case .down:
		if coverindex.1[coverindex.0] < column.childNodes.count - 1 {
			coverindex.1[coverindex.0] += 1
			column.runAction(slideup)
			animatecover (column: column)
		}else{
			if coverindex.0 < smanager.cols {
				let i							= coverindex.0 + 1
				coverindex.1[i]					= 0
				smanager.columns[i].position.y	= 0
			}else{
				smanager.columns[0].position.y 	= 0
				coverindex.1[0] 				= 0
			}
			trackDirection(d: .right)
		}
	}
}

/// resets covers to the correct position before applying new animations
fileprivate func resetcovers () {
	covernode.removeAllActions()
	covernode.position.x = -CGFloat(coverindex.0)
}

/// the previously selected cover
var lastnode 	= SCNNode()
var record 		= menuScene.rootNode.childNode(withName: "record", recursively: false)
var label 		= record?.childNode(withName: "label", recursively: false)

func animatecover (column: SCNNode) {
	
	Jukebox.shared.stop()

	let cover = column.childNodes[coverindex.1[coverindex.0]] as! CoverArt
	record?.removeAllActions()
	record?.position.x = 0
	record?.rotation.z = 1
	record?.rotation.w = 1.5
	cover.addChildNode(record!)
	cover.addChildNode(menutext.detailnode!)

	if let stat = smanager.sorted.first(where: {$0.songid == cover.id}) {
		selectedStat = stat
	} else {
		selectedStat =  smanager.fetchStatByID(id: cover.id.uuidString)
	}

	selectedSong = selectedStat.song!
	
	
	
	TextureMover.shared.changeStars(selectedStat.prodrums?.stars ?? 0)
	print(selectedStat.prodrums?.stars)
	TextureMover.shared.changeDifficulty(diff: selectedSong.tier?.drums ?? 0, node: label!)
//	label?.geometry?.firstMaterial?.diffuse.contents = iconAtlas.textureNamed(selectedSong.icon!)
	
	record?.runAction(slideout)
	record?.runAction(spinrecord)
	
	labela.text = selectedSong.artist
	labeln.text = selectedSong.title
	let texture = iconAtlas.textureNamed(selectedSong.icon ?? "blank")
	
	labelicon.texture = texture
	
	
	if selectedSong.length > 0 {
		var secs = DateComponents()
		secs.second = Int(selectedSong.length)
		labelt.text = format.string(for: secs)
	}else{
		labelt.text = ""
	}
	
	lastnode.removeAction(forKey: "looper")
	lastnode.runAction(movebackward)
	lastnode.runAction(rotateto0)
	
//	waddleforever.timingMode = .easeOut
	cover.removeAllActions()
	cover.position.z = 0
	cover.position.x = 0
	
//	timer?.invalidate()
//	timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true){tim in
//		print(tim.timeInterval)
//		if tim.timeInterval > 10 {
//			Jukebox.shared.fadeout()
//		}
//		if tim.timeInterval > 15 {
//
//			Jukebox.shared.stop()
//			timer?.invalidate()
//		}
//	}
	
	Jukebox.shared.timeit()
	cover.runAction(wad, forKey: "looper") {

		cover.runAction(wadtwice, forKey: "looper")
		Jukebox.shared.getsongfiles(folder: selectedSong.folder!)
		if Jukebox.shared.players.isEmpty {
			print("no players found, you should exit here")
		} else {
			if selectedSong.length < 1 {
				selectedSong.length = Jukebox.shared.players[.guitar]!.duration
				
				labelt.text = format.string(from: selectedSong.length)
				try? pc.viewContext.save()
			}
			if selectedSong.preview == 0 {
				Jukebox.shared.preview(from: 30)
			}else {
				Jukebox.shared.preview(from: selectedSong.preview)
			}
			
			
		}
	}
	
	cover.runAction(moveforward)
	
	lastnode = cover
	animatecolumn (column: column)
	
	DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
		let covers = mainView.nodesInsideFrustum(of: frustum!)
		smanager.revealcoverart(covers: covers)
	}
}

var lastcolumn = SCNNode()
func animatecolumn (column: SCNNode) {
	lastcolumn.position.z 	= 0
	column.position.z 		= 0.25
	lastcolumn 				= column
}

let waddle 	= SCNAction.rotateTo(x: 0, y: 0.5, z: 0, duration: 1.25)


var waddle1:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.5, z: 0, duration: 1.25)
	scna.timingMode = .easeIn
	return scna
}

var waddle2:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.6, z: 0, duration: 1.25)
	scna.timingMode = .easeIn
	return scna
}

var waddle3:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.55, z: 0, duration: 1.25)
	scna.timingMode = .easeOut
	return scna
}

var wad:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.65, z: 0, duration: 1.25)
	scna.timingMode = .easeIn
	return scna
}

let rotateto0 	= SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.4)
let slideout 	= SCNAction.move(to: SCNVector3(0.53, 0, -0.01 ), duration: 0.5)

let moveforward 	= SCNAction.moveBy(x: 0.42, y: 0, z: 2.25, duration: 0.4)
let movebackward 	= SCNAction.moveBy(x: -0.42, y: 0, z: -2.25, duration: 0.4)
let waddleseq 		= SCNAction.sequence([waddle1,waddle2])
let waddleforever 	= SCNAction.repeatForever(waddleseq)
let wadtwice 		= SCNAction.sequence([waddle1, waddle2, waddle3])
let spinrecord 		= SCNAction.rotateTo(x: 0, y: 0, z: -0.25, duration: 0.5)
let delay 			= SCNAction.wait(duration: 0.15)
let delay30 		= SCNAction.wait(duration: 1)

let slideup 		= SCNAction.move(by: SCNVector3(0, 1, 0)	, duration: 0.1)
let slidedown 		= SCNAction.move(by: SCNVector3(0, -1, 0)	, duration: 0.1)
let slideleft 		= SCNAction.move(by: SCNVector3(1, 0, 0)	, duration: 0.1)
let slideright 		= SCNAction.move(by: SCNVector3(-1, 0, 0)	, duration: 0.1)
let waitflash 		= SCNAction.wait(duration: 0.10)
let waitlesss 		= SCNAction.wait(duration: 0.05)
