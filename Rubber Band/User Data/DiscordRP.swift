//
//  DiscordRP.swift
//  noice
//
//  Created by fernando on 1/31/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation
import SwiftRPC

//let rpc = SwiftRPC(appId: "672170746834845727")
//
//rpc.onConnect { rpc in
//	var presence = RichPresence()
//	presence.details = "In Menu"
//	presence.state = "Selecting Track"
//	presence.timestamps.start = Date()
//	presence.assets.largeImage = "logo"
//
//	rpc.setPresence(presence)
//}
//
//rpc.connect()


class DiscordRP {
	let clientID = "672170746834845727"
	static var rpc: SwiftRPC?
	static var p = RichPresence()
	
	func initRPC() {
		// init discord stuff
		DiscordRP.rpc = SwiftRPC(appId: clientID)
//		rpc!.delegate = self
		print("i am connec, ", DiscordRP.rpc!.connect())
		DiscordRP.rpc?.setPresence(DiscordRP.p)
	}

	func deinitRPC() {
		DiscordRP.rpc!.setPresence(RichPresence())
//		DiscordRP.rpc!.disconnect()
		DiscordRP.rpc = nil
	}
	
	static func presence(song: Song) {
		p.state = song.title ?? "untitled"
		p.details = song.artist ?? "no artist?"
		rpc?.setPresence(p)
	}
}
