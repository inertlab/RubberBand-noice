//
//  Defaults.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/8/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import CoreData


class Defaults {
	static let shared = Defaults()
	
	let global = UserDefaults(suiteName: "global")
	
	private init() {}
	
	func defaultuser () -> Player {
		let fet:NSFetchRequest<Player> = Player.fetchRequest()
		let array = try? pc.viewContext.fetch(fet)
		
		if array!.isEmpty {
			print("no players in db, making default one")
			let dplayer 	= Player(context: pc.viewContext)
			dplayer.name 	= "guest"
			dplayer.index 	= 0
			do{
				try pc.viewContext.save()
				print("default player saved")
				global?.set(0, forKey: "userindex")
				global?.set("guest", forKey: "username")
				return dplayer
			}catch{
				print(error)
				print("default player failed to save")
			}
		}else{
			print("players found, selecting player")
			if let selecteduser = global?.integer(forKey: "userindex"){
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
}
