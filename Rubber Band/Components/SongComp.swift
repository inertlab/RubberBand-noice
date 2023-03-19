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
			return 2.75
		default:
			return 0
		}
	}
}



private let labeln = menuOverlay?.childNode(withName: "name") 	as! SKLabelNode
private let labela = menuOverlay?.childNode(withName: "artist") as! SKLabelNode
private let labelt = menuOverlay?.childNode(withName: "time") 	as! SKLabelNode


//MARK: - Song Comp
/// Contains the Song instance, cover art, and selection status
///
/// album art is loaded when it comes into camera view, it should be unloaded in the future
///
/// Selection state controls the animaton and positioning of Album Art - Record node is a different component
class SongComp: GKComponent {
	
	var state = SelState.notselected {
		didSet {
			switch state {
			case .selected:
				// check where it is being selected from
				switch oldValue {
				case .notselected, .othersongs:
					initiateselected()
					time()
					previewsong(song: self)
					fallthrough
					case .detailview:
						cover.runAction(SCNAction.move(to: SCNVector3(x: 0.42, y: row, z: state.z()), duration: 0.4), forKey: "movez")
				default:
					break
				}
			case .notselected:
//				Jukebox.shared.stop()
				cover.opacity = 1
				reset()
			case .detailview:
				// covernode goes back 1.25 this moves forward 1.25
				// if it wasn't previously selected, add record and stars and update titles etc
				if oldValue == .notselected {
					initiateselected()
					cover.runAction(waddle3)
				}
				cover.runAction(SCNAction.move(to: SCNVector3(x: 0.42, y: row, z: state.z()), duration: 0.5), forKey: "movez")
			case .othersongs:
				cover.runAction(SCNAction.move(to: SCNVector3(x: 0.42, y: row, z: state.z()), duration: 0.5), forKey: "movez")
				cover.runAction(SCNAction.fadeOpacity(to: 0.05, duration: 0.75), forKey: "coveropacity")
			}
		}
	}
	
	let song		: Song
	var index 		= 0
	var row:CGFloat	= 0
	let cover 		= makecoverart()
	
	init(song:Song) {
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
	
	func time() {
		if song.length > 0 {
			var secs 	= DateComponents()
			secs.second = Int(song.length)
			labelt.text = format.string(for: secs)
		}else{
			labelt.text = ""
		}
	}
	
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
		if Jukebox.shared.players.isEmpty && Jukebox.shared.fplayers.isEmpty {
			print("no players found, you should exit here")
		} else {
			// if song duration is not marked get the song duration
			if song.song.length < 1 {
				song.song.length = Jukebox.shared.duration()!
				labelt.text = format.string(from: song.song.length)
				try? pc.viewContext.save()
			}
			
			if Jukebox.shared.timer.isValid {
				if song.song.preview == 0 {
					Jukebox.shared.preview(from: 30)
				}else {
					Jukebox.shared.preview(from: song.song.preview)
				}
			}
		}
	}
}


let albumscn = SCNScene(named: "art.scnassets/scns/album.scn")!
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

