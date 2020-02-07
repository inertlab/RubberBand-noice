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
	
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
	
	func applicationWillTerminate(_ notification: Notification) {
		User.current.updateUser()
	}
	
	
	@IBAction func deletestats(_ sender: NSMenuItem) {
		scorekeeper.deleteallstats()
	}
	
	@IBAction func countstats(_ sender: NSMenuItem) {
		print(scorekeeper.statcount().description)
	}
	
	@IBAction func deleteStat (_ sender: NSMenuItem) {
//		smanager.deletestat()
	}
	
	@IBAction func printStat (_ sender: NSMenuItem) {
//		smanager.printstat()
	}

	// MARK: catalog + sorting
	//	catalog
	@IBAction func recatalog(_ sender: NSMenuItem) {
		// this crashes because the column letter no longer exists after running this
		// make a new one that only scans for new songs
		smanager.recatalog()
	}
	
	// sorting
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
	
	@IBAction func scanfornewsongs(_ sender: NSMenuItem){
		let finder = SongFinder()
		finder.scanfornewsongs()
		finder.scanforinichanges()
	}
}
