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

class RowCall {
	var index 	= 0
	var row 	= 0
	var col 	= 0
}

let menutext = MenuText()

/// Retrieves Song information from coredata and creates album art for menu display
class SongManager {
	/// selected album always has the record component
	var songcount 	= 0
	var loc 		= RowCall()
	let record 		= RecordComp()
	let stars 		= StarsComp()
	var selected 	= SongComp(song: Song())
	var songenties 	= Set<GKEntity>()
	/// collection of song components
	///
	/// should not be sorted because it is access by Index
	var songsystem 	= GKComponentSystem<SongComp>(componentClass: SongComp.self)
	var colsystem 	= GKComponentSystem<ColumnComp>(componentClass: ColumnComp.self)
	let noart		= NSImage(named: "noart")
	/// the scnnodes containing a row of covers
	var sortkeypath:SortKeypath = .song
	var sorting:SortKeypath 	= .song
	/// array of ordered Stats used to arrange covers
	/// - kept and reused trhoughout life of game
	/// - updated every time user sorts music
	var sorted = [Song]()
	/// array of the CoverArt (scnnodes with UUID)
	/// - Loaded once at start, can take a while to build
	/// - Needs to be rebuilt if cataloging songs again
	var covers = [CoverArt]()
	
	/// Creates cover art and displays progress for songs in the core library arranged by Artist
	///
	/// Called at loading time once and only once
	private func createcovers (songs: [Song]) {
		covers = []
		var count = sorted.count
		let total = CGFloat(count)
		var countup = 1
		for song in songs {
			count 	-= 1
			countup += 1
			noice.alpha = CGFloat(countup) / total
			loadcount.text = String(format: "%04d", count)
			
			let entity = GKEntity()
			let songcomp = SongComp(song: song)
			// assign entity to the covernode so it can be reference by the frusturm
			songcomp.cover.entity = entity
			entity.addComponent(songcomp)
			songsystem.addComponent(foundIn: entity)
			songenties.insert(entity)
		}
	}
	
	/// camera base culling of cover art
	/// - Parameter covers: reveals cover art if within camera frustrum
	func revealcoverart(covers: [SCNNode]) {
		for cover in covers {
			addcoverarttonode(cover: cover)
		}
	}
	
	func addcoverarttonode(cover:SCNNode) {
		if let entity = cover.entity {
			if cover.geometry?.firstMaterial?.diffuse.contents != nil {return}
			if let song = entity.component(ofType: SongComp.self)?.song {
				let arturl = song.trackOf?.value(forKey: "albumArt") as! URL
				let art:NSImage = NSImage (byReferencing: arturl)
				if art.isValid {
					cover.geometry?.firstMaterial?.diffuse.contents = art
				}else{
					cover.geometry?.firstMaterial?.diffuse.contents = noart
				}
			}
		}
	}
	
	/// Initializes Coverflow, run only once at beginning of game
	func coverflow () {
		sorted 	= fetchSongs(sortBy: sortkeypath.value())

//		songenties.removeAll()
		
		
		createcovers(songs: sorted)

		if !sorted.isEmpty{
			flowcoverart()
		}
	}
	
	/// Sorts Album Art by given KeyPath
	///
	/// - Parameter keypath: path to sorting value for Stat
	func reflow (sortedBy keypath: SortKeypath) {
		
		if songsystem.components.isEmpty { return }
		
		if sortkeypath ==  keypath { return }
		if keypath == .artist { sorting = .artist} else {sorting = .song}
		sortkeypath 		= keypath
//		let tempcontainer 	= movecoverstotempcol()
		
		// if sorting requires stat switch fetch method
		if keypath == .stars {
			sorted = fetchSongs(sortByStat: keypath.value())
		} else {
			sorted = fetchSongs(sortBy: keypath.value())
		}
		
		for child in covernode.childNodes {
			child.removeFromParentNode()
		}
		
		for comp in songsystem.components {
			songsystem.removeComponent(comp)
		}
		
		for col in colsystem.components {
			colsystem.removeComponent(col)
		}
		/// add songcomponents back to system in the right order
		for song in sorted {
			if let entity = songenties.first(where: {$0.component(ofType: SongComp.self)?.song == song}){
				songsystem.addComponent(foundIn: entity)
			}
		}
		print("about to reflow")
		flowcoverart()
		smanager.updatesongselection(newsong: smanager.selected, state: .selected)
//		tempcontainer.removeFromParentNode()
	}
	
	/// DEPRICATED - Retrieves list of Stats ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Stats sorted by Artist or Album
	func fetchStats (sortBy: String) -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let sorter 		= NSSortDescriptor(key: sortBy, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		let second 		= NSSortDescriptor(key: "song.title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
		fet.predicate 		= NSPredicate(format: "song != %@", "nil")
		fet.sortDescriptors = [sorter, second]
//		fet.fetchLimit 		= 100
		let array 			= try? pc.viewContext.fetch(fet)
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
		do {
			let songarray = try pc.viewContext.fetch(delete)
			for s in songarray {
				pc.viewContext.delete(s)
			}
			try pc.viewContext.save()
		}catch let err as NSError {
			print(err)
		}
	}
	
	func deletealbums() {
		let delete:NSFetchRequest<Album> = Album.fetchRequest()
		do {
			let album = try pc.viewContext.fetch(delete)
			for s in album {
				pc.viewContext.delete(s)
				try pc.viewContext.save()
			}
		}catch let err as NSError {
			print(err)
		}
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
		deletealbums()
		let sfinder = SongFinder()
		sfinder.catalogSongs()
//		coverflow()
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
	
	func selectfirstsong() -> Bool {
		if songsystem.components.isEmpty {
			return false
		}
		selected = songsystem[0]
		selected.state = .selected
		TextureMover.shared.updatechartericon(icon: selected.song.icon!)
		return true
	}
	
	/// makes a record selection with animation
	/// - Parameter newsong: the song to be selected
	///
	/// a different seleciton function needs to be made without the animating
	func updatesongselection(newsong: SongComp, state: SelState) {
	
		let oldcolumn = selected.entity?.component(ofType: ColumnComp.self)
		
		selected.state = .notselected
		
		selected = newsong
		newsong.state = state
		
//		print(selected.song.folder)
		TextureMover.shared.updatechartericon(icon: newsong.song.icon!)
		
		if newsong.song.length > 0 {
			var secs = DateComponents()
			secs.second = Int(newsong.song.length)
			labelt.text = format.string(for: secs)
		}else{
			labelt.text = ""
		}
		
		let column = selected.entity?.component(ofType: ColumnComp.self)
		
		if -column!.posx + 1 != covernode.position.x {
			
			covernode.removeAllActions()
			var posz:CGFloat = 0
			if state == .detailview {
				posz = -1.25
			}
			// find out if leap is really big
			let offset:CGFloat = column!.posx - oldcolumn!.posx
			if offset > 8 {
				//needs to travel to the end (move left)
				// first go off scren to the rigt
				covernode.runAction(SCNAction.move(to: SCNVector3(x: 5 , y: 0, z: posz), duration: 0.15)) {
					// then move everything all the way to the left to slide in gracefully
					covernode.position.x = -CGFloat(self.colsystem.components.count + 1)
					covernode.runAction(SCNAction.move(to: SCNVector3(x: -column!.posx + 1 , y: 0, z: posz), duration: 0.15))
//					self.frustrumreveal()
				}
			}else if offset < -8 {
				// needs to travel to begining
				covernode.runAction(SCNAction.move(to: SCNVector3(x: -CGFloat(self.colsystem.components.count + 1) , y: 0, z: posz), duration: 0.10)){
					covernode.position.x = 5
					// covernode has to moved sideways so update index
					covernode.runAction(SCNAction.move(to: SCNVector3(x: -column!.posx + 1 , y: 0, z: posz), duration: 0.2))
//					self.frustrumreveal()
				}
			} else {
				
				// covernode has to moved sideways so update index
				covernode.runAction(SCNAction.move(to: SCNVector3(x: -column!.posx + 1 , y: 0, z: posz), duration: 0.25))
			}
			oldcolumn?.node.position.z = 0
			loc.col = Int(column!.posx - 1)
			column!.highlight()
			oldcolumn?.unhilight()
		}
		column!.node.runAction(SCNAction.move(to: SCNVector3(x: column!.node.position.x, y: -selected.row, z: 0.25), duration: 0.125)){
			
			self.frustrumreveal()
		}
	}
	
	func moveselect(direction: Direction)  {
		var i = selected.index
		switch direction {
		case .left:
			if loc.col == 0 {
				i = colsystem.components.last!.index
			} else {
				i = colsystem[loc.col - 1].index
			}
			updatesongselection(newsong: songsystem[i], state: .selected)
			UpNext.shared.refreshlist(nexttitles: songrange(index: i))
		case .right:
			if loc.col == colsystem.components.count - 1 {
				i = colsystem.components.first!.index
			} else {
				i = colsystem.components[loc.col + 1].index
			}
			updatesongselection(newsong: songsystem[i], state: .selected)
			UpNext.shared.refreshlist(nexttitles: songrange(index: i))
			break
		case .down:
			i += 1
			var x = i + 3
			if songcount - x <= 0 {
				x -= songcount
			}
			if i == songcount { i = 0 }
			UpNext.shared.scrolldown(title: songsystem[x].song.title!)
			updatesongselection(newsong: songsystem[i], state: .selected)
		case .up:
			var x = i - 4
			if x < 0 {
				x += songcount
			}
			if i == 0 { i = songcount }
			i -= 1
			UpNext.shared.scrollup(title: songsystem[x].song.title!)
			updatesongselection(newsong: songsystem[i], state: .selected)
		}
	}
	
	func songrange(index: Int) -> [String] {
		var titles = [String]()
		var base = index - 4
		for _ in 0...6 {
			base += 1
			if base < 0 {
				base += songcount
			}
			if base >= songcount {
				base = base - songcount
			}
			titles.append(songsystem[base].song.title!)
		}
		return titles
	}
	
	
}


private extension SongManager {	
	/// lays out cover art into a grid of columns
	func flowcoverart () {
		
		var index 			= 0
		var char		 	= ""
		var row 			= CGFloat(1)
		var column 			= CGFloat(1)
		/// this is the first column used always
		var colnode 		= makeColumn(name: "col-" + column.description)
		var columncomp 		= ColumnComp(column: column, node: colnode)
		colsystem.addComponent(columncomp)
		colnode.position.x 	= column
		
		print(sorted.count)
		print(colsystem.components.count)
		
		for comp in songsystem.components {
//			print(comp)
			/// first character of the song Title, Artist et depending of the "sorting value"
			var tchar 	= (comp.song.value(forKeyPath: sorting.value()) as! String).first!.uppercased().folding(options: .diacriticInsensitive, locale: .current)
			// remap the first characters
			switch tchar {
			case "0"..."9":
				tchar = "#"
			case "A"..."Z":
				break
			default:
				tchar = "?"
				break;
			}
			// this should run only once
			if char == "" {
				columncomp.addletter(char: tchar)
				char = tchar
			}
			// if tchar is still the same, we add a new row to the same colum
			if tchar == char {
				row -= 1
			// else we make a new comlum + new component
			}else{
				char 				= tchar
				row 				= 0
				column 				+= 1
				// creat a new column and comp
				colnode 			= makeColumn(name: "col-" + column.description)
				columncomp 			= ColumnComp(column: column, node: colnode)
				columncomp.index 	= index
				colsystem.addComponent(columncomp)
				colnode.position.x 	= column
				columncomp.addletter(char: char)
			}
			comp.index = index
			index += 1
			comp.cover.position.y = row
			comp.row = row
			colnode.addChildNode(comp.cover)
			comp.entity?.addComponent(columncomp)
			// check to see if cover is on screen at start
			if row > -3 && column < 7 {
				addcoverarttonode(cover: comp.cover)
			}
		}
		songcount = songsystem.components.count
//		resetcolumns()
	}
	
	func createstats(uuid: String) -> Stats? {
		let stat = Stats(context: pc.viewContext)
		let song = fetchSongById(id: uuid)
		song.addToStats(stat)
		User.current.player.addToStats(stat)
		stat.songid 	= song.uuid
		stat.pindex		= User.current.player.index
		try? pc.viewContext.save()
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
	
	func makeColumn () -> SCNNode {
		let column 		= SCNNode()
		
		covernode.addChildNode(column)
		return column
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
	
	func frustrumreveal() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
			let covers = mainView.nodesInsideFrustum(of: frustum!)
			smanager.revealcoverart(covers: covers)
		}
	}
}

let smanager 	= SongManager()
