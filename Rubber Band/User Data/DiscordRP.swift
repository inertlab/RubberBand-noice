//
//  DiscordRP.swift
//  noice
//
//  Created by fernando on 1/31/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation
import SwordRPC



class DiscordRP {
	let clientID = "672170746834845727"
	static var rpc:SwordRPC?
	static var p = RichPresence()
	
	func initRPC() {
		// init discord stuff
		DiscordRP.rpc = SwordRPC.init(appId: clientID)
//		rpc!.delegate = self
		print("i am connec, ", DiscordRP.rpc!.connect())
		DiscordRP.rpc?.setPresence(RichPresence())
	}

	func deinitRPC() {
		DiscordRP.rpc!.setPresence(RichPresence())
		DiscordRP.rpc!.disconnect()
		DiscordRP.rpc = nil
	}
	
	static func presence(song: Song) {
		p.state = song.title
		p.details = song.artist
		rpc?.setPresence(p)
	}
}
