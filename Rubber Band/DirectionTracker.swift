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
		if coverindex.0 > 0 {
			coverindex.0 			-= 1
			column 					= smanager.columns[coverindex.0]
			covernode.runAction(slideleft)
			animatecolumn (column: column)
		}else{
			coverindex.0 			= smanager.columns.count - 1
			column 					= smanager.columns[coverindex.0]
			covernode.position.x 	= -CGFloat(coverindex.0)
		}
		animatecover (column: column)
	case .right:
		if coverindex.0 < smanager.cols {
			coverindex.0 			+= 1
			column 					= smanager.columns[coverindex.0]
			covernode.runAction (slideright)
			animatecolumn (column: column)
		}else{
			coverindex.0 			= 0
			column 					= smanager.columns[coverindex.0]
			covernode.position.x 	= -CGFloat(coverindex.0)
		}
		animatecover (column: column)
	case .up:
		if coverindex.1[coverindex.0] > 0{
			column.runAction(slidedown)
			coverindex.1[coverindex.0] -= 1
			animatecover (column: column)
		}else{
			// this only sets the position of the cover
			if coverindex.0 > 0 {
				let i 			= coverindex.0-1
				let col 		= smanager.columns[i]				// col is the destination col
				col.position.y 	= -(col.childNodes.last?.position.y)!
				coverindex.1[i] = col.childNodes.count-1	//set the las cover on the column
			}else{
				let col 		= smanager.columns.last!
				col.position.y 	= -(col.childNodes.last?.position.y)!
				coverindex.1[smanager.columns.count-1] = col.childNodes.count-1
			}
			trackDirection(d: .left)						// this will change and track position of the column
		}
	case .down:
		if coverindex.1[coverindex.0] < column.childNodes.count - 1{
			coverindex.1[coverindex.0] += 1
			column.runAction(slideup)
			animatecover (column: column)
		}else{
			if coverindex.0 < smanager.cols {
				let i							= coverindex.0+1
				coverindex.1[i]					= 0
				smanager.columns[i].position.y	= 0
			}else{
				smanager.columns[1].position.y 	= 0
				coverindex.1[1] 				= 0
			}
			trackDirection(d: .right)
		}
	}
	//	print(coverindex)
}


/// the previously selected cover
var lastnode = SCNNode()
var record = menuScene.rootNode.childNode(withName: "record", recursively: false)
var label = record?.childNode(withName: "label", recursively: false)

func animatecover (column: SCNNode) {
	let cover = column.childNodes[coverindex.1[coverindex.0]] as! CoverArt
	record?.removeAllActions()
	record?.position.x = 0
	record?.rotation.z = 1
	record?.rotation.w = 1.5
	cover.addChildNode(record!)
	cover.addChildNode(menutext.detailnode!)
	

	
//	let stat	= smanager.fetchStatByID(id: cover.id.uuidString)
	
//	print(stat.songid)
	
//	if selectedStat.song == nil{
//		selectedStat.song = smanager.fetchSongById(id: cover.name!)
//		print("reconnected stat to song")
//	}
//	selectedSong 	= selectedStat.song!
	selectedStat	= smanager.sorted.first(where: {$0.songid! == cover.id})!
	selectedSong	= selectedStat.song!
	
	let diff 		= selectedSong.tier?.drums

	var translation = SCNMatrix4()
	let scale 		= SCNMatrix4MakeScale(0.333, 0.333, 0.333)
	
	switch diff {
	case 0: // tier: novice
		translation = SCNMatrix4MakeTranslation(0, 0, 0)
	case 1:
		translation = SCNMatrix4MakeTranslation(1, 0, 0)
	case 2:
		translation = SCNMatrix4MakeTranslation(2, 0, 0)
	case 3:
		translation = SCNMatrix4MakeTranslation(0, 1, 0)
	case 4:
		translation = SCNMatrix4MakeTranslation(1, 1, 0)
	case 5:
		translation = SCNMatrix4MakeTranslation(2, 1, 0)
	case 6: // tier: devil
		translation = SCNMatrix4MakeTranslation(0, 2, 0)
	default:
		translation = SCNMatrix4MakeTranslation(1, 2, 0) // case = nil and -1
		break;
	}
	
	label?.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Mult(translation, scale)
	
	record?.runAction(slideout)
	record?.runAction(spinrecord)
	
	labela.text = selectedSong.artist
	labeln.text = selectedSong.title
	if selectedSong.length > 0 {
		var secs = DateComponents()
		secs.second = Int(selectedSong.length)
		labelt.text = format.string(for: secs)
	}else{
		labelt.text = ""
	}
	
	lastnode.removeAction(forKey: "looper")
	lastnode.runAction(movebackward)
	
	lastnode.runAction(waddler)
	
	waddleforever.timingMode = .easeInEaseOut
	cover.position.z = 0
	cover.position.x = 0
	
	cover.runAction(waddleforever, forKey: "looper")
	cover.runAction(moveforward)
	
	lastnode = cover
}

var lastcolumn = SCNNode()
func animatecolumn (column: SCNNode) {
	lastcolumn.position.z 	= 0
	column.position.z 		= 0.25
	lastcolumn 				= column
}

//let waddle 	= SCNAction.rotate(toAxisAngle: SCNVector4(0, 1, 0, 1)( , duration: 0.5)
let waddle 		= SCNAction.rotateTo(x: 0, y: 0.6, z: 0, duration: 1.25)
//let waddle1 	= SCNAction.rotateTo(x: -0.1, y: 0.3, z: 0, duration: 0.5)
let waddle2 	= SCNAction.rotateTo(x: 0, y: 0.5, z: 0, duration: 1.25)
let waddler 	= SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.4)
let slideout 	= SCNAction.move(to: SCNVector3(0.53, 0, -0.01 ), duration: 0.5)
//let slideout 	= SCNAction.moveBy(x: 0.53, y: 0, z: 0, duration: 0.5)
//let slide 	= SCNAction.moveBy(x: -0.5, y: 0, z: -2.5, duration: 0.25)
//let moveforward = SCNAction.move(to: SCNVector3(0.42, 0, 2.25), duration: 0.4)
let moveforward 	= SCNAction.moveBy(x: 0.42, y: 0, z: 2.25, duration: 0.4)
let movebackward 	= SCNAction.moveBy(x: -0.42, y: 0, z: -2.25, duration: 0.4)
let waddleseq 		= SCNAction.sequence([waddle,waddle2])
let waddleforever 	= SCNAction.repeatForever(waddleseq)
let spinrecord 		= SCNAction.rotateTo(x: 0, y: 0, z: -0.25, duration: 0.5)
let delay 			= SCNAction.wait(duration: 0.15)
let delay30 		= SCNAction.wait(duration: 0.5)

let slideup 		= SCNAction.move(by: SCNVector3(0, 1, 0)	, duration: 0.1)
let slidedown 		= SCNAction.move(by: SCNVector3(0, -1, 0)	, duration: 0.1)
let slideleft 		= SCNAction.move(by: SCNVector3(1, 0, 0)	, duration: 0.1)
let slideright 		= SCNAction.move(by: SCNVector3(-1, 0, 0)	, duration: 0.1)
let waitflash 		= SCNAction.wait(duration: 0.10)
let waitlesss 		= SCNAction.wait(duration: 0.05)

