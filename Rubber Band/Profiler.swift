//
//  Profiler.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/30/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import CoreData

let globaldefaults = UserDefaults(suiteName: "global")

private func defaultuser () -> Player {
	
	let fet:NSFetchRequest<Player> = Player.fetchRequest()
	let array = try? pc.viewContext.fetch(fet)
	
	if array?.count == 0 {
		print("no players in db, making default one")
		let dplayer 	= Player(context: pc.viewContext)
		dplayer.name 	= "guest"
		dplayer.index 	= 0
		do{
			try pc.viewContext.save()
			print("default player saved")
			globaldefaults?.set(0, forKey: "userindex")
			globaldefaults?.set("guest", forKey: "username")
			return dplayer
		}catch{
			print(error)
			print("default player failed to save")
		}
	}else{
		print("players found, selecting player")
		if let selecteduser = globaldefaults?.integer(forKey: "userindex"){
			print("userindex found")
			for p in array! {
				if p.index == selecteduser {
					return p
				}
			}
		}
	}
	
	return (array?.first)!
}

class UserDefault {
	let player:	Player
	let prefs:	UserDefaults
	init() {
		self.player = defaultuser()
		self.prefs 	= UserDefaults(suiteName: self.player.name)!
	}
	
	func printinfo()  {
		print(prefs.integer(forKey: "userindex"))
	}
}

private extension UserDefault {
	func doessonghavescore(song: Song) -> Bool {
		
		
		return false
	}
	
	func playerhasscore(song: Song) -> Bool {
		
		return false
	}
}

let userdef = UserDefault()



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



func newplayer (name: String)  {
	let fet:NSFetchRequest<Player> = Player.fetchRequest()
	//	fet.predicate 	= NSPredicate(format: "name == %@", "guest")
	//	fet.fetchLimit 	= 1
	let array = try? pc.viewContext.fetch(fet)
	
	print("there are \(array?.count.description ?? "0") players")
	
	let player = Player(context: pc.viewContext)
	//		player.name = "guest"
	player.index = Int16(array!.count)
	do{
		try pc.viewContext.save()
		//			return player
	}catch{
		print(error)
		print("player failed to save")
	}
	
	
	//	return array![0]
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
