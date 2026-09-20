//
//  SongDetails.swift
//  noice
//
//  Created by fernando on 1/22/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit
import SwiftRPC

class SongDetails {
	
	let node 	= menuOverlay?.childNode(withName: "details")
	let album 	= menuOverlay?.childNode(withName: "details/album") 	as! SKLabelNode
	let charter = menuOverlay?.childNode(withName: "details/charter") 	as! SKLabelNode
	let genre 	= menuOverlay?.childNode(withName: "details/genre") 	as! SKLabelNode
	let phrase 	= menuOverlay?.childNode(withName: "details/phrase") 	as! SKLabelNode
	let year 	= menuOverlay?.childNode(withName: "details/year") 		as! SKLabelNode
	let rp 		= RichPresence()
	
	/// updates and displays details view and sets the states. does not control other view labels
	///
	/// detail view can come from menu view, or other song views
	func update (_ comp: SongComp) {
		comp.state 		= .detailview
		phrase.text 	= comp.song.phrase
		charter.text 	= comp.song.charter
		year.text 		= comp.song.year.description
		album.text		= comp.song.trackOf?.name
		genre.text 		= comp.song.genre
	
		SongLister.shared.loadreleatedsongs(artistsong: comp.song)
	}
	
	func hide () {
		node?.run(Actions.shared.fadeout, withKey: "detailsfade")
	}
	
	func show () {
		node?.run(Actions.shared.fadein, withKey: "detailsfade")
	}
}
