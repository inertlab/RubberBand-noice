//
//  Profiler.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/30/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import CoreData
import SpriteKit

protocol UserDelegate {
	func changedinstrument(tier: Int16)
}

class User {
	static let current = User()
	var delegate: UserDelegate?
	let player:	Player
	
//	this labels are here because they relate to user options and not song details
	let difficultylabel = menuOverlay?.childNode(withName: "details/difficulty") as! SKLabelNode
	let instrumentlabel = menuOverlay?.childNode(withName: "details/instrument") as! SKLabelNode
	
	var diff: Difficulty = .expert {
		didSet {
			difficultylabel.text = diff.text()
		}
	}
	
	var instrument: Instrument  {
		didSet {
			updatekeycode(self.instrument)
			instrumentlabel.text = instrument.name()
			delegate?.changedinstrument(tier: instrument.gettier())
		}
	}
	
	private init() {
		self.player = Defaults.config().currentplayer!
		self.diff = Difficulty(rawValue: self.player.difficulty)!
		self.instrument = Instrument(rawValue: self.player.instrument)!
		difficultylabel.text = self.diff.text()
		instrumentlabel.text = self.instrument.name()
	}
	
	/// Saves config options to user database
	///
	/// Saved options:
	/// - difficulty
	///	- instrument
	///	- volume
	///	- kraken
	///
	func updateUser() {
		player.difficulty = diff.rawValue
		player.instrument = instrument.rawValue
		player.config?.vol_master = Jukebox.shared.volume
		player.config?.vol_preview = Jukebox.shared.vol_prev
		player.config?.vol_crowd = Jukebox.shared.vol_crowd
		player.config?.kraken = stagemc.bg
		do {
			try pc.viewContext.save()
		} catch  {
			print(error)
		}
	}
	
	func printinfo() {
		print("player = \(player.name!) and index = \(player.index)")
	}
	
	func newPlayer (name: String)  {
		let users = findUsers()
		let user = users.contains {$0.name == name }
		
		if user {
			print("name has been taken")
		} else {
			
		}
		
		let player = Player(context: pc.viewContext)
		player.name = name
		player.index = Int16(users.count)
		
		do {
			try pc.viewContext.save()
		} catch {
			print("player failed to save")
		}
	}
	
	func deleteplayers() {
		let delete: NSFetchRequest<NSFetchRequestResult> = Player.fetchRequest()
		let del = NSBatchDeleteRequest(fetchRequest: delete)
		do {
			try pc.viewContext.execute(del)
		} catch let err as NSError {
			print(err)
		}
	}
}

private extension User {
	func findUsers() -> [Player] {
		let fet:NSFetchRequest<Player> = Player.fetchRequest()
		return try! pc.viewContext.fetch(fet)
	}
}
