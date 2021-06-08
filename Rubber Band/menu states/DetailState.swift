//
//  DetailState.swift
//  noice
//
//  Created by Fernando Zamora on 6/6/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import GameplayKit

class DetailState: GKState {
	
	let octo: Octopus
	
	init(octo: Octopus) {
		self.octo = octo
	}

	override func didEnter(from previousState: GKState?) {
		if previousState is HelpState {
			return
		}
		ListState.screen = .detail
		octo.comein()
		updatedetails()
		UpNext.shared.hide()
		rowcall.state = .detail
		labeldetails?.run(Actions.shared.fadein)
	}
	
	override func willExit(to nextState: GKState) {
		if nextState is HelpState {
			return
		}
		octo.leave()
		rowcall.state = .off
		labeldetails?.removeAllActions()
		labeldetails?.run(Actions.shared.fadeout)
	}
	
	/// updates and displays details view and sets the states. does not control other view labels
	///
	/// detail view can come from menu view, or other song views
	func updatedetails () {
		smanager.selected.state = .detailview
		labelphrase.text 	= smanager.selected.song.phrase
		labelcharter.text 	= smanager.selected.song.charter
		labelyear.text 		= smanager.selected.song.year.description
		labelalbum.text		= smanager.selected.song.trackOf?.name
		labelgenre.text 	= smanager.selected.song.genre
		
		SongLister.shared.loadreleatedsongs(artistsong: smanager.selected.song)
	}
}
