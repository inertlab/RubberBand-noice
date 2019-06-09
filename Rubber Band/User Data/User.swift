//
//  Profiler.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/30/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import CoreData


class User {
	static let current = User()
	
	let player:	Player
	var diff: Difficulty = .easy
	private init() {
		self.player = Defaults.shared.defaultuser()
//		self.diff = Difficulty(rawValue: self.player.difficulty) ?? .easy
		labelDiff.text = self.diff.text()
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
		player.name 	= name
		player.index 	= Int16(users.count)
		
		do{
			try pc.viewContext.save()
		}catch{
			print(error)
			print("player failed to save")
		}
	}
	

	func deleteplayers() {
		let delete:NSFetchRequest<NSFetchRequestResult> = Player.fetchRequest()
		let del = NSBatchDeleteRequest(fetchRequest: delete)
		do {
			try pc.viewContext.execute(del)
		}catch let err as NSError {
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





//
//func setplayer (name: String) -> Player {
//	print("settubg player")
//	let fet:NSFetchRequest<Player> = Player.fetchRequest()
//	fet.predicate 	= NSPredicate(format: "name == %@", name)
//	fet.fetchLimit 	= 1
//	let array = try? pc.viewContext.fetch(fet)
//	if array?.count == 0 {
//		print("no players found")
//		return defaultuser()
//	}
//	print("player found and setting it")
//	return array![0]
//}
