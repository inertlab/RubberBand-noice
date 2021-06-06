//
//  CoverEntity.swift
//  RubberBand
//
//  Created by Fernando Zamora on 1/19/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit
import SceneKit


enum SelState {
	case selected, notselected, detailview, othersongs
	
	func z() -> CGFloat {
		switch self {
		case .selected:
			return 2.25
		case .detailview:
			return 3.5
		case .othersongs:
			return 3
		default:
			return 0
		}
	}
}

//MARK: - Song Comp
/// geometry node component
///
/// initially conatins no album art - to be loaded when it comes into scene
class SongComp: GKComponent {
	
	var state = SelState.notselected {
		didSet {
			switch state {
			case .selected:
				// check where it is being selected from
				switch oldValue {
				case .notselected:
					initiateselected()
					previewsong(song: self)
					fallthrough
					case .detailview:
						cover.runAction(SCNAction.move(to: SCNVector3(x: 0.42, y: row, z: state.z()), duration: 0.4))
				default:
					break
				}
			case .notselected:
				Jukebox.shared.stop()
				cover.opacity = 1
				reset()
			case .detailview:
				// covernode goes back 1.25 this moves forward 1.25
				// if it wasn't previously selected, add record and stars and update titles etc
				if oldValue == .notselected {
					initiateselected()
					cover.runAction(waddle3)
				}
				cover.runAction(SCNAction.move(to: SCNVector3(x: 0.42, y: row, z: state.z()), duration: 0.5))
			case .othersongs:
				cover.runAction(SCNAction.move(to: SCNVector3(x: 0.42, y: row, z: state.z()), duration: 0.5))
				cover.runAction(SCNAction.fadeOpacity(to: 0.05, duration: 0.75))
			}
		}
	}
	
	let song:Song
	var index 		= 0
	var row:CGFloat = 0
	let cover 		= makecoverart()
	
	init(song:Song){
		self.song = song
		super.init()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func getcolumn() -> ColumnComp {
		let column = self.entity?.component(ofType: ColumnComp.self)
		return column!
	}
}

private extension SongComp {
	func initiateselected() {
		UpNext.shared.listnodes[3].text = "# \(index + 1)"
		getcolumn().index = index
		self.entity?.addComponent(smanager.record)
		self.entity?.addComponent(smanager.stars)
		labela.text = song.artist
		labeln.text = song.title
	}
	
	func reset() {
		cover.removeAllActions()
		cover.runAction(SCNAction.move(to: SCNVector3(x: 0, y: row, z: 0), duration: 0.4))
		cover.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.4))
	}
}

//MARK: - Record
class RecordComp: GKComponent {
	let node = menuScene.rootNode.childNode(withName: "record", recursively: false)!

	override func didAddToEntity() {
		reset()
		let song = self.entity?.component(ofType: SongComp.self)
		song?.cover.addChildNode(self.node)
		self.node.runAction(SCNAction.move(to: SCNVector3(0.53, 0, -0.01 ), duration: 0.5))
		self.node.runAction(SCNAction.rotateTo(x: 0, y: 0, z: -0.25, duration: 0.5))
	}
}
private extension RecordComp {
	func reset() {
		node.removeAllActions()
		node.position.x = 0
		node.rotation.z = 1
		node.rotation.w = 1.5
	}
}

//MARK: - Column
/// Column node entity belongs to
class ColumnComp: GKComponent {
	let posx	: CGFloat
	let node	: SCNNode
	var letter 	= SCNNode()
	var index 	= 0
	init(column: CGFloat, node: SCNNode){
		self.posx = column
		self.node = node
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func highlight() {
		letter.runAction(SCNAction.fadeIn(duration: 0.5))
		letter.position.z = 0.5
	}
	
	func unhilight() {
		letter.runAction(SCNAction.fadeOpacity(to: 0.15, duration: 0.35))
		letter.position.z = 0.25
	}
	
	func addletter(char: String) {
		if let textnode = albumscn.rootNode.childNode(withName: "colnum", recursively: false){
			letter = textnode.clone()
			letter.geometry = textnode.geometry?.copy() as! SCNText
			(letter.geometry as! SCNText).string = char
			letter.position.x = posx
			covernode.addChildNode(self.letter)
			unhilight()
		}
	}
}

class StarsComp: GKComponent {
	let node = menuScene.rootNode.childNode(withName: "details", recursively: false)!

	override func didAddToEntity() {
		let song = self.entity?.component(ofType: SongComp.self)
		song?.cover.addChildNode(self.node)
	}
}

//MARK: - Functions

fileprivate func makecoverart() -> SCNNode {
	let plane = SCNPlane(width: 0.8, height: 0.8)
	plane.firstMaterial = (cover.geometry?.firstMaterial?.copy() as! SCNMaterial)
	plane.firstMaterial?.diffuse.contents = nil
	let node = SCNNode(geometry: plane)
	return node
}


fileprivate func previewsong(song: SongComp) {
	Jukebox.shared.timeit()
	song.cover.runAction(wad, forKey: "looper") {
		song.cover.runAction(wadtwice, forKey: "looper")
		Jukebox.shared.getsongfiles(folder: song.song.folder!)
		if Jukebox.shared.players.isEmpty {
			print("no players found, you should exit here")
		} else {
			if song.song.length < 1 {
				song.song.length = Jukebox.shared.players[.guitar]!.duration
				labelt.text = format.string(from: song.song.length)
				try? pc.viewContext.save()
			}
			if song.song.preview == 0 {
				Jukebox.shared.preview(from: 30)
			}else {
				Jukebox.shared.preview(from: song.song.preview)
			}
		}
	}
}


fileprivate let albumscn = SCNScene(named: "art.scnassets/scns/album.scn")!
fileprivate let cover 	= albumscn.rootNode.childNode(withName: "cover", recursively: false)!

//MARK: - Waddle Animations
fileprivate var waddle1:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.5, z: 0, duration: 1.25)
	scna.timingMode = .easeIn
	return scna
}

fileprivate var waddle2:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.6, z: 0, duration: 1.25)
	scna.timingMode = .easeIn
	return scna
}

fileprivate var waddle3:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.55, z: 0, duration: 1.25)
	scna.timingMode = .easeOut
	return scna
}

fileprivate var wad:SCNAction {
	let scna = SCNAction.rotateTo(x: 0, y: 0.65, z: 0, duration: 1.25)
	scna.timingMode = .easeIn
	return scna
}

fileprivate let wadtwice = SCNAction.sequence([waddle1, waddle2, waddle3])

