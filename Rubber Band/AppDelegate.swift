	//
	//  AppDelegate.swift
	//  Rubber Band
	//
	//  Created by Fernando on 2/8/18.
	//  Copyright © 2018 Artecolote. All rights reserved.
	//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var mastervolume	: NSSlider!
	@IBOutlet weak var previewvolume: NSSlider!
	@IBOutlet weak var crowdslider	: NSSlider!
	@IBOutlet weak var kraken		: NSMenuItem!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
			// Insert code here to initialize your application
			// set the slider
		mastervolume.floatValue 	= User.current.player.config?.vol_master ?? 0
		previewvolume.floatValue 	= User.current.player.config?.vol_preview ?? 0
		crowdslider.floatValue 		= User.current.player.config?.vol_crowd ?? 0
		Jukebox.shared.volume 		= mastervolume.floatValue
		Jukebox.shared.vol_prev 	= previewvolume.floatValue
		Jukebox.shared.vol_crowd 	= crowdslider.floatValue
		if User.current.player.config!.kraken {
			stagemc.bg 		= true
			kraken.state 	= .on
		}
	}
	
	
	
	func applicationWillTerminate(_ notification: Notification) {
		Jukebox.shared.stop()
		User.current.updateUser()
	}
	
		//MARK: - Stats
	@IBAction func deletestats(_ sender: NSMenuItem) {
		ScoreManager.deleteallstats()
	}
	
	@IBAction func countstats(_ sender: NSMenuItem) {
		print(ScoreManager.statcount().description)
	}
	
	@IBAction func deleteStat (_ sender: NSMenuItem) {

	}
	
		/// writes a list of songs to json file
		/// - Parameter sender: i have no idea
	@IBAction func printStat (_ sender: NSMenuItem) {
		var songs = [StatPrintable]()
		for s in User.current.player.stats! {
			if let song = (s as! Stats).song {
				songs.append(StatPrintable(song: song))
			}
		}
		
		if !songs.isEmpty {
			let json 				= JSONEncoder()
			json.outputFormatting 	= .prettyPrinted
			if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
				let data 	= try! json.encode(SongList(songs: songs))
				let fileURL = dir.appendingPathComponent("songs.json")
					//writing
				do {
					try data.write(to: fileURL)
				}
				catch {/* error handling here */}
			}
		}
	}
	
		//MARK: - Sorting
	@IBAction func sortbyartist(_ sender: NSMenuItem) {
		smanager.reflow(sortedBy: .artist)
	}
	@IBAction func sortbydifficult(_ sender: NSMenuItem) {
		smanager.reflow(sortedBy: .tier)
	}
	@IBAction func sortbyscore(_ sender: NSMenuItem) {
		smanager.reflow(sortedBy: .stars)
	}
	@IBAction func sortbysong(_ sender: NSMenuItem) {
		smanager.reflow(sortedBy: .song)
	}
	
		// MARK: - catalog
		//	catalog
	@IBAction func recatalog(_ sender: NSMenuItem) {
			// this crashes because the column letter no longer exists after running this
			// make a new one that only scans for new songs
		smanager.recatalog()
	}
	
	@IBAction func scanfornewsongs(_ sender: NSMenuItem){
		let finder = SongFinder()
		finder.updatemetadata()
	}
	
	@IBAction func printhistory(_ sender: NSMenuItem) {
			//		for h in User.current.player.history! {
			//			let his = h as! History
			//			print(his.song!.title!, his.date!)
			//		}
	}
	
	@IBAction func mastervolume(_ sender: NSSlider) {
		Jukebox.shared.setvolume(vol: sender.floatValue)
		User.current.updateUser()
	}
	
	@IBAction func previewvolume(_ sender: NSSlider) {
		Jukebox.shared.setpreviewvol(vol: sender.floatValue)
		User.current.updateUser()
	}
	
	@IBAction func crowdnoise(_ sender: NSSlider) {
		Jukebox.shared.setcrowdnoise(vol: sender.floatValue)
		User.current.updateUser()
	}
	
	
	@IBAction func releasekraken(_ sender: NSMenuItem) {
		if sender.state == .off {
			sender.state 	= .on
			stagemc.bg 		= true
		} else {
			sender.state 	= .off
			stagemc.bg 		= false
		}
		User.current.updateUser()
	}
}

struct StatPrintable: Encodable {
	let title: String
	let artist: String
	init(song: Song) {
		self.title = song.title ?? "untitled"
		self.artist = song.artist ?? "uknown"
	}
}

struct SongList: Encodable {
	let songs: [StatPrintable]
}
