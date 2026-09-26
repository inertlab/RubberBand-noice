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
	
	/// checks if library folder has been modified
	static func modifiedlib() -> Bool {
		return false
	}
	
	static func config() -> Config {
		let fetconfig: NSFetchRequest<Config> = Config.fetchRequest()
		
		let configs = try? pc.viewContext.fetch(fetconfig)
		
		if configs!.isEmpty {
			let newconfig = Config(context: pc.viewContext)
			let player = Defaults.getplayer()
			newconfig.currentplayer = player
			do{
				try pc.viewContext.save()
				print("new config saved")
				return newconfig
			}catch{
				print(error)
			}
		}
		let config = configs![0]
		if config.currentplayer == nil {
			let player = Defaults.getplayer()
			config.currentplayer = player
			do{
				try pc.viewContext.save()
				print("new config saved")
			}catch{
				print(error)
			}
		}
		return config
	}
	
	/// checks for players and returns player[0], makes one
	static func getplayer() -> Player {
		let fet:NSFetchRequest<Player> = Player.fetchRequest()
		let array = try? pc.viewContext.fetch(fet)
		
		if array!.isEmpty {
			print("no players in db, making default one")
			let dplayer = Player(context: pc.viewContext)
			dplayer.name = "guest"
			dplayer.index = 0
			do{
				try pc.viewContext.save()
				print("default player saved")
				return dplayer
			}catch{
				print(error)
				print("default player failed to save")
			}
		}
		return (array?.first)!
	}
}
