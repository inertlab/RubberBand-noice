//
//  SongManager.swift
//  RubberBand
//
//  Created by Fernando on 3/7/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Cocoa
import SceneKit
import SpriteKit


let loadingscreen 	= SKScene(fileNamed: "LoadingScreen.sks")
let loadcount 		= loadingscreen?.childNode(withName: "loadcount") as! SKLabelNode
let noice 			= loadingscreen?.childNode(withName: "noice") as! SKSpriteNode

let menuOverlay 	= SKScene(fileNamed: "titleDisplay.sks")

let menuScene 		= SCNScene(named: "art.scnassets/scns/menu_song.scn")!
var covernode 		= menuScene.rootNode.childNode(withName: "coverflow", recursively: true)!

struct MenuText {
	let detailscene		= SKScene(fileNamed: "songDetails.sks")
	let detailslabel	: SKLabelNode
	let detailnode 		= menuScene.rootNode.childNode(withName: "details", recursively: true)
	init(){
		self.detailslabel = detailscene?.childNode(withName: "details") as! SKLabelNode
		//		self.detailnode?.geometry?.firstMaterial?.diffuse.contents = detailscene
	}
}
let menutext = MenuText()

/// reference to the song catalog in coredata
let pc: NSPersistentContainer = {
	let container = NSPersistentContainer(name: "catalog")
//	container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
	container.loadPersistentStores(completionHandler: { (storeDescription, error) in
		if let error = error {
			print("hello no")
			fatalError("Unresolved error \(error)")
		}
	})
	return container
}()


/// Retrieves Song information from coredata and creates album art for menu display
class SongManager: SCNLayer {
	let noart	= NSImage(named: "noart")
	/// the scnnodes containing a row of covers
	var columns = covernode.childNodes
	var coverlimit = [CGFloat]()
	var sortkeypath:SortKeypath = .song
	var sorting:SortKeypath = .song
	var cols = 0
	/// array of ordered Stats used to arrange covers
	/// - kept and reused trhoughout life of game
	/// - updated every time user sorts music
	var sorted = [Stats]()
	/// array of the CoverArt (scnnodes with UUID)
	/// - Loaded once at start, can take a while to build
	/// - Needs to be rebuilt if cataloging songs again
	var covers = [CoverArt]()
	/// Creates and displays cover art for songs in the core library arranged by Artist
	
	
	private func createcovers (stats: [Stats]) {
		covers = []
		var count = sorted.count
		let tot = CGFloat(count)
		var countup = 1
		for stat in stats {
			count -= 1
			countup += 1
//			if countup % 10 == 0 {
				noice.alpha = CGFloat(countup) / tot
//			}
			loadcount.text = String(format: "%04d", count)
			//			}
//			let song	= stat.song!
			let cover 	= CoverArt(id: stat.songid!)
			
//			let arturl 	= song.trackOf?.value(forKey: "albumArt") as! URL
//
//			let art:NSImage! = NSImage(byReferencing: arturl)
//
//			if art.isValid {
//				cover.geometry?.firstMaterial?.diffuse.contents = art
//			}else{
//				cover.geometry?.firstMaterial?.diffuse.contents = noart
//				print(song.title!)
//			}
			covers.append(cover)
		}
	}
	
	func revealcoverart2(covers: [SCNNode], art: NSImage) {
		for c in covers {
			if c.geometry?.firstMaterial?.diffuse.contents != nil {continue}
			if let _ = c as? CoverArt{
				
				if art.isValid {
					c.geometry?.firstMaterial?.diffuse.contents = art
				}else{
					c.geometry?.firstMaterial?.diffuse.contents = noart
				}
			}
		}
	}
	
	func revealcoverart(covers: [SCNNode]) {
		for c in covers {
			if c.geometry?.firstMaterial?.diffuse.contents != nil {continue}
			if let co = c as? CoverArt{
				let song 	= sorted.first(where: {$0.songid == co.id})?.song
				let arturl 	= song!.trackOf?.value(forKey: "albumArt") as! URL
				let art:NSImage! = NSImage(byReferencing: arturl)
				
				if art.isValid {
					c.geometry?.firstMaterial?.diffuse.contents = art
				}else{
					c.geometry?.firstMaterial?.diffuse.contents = noart
				}
			}
		}
	}
	
	/// Initializes Coverflow, run only once at beginning of game
	func coverflow () {
		sorted 	= fetchStats(sortBy: sortkeypath.value())
		createcovers(stats: sorted)
		flowcoverart()
	}
	
	/// Sorts Album Art by given KeyPath
	///
	/// - Parameter keypath: path to sorting value for Stat
	func reflow (sortedBy keypath: SortKeypath) {
		if sortkeypath ==  keypath { return }
		if keypath == .artist { sorting = .artist} else {sorting = .song}
		sortkeypath = keypath
		let tempcontainer = movecoverstotempcol()
		sorted 	= fetchStats(sortBy: keypath.value())
		flowcoverart()
		tempcontainer.removeFromParentNode()
	}
	
	private func flowcoverart () {
		self.coverlimit 	= [] // reset cover limit

		var char		 	= ""
		var row 			= CGFloat(1)
		var col 			= CGFloat(1)
		var colnode 		= SCNNode()
		colnode 			= makeColumn(name: "col-" + col.description)
		colnode.position.x 	= col

		for stat in sorted {
			let tchar 	= (stat.value(forKeyPath: sorting.value()) as! String).first!.uppercased().folding(options: .diacriticInsensitive, locale: .current)
			if char == "" {
				char = tchar
			}
			if tchar == char {
				row -= 1
			}else{
				self.coverlimit.append(row)
				char 				= tchar
				row 				= 0
				col 				+= 1
				colnode 			= makeColumn(name: "col-"+col.description)
				colnode.position.x 	= col
			}
			let cover			= covers.first(where: {$0.id == stat.songid})
			cover?.position.y 	= row
			if (cover != nil) {
				colnode.addChildNode(cover!)
			} else {
				row += 1
			}
		}
		self.coverlimit.append(row) // append the last column to coverlimit
		resetcolumns()
		animatecover(column: self.columns[coverindex.0])
	}
	
	/// Retrieves list of Stats ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Song sorted by Artist or Album
	func fetchStats (sortBy: String) -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let sorter = NSSortDescriptor(key: sortBy, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		let second = NSSortDescriptor(key: "song.title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		fet.predicate = NSPredicate(format: "song != %@", "nil")
		fet.sortDescriptors = [sorter, second]
//		fet.fetchLimit = 100
		let array = try? pc.viewContext.fetch(fet)
		return array!
	}
	
	/// Retrives song from coredata with the given ID (cover name)
	///
	/// - Parameter id: unique Int id for song - also used as name for cover (cover.name)
	/// - Returns: First song in the array of Songs found
	func fetchSongById (id: String) -> Song {
		let fetch:NSFetchRequest<Song> = Song.fetchRequest()
			fetch.predicate 	= NSPredicate(format: "uuid == %@", id)
			fetch.fetchLimit 	= 1
		let array = try? pc.viewContext.fetch(fetch)

		return array![0]
	}
	
	func fetchStatByID (id: String) -> Stats {
		let fetch:NSFetchRequest<Stats> = Stats.fetchRequest()
		fetch.predicate 	= NSPredicate(format: "songid == %@", id)
		fetch.fetchLimit 	= 1
		let array = try? pc.viewContext.fetch(fetch)
		if array?.count == 0 {
			return createstats(uuid: id)!
		}
		return array![0]
	}
	
	/// Removes all songs from coredata and cover art from view
	func deleteCatalog() {
		let delete:NSFetchRequest<Song> = Song.fetchRequest()
//		let del = NSBatchDeleteRequest(fetchRequest: delete)
		do {
			let songarray = try pc.viewContext.fetch(delete)
			for s in songarray {
				pc.viewContext.delete(s)
			}
			try pc.viewContext.save()
		}catch let err as NSError {
			print(err)
		}
		self.removecovers()
	}
	
	func connectsongtostats() {
		let fetstat:NSFetchRequest<Stats> = Stats.fetchRequest()
		fetstat.predicate = NSPredicate(format: "song == %@", "nil")
		
		do {
			let stats = try pc.viewContext.fetch(fetstat)
			for s in stats {
				print("the song is = " + (s.songid?.description)!)
			}
		}catch let err as NSError {
			print(err)
		}
	}
}


private extension SongManager {
	
	func createstats(uuid: String) -> Stats? {
		let stat = Stats(context: pc.viewContext)
		let song = fetchSongById(id: uuid)
		song.addToStats(stat)
		User.current.player.addToStats(stat)
		stat.songid 	= song.uuid
		stat.pindex		= User.current.player.index
		try? pc.viewContext.save()

		print("created stat line 223")
		return stat
	}

	/// Creates a single column of 3D album covers
	///
	/// - Parameter name: this is set in reflow() or coverflow()
	/// - Returns: 3D column of album covers
	func makeColumn (name: String) -> SCNNode {
		let column 		= SCNNode()
			column.name = name
		covernode.addChildNode(column)
		return column
	}
	
	/// Deletes all album art from covernode
	func removecovers () {
		for col in covernode.childNodes {
			col.removeFromParentNode()
		}
		self.resetcolumns()
	}
	
	/// creates a temporary node to hold existing album covers for resorting into new columns. this node gets discarded after used
	///
	/// - Returns: temporary albums holder
	func movecoverstotempcol () -> SCNNode {
		let tempcol = SCNNode()
		menuScene.rootNode.addChildNode(tempcol)
		for col in covernode.childNodes {
			
			for cover in col.childNodes {
				tempcol.addChildNode(cover)
			}
			col.removeFromParentNode()
		}
		return tempcol
	}
	
	/// resets all params to 0 and recounts columns and limits
	func resetcolumns() {
		covernode.position.x = 0
		self.columns 	= covernode.childNodes
		self.cols 		= self.columns.count - 1
		coverindex 		= (Int(0), Array(repeating: 0, count: self.columns.count))
	}
}


let smanager 	= SongManager()

