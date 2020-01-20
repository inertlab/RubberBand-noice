//
//  SongManager.swift
//  RubberBand
//
//  Created by Fernando on 3/7/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//


// TO DO : add sorting by stats

import Cocoa
import SceneKit
import SpriteKit
import GameplayKit


let loadingscreen 	= SKScene(fileNamed: "LoadingScreen.sks")
let loadcount 		= loadingscreen?.childNode(withName: "loadcount") as! SKLabelNode
let noice 			= loadingscreen?.childNode(withName: "noice") as! SKSpriteNode

let menuOverlay 	= SKScene(fileNamed: "titleDisplay.sks")

let menuScene 		= SCNScene(named: "art.scnassets/scns/menu_song.scn")!
var covernode 		= menuScene.rootNode.childNode(withName: "coverflow", recursively: true)!

struct MenuText {
//	let detailscene		= SKScene(fileNamed: "songDetails.sks")
//	let detailslabel	: SKLabelNode
	let detailnode 		= menuScene.rootNode.childNode(withName: "details", recursively: true)
	init(){
//		self.detailslabel = detailscene?.childNode(withName: "details") as! SKLabelNode
		//		self.detailnode?.geometry?.firstMaterial?.diffuse.contents = detailscene
	}
}

let menutext = MenuText()

/// Retrieves Song information from coredata and creates album art for menu display
class SongManager {
	
	var songenties 	= Set<SongEntity>()
	var coversystem = GKComponentSystem(componentClass: CoverArtComp.self)
	let noart		= NSImage(named: "noart")
	/// the scnnodes containing a row of covers
	var columns 	= covernode.childNodes
	var coverlimit 	= [CGFloat]()
	var sortkeypath:SortKeypath = .song
	var sorting:SortKeypath = .song
	var cols = 0
	/// array of ordered Stats used to arrange covers
	/// - kept and reused trhoughout life of game
	/// - updated every time user sorts music
	var sorted = [Song]()
	/// array of the CoverArt (scnnodes with UUID)
	/// - Loaded once at start, can take a while to build
	/// - Needs to be rebuilt if cataloging songs again
	var covers = [CoverArt]()
	
	/// Creates cover art and displays progress for songs in the core library arranged by Artist
	private func createcovers1 (songs: [Song]) {
		covers = []
		var count = sorted.count
		let total = CGFloat(count)
		var countup = 1
		for song in songs {
			count -= 1
			countup += 1
			noice.alpha = CGFloat(countup) / total

			loadcount.text = String(format: "%04d", count)
			let cover 	= CoverArt(id: song.uuid!)
			covers.append(cover)
		}
	}
	
	private func createcovers (songs: [Song]) {
		covers = []
		var count = sorted.count
		let total = CGFloat(count)
		var countup = 1
		for song in songs {
			count -= 1
			countup += 1
			noice.alpha = CGFloat(countup) / total

			loadcount.text = String(format: "%04d", count)

			let songenty = SongEntity(song: song)
			coversystem.addComponent(foundIn: songenty)
			songenties.insert(songenty)
		}
	}
	
//	func revealcoverart2(covers: [SCNNode], art: NSImage) {
//		for c in covers {
//			if c.geometry?.firstMaterial?.diffuse.contents != nil {continue}
//			if let _ = c as? CoverArt{
//
//				if art.isValid {
//					c.geometry?.firstMaterial?.diffuse.contents = art
//				}else{
//					c.geometry?.firstMaterial?.diffuse.contents = noart
//				}
//			}
//		}
//	}
	
	/// camera base culling of cover art
	/// - Parameter covers: reveals cover art if within camera frustrum
	func revealcoverart(covers: [SCNNode]) {
		for c in covers {
			if c.geometry?.firstMaterial?.diffuse.contents != nil {continue}
			if let co = c as? CoverArt{
				let song 	= sorted.first(where: {$0.uuid == co.id})
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
		sorted 	= fetchSongs(sortBy: sortkeypath.value())

		createcovers(songs: sorted)

		if !sorted.isEmpty{
			flowcoverart()
		}
	}
	
	/// Sorts Album Art by given KeyPath
	///
	/// - Parameter keypath: path to sorting value for Stat
	func reflow (sortedBy keypath: SortKeypath) {
		
		if sortkeypath ==  keypath { return }
		if keypath == .artist { sorting = .artist} else {sorting = .song}
		sortkeypath 		= keypath
		let tempcontainer 	= movecoverstotempcol()
		
		// if sorting requires stat switch fetch method
		if keypath == .stars {
			sorted = fetchSongs(sortByStat: keypath.value())
		} else {
			sorted = fetchSongs(sortBy: keypath.value())
		}
		flowcoverart()
		tempcontainer.removeFromParentNode()
	}
	
	/// DEPRICATED - Retrieves list of Stats ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Stats sorted by Artist or Album
	func fetchStats (sortBy: String) -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let sorter 		= NSSortDescriptor(key: sortBy, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		let second 		= NSSortDescriptor(key: "song.title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		fet.predicate 	= NSPredicate(format: "song != %@", "nil")
		fet.sortDescriptors = [sorter, second]
//		fet.fetchLimit = 100
		let array = try? pc.viewContext.fetch(fet)
		return array!
	}
	
	/// Retrieves list of Songs ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Songs sorted by Artist or Album
	func fetchSongs (sortBy: String) -> [Song] {
		
		// what happends when sorting = .stars?
		
		let fet:NSFetchRequest<Song> = Song.fetchRequest()
		let sorter = NSSortDescriptor(key: sortBy, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		let second = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
//		fet.predicate = NSPredicate(format: "song != %@", "nil")
		fet.sortDescriptors = [sorter, second]
		//		fet.fetchLimit = 100
		let array = try? pc.viewContext.fetch(fet)
		print("ist me margaret")
		return array!
	}
	
	/// Retrieves list of Songs ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Songs sorted by Artist or Album
	func fetchSongs (sortByStat: String) -> [Song] {
		
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let sorter 		= NSSortDescriptor(key: sortByStat, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		let second 		= NSSortDescriptor(key: "song.title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
//		fet.predicate 	= NSPredicate(format: "song != %@", "nil")
		fet.sortDescriptors = [sorter, second]
		
		var songs = [Song]()
		
		let array = try? pc.viewContext.fetch(fet)
		for stat in array! {
			songs.append(stat.song!)
		}
		return songs
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
		if array!.isEmpty {
			return createstats(uuid: id)!
		}
		return array![0]
	}
	
	/// Removes all songs from coredata and cover art from view but nat the stats
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
	
	/// Deletes current catalog and rescans library
	///
	/// If a user stat is not currently found, a new stat is created.
	/// Deleting songs should not delete stats
	func recatalog()  {
		deleteCatalog()
		let sfinder = SongFinder()
		sfinder.catalogSongs()
		coverflow()
	}
	
	func allsongsfromartist(song: Song) -> [Song] {
		let fetch:NSFetchRequest<Song> = Song.fetchRequest()
		fetch.predicate 	= NSPredicate(format: "artist == %@", song.artist!)
		let sorter 		= NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		//		fet.predicate 	= NSPredicate(format: "song != %@", "nil")
				fetch.sortDescriptors = [sorter]
//			fetch.fetchLimit 	= 1
		let array = try? pc.viewContext.fetch(fetch)

		return array!
	}
}


private extension SongManager {
	
	func flowcoverart () {
		self.coverlimit 	= [] // reset cover limit
		
		var char		 	= ""
		var row 			= CGFloat(1)
		var column 			= CGFloat(1)
		var colnode 		= makeColumn(name: "col-" + column.description)
		colnode.position.x 	= column
		
		for song in sorted {
			let tchar 	= (song.value(forKeyPath: sorting.value()) as! String).first!.uppercased().folding(options: .diacriticInsensitive, locale: .current)
			if char == "" {
				char = tchar
			}
			if tchar == char {
				row -= 1
			}else{
				self.coverlimit.append(row)
				char 				= tchar
				row 				= 0
				column 				+= 1
				colnode 			= makeColumn(name: "col-" + column.description)
				colnode.position.x 	= column
			}
			let cover			= covers.first(where: {$0.id == song.uuid})
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
