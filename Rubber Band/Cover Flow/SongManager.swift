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

protocol SongManagerDelegate {
	func newsongselected(song: Song)
}

/// Directions the player press to navigate menu
///
/// - left: player pressed left
/// - right: player pressed right
/// - up: player pressed up
/// - down: player pressed down
enum Direction {
	case left, right, up, down
}

let loadingscreen 	= SKScene(fileNamed: "LoadingScreen.sks")
let loadcount 		= loadingscreen?.childNode(withName: "loadcount") as! SKLabelNode
let noice 			= loadingscreen?.childNode(withName: "noice") as! SKSpriteNode

let menuOverlay 	= SKScene(fileNamed: "titleDisplay.sks")

let menuScene 		= SCNScene(named: "art.scnassets/scns/menu_song.scn")!
var covernode 		= menuScene.rootNode.childNode(withName: "coverflow", recursively: true)!

struct MenuText {
	let detailnode 	= menuScene.rootNode.childNode(withName: "details", recursively: true)
	init(){
	}
}

class ColCol {
	var index 	= 0
	var row 	= 0
	var col 	= 0
}

let menutext = MenuText()


/// Retrieves Song information from coredata and creates album art for menu display
class SongManager {
	
	//MARK: - Vars
	/// selected album always has the record component
	var delegate	: SongManagerDelegate?
	var songcount 	= 0
	var loc 		= ColCol()
	let noart		= NSImage(named: "noart")
	
	//MARK: ECS
	let record 		= RecordComp()
	let stars 		= StarsComp()
	var selected 	= SongComp(song: Song())
	var songenties 	= Set<GKEntity>()
	
	/// collection of song components
	///
	/// should not be sorted because it is access by Index
	var songsystem 	= GKComponentSystem<SongComp>	(componentClass: SongComp.self)
	var colsystem 	= GKComponentSystem<ColumnComp>	(componentClass: ColumnComp.self)
	
	/// the scnnodes containing a row of covers
	var sortkeypath:SortKeypath = .song
	var sorting:SortKeypath 	= .song
	
	//MARK: Lists
	/// array of ordered Stats used to arrange covers
	/// - kept and reused trhoughout life of game
	/// - updated every time user sorts music
	var sorted = [Song]()
	var shuffled = [SongComp]()
	
	/// array of the CoverArt (scnnodes with UUID)
	/// - Loaded once at start, can take a while to build
	/// - Needs to be rebuilt if cataloging songs again
	var covers = [CoverArt]()
	
	//MARK: -  Funcs
	/// Creates cover art and displays progress for songs in the core library arranged by Artist
	///
	/// Called at loading time once and only once
	private func createcovers (songs: [Song]) {
		covers 		= []
		var count 	= songs.count
		let total 	= CGFloat(count)
		var countup = 1
		for song in songs {
			count -= 1
			countup += 1
			noice.alpha 	= CGFloat(countup) / total
			loadcount.text 	= String(format: "%04d", count)
			let entity 		= GKEntity()
			let songcomp 	= SongComp(song: song)
			// assign entity to the covernode so it can be reference by the frusturm
			songcomp.cover.entity = entity
			entity.addComponent(songcomp)
			songsystem.addComponent(foundIn: entity)
			songenties.insert(entity)
		}
		shuffled = songsystem.components.shuffled()
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
		let sfinder = SongFinder()
		
		sfinder.librarymodified()
		
		sorted = fetchSongs(sortBy: sortkeypath.value(), nil, nil)
	
		createcovers(songs: sorted)
		if !sorted.isEmpty{
			iconAtlas.preload {
				self.flowcoverart()
			}
		}
	}
	
	/// Sorts Album Art by given KeyPath
	///
	/// - Parameter keypath: path to sorting value for Stat
	func reflow (sortedBy keypath: SortKeypath) {
		
		if songsystem.components.isEmpty { return }
		
		if sortkeypath ==  keypath { return }
		if keypath == .artist { sorting = .artist} else {sorting = .song}
		sortkeypath = keypath
//		let tempcontainer 	= movecoverstotempcol()
		
		// if sorting requires stat switch fetch method
		if keypath == .stars {
			sorted = fetchSongs(sortByStat: keypath.value())
		} else {
			sorted = fetchSongs(sortBy: keypath.value(), nil, nil)
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

		flowcoverart()
		smanager.updatesongselection(newsong: smanager.selected, state: .selected)
	}
	
	//MARK: - Fetching
	/// DEPRICATED - Retrieves list of Stats ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Stats sorted by Artist or Album
	func fetchStats (sortBy: String) -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let sorter = NSSortDescriptor(
			key: sortBy,
			ascending: true,
			selector: #selector(NSString.localizedCaseInsensitiveCompare)
		)
		let second = NSSortDescriptor(
			key: "song.title",
			ascending: true,
			selector: #selector(NSString.localizedCaseInsensitiveCompare)
		)
		fet.predicate = NSPredicate(format: "song != %@", "nil")
		fet.sortDescriptors = [sorter, second]
		let array = try? pc.viewContext.fetch(fet)
		return array!
	}
	
	/// Retrieves list of Songs ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Songs sorted by Artist or Album
	func fetchSongs (sortBy: String, _ limit: Int?, _ ascending: Bool?) -> [Song] {
		let fet:NSFetchRequest<Song> = Song.fetchRequest()
		let sorter = NSSortDescriptor(
			key: sortBy,
			ascending: ascending ?? true,
			selector: #selector(NSString.localizedCaseInsensitiveCompare)
		)
		let second = NSSortDescriptor(
			key: "title",
			ascending: true,
			selector: #selector(NSString.localizedCaseInsensitiveCompare)
		)
		fet.sortDescriptors = [sorter, second]
		if limit != nil { fet.fetchLimit = limit!}
		let array = try? pc.viewContext.fetch(fet)
		print("ist me margaret")
		return array!
	}
	
	/// Retrieves list of Songs ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Songs sorted by Artist or Album
	func fetchSongs (sortByStat: String) -> [Song] {
		
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let sorter = NSSortDescriptor(
			key: sortByStat,
			ascending: true,
			selector: #selector(NSString.localizedCaseInsensitiveCompare)
		)
		let second = NSSortDescriptor(
			key: "song.title",
			ascending: true,
			selector: #selector(NSString.localizedCaseInsensitiveCompare)
		)
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
	}
	
	func allsongsfromartist(song: Song) -> [Song] {
		let fetch:NSFetchRequest<Song> = Song.fetchRequest()
		fetch.predicate 	= NSPredicate(format: "artist == %@", song.artist!)
		let sorter 			= NSSortDescriptor(
			key: "title",
			ascending: true,
			selector: #selector(NSString.localizedCaseInsensitiveCompare)
		)
			fetch.sortDescriptors = [sorter]
		let array = try? pc.viewContext.fetch(fetch)

		return array!
	}

//MARK: Song Selection
	/// makes a record selection with animation
	/// - Parameter newsong: the song to be selected
	///
	/// a different seleciton function needs to be made without the animating
	func updatesongselection(newsong: SongComp, state: SelState) {
	
		let oldcolumn 	= selected.entity?.component(ofType: ColumnComp.self)
		selected.state 	= .notselected
		selected 		= newsong
		newsong.state 	= state
		
		delegate?.newsongselected(song: selected.song)
		
		let column 		= selected.entity?.component(ofType: ColumnComp.self)
		rowcall.posx 	= -column!.posx + 1
		
		if column != oldcolumn {
			loc.col = Int(column!.posx - 1)
			column!.highlight()
			oldcolumn?.unhilight()
		}
		
		// update column vertically
		column!.node.runAction(SCNAction.move(to: SCNVector3(x: column!.node.position.x, y: -selected.row, z: 0.25), duration: 0.125)){
			self.frustrumreveal()
		}
		UpNext.shared.rowcount(count: column!.node.childNodes.count, row: Int(-selected.row))
	}
	
	func selectrandom() {
		if let comp = shuffled.last {
//			if song has no tier in the current isntrument, remove from list and select new random song
			if User.current.instrument.gettier(comp.song) == -1 {
				shuffled.removeLast()
				selectrandom()
				return
			}
			updatesongselection(newsong: comp, state: .detailview)
		} else {
//			if shuffled is empty reassign all components again
			shuffled = songsystem.components.shuffled()
			selectrandom()
		}
	}
	
	func selectrandom(_ artist: String) {
		if let song = shuffled.first(where: {$0.song.artist == artist}) {
			updatesongselection(newsong: song, state: .detailview)
			return
		}
//		should i re-add the artist songs back to shuffled?
		let songsby = songsystem.components.filter {$0.song.artist == artist && $0 != selected}
		if songsby.isEmpty { return }
		updatesongselection(newsong: songsby.randomElement()!, state: .detailview)
	}
	
	func removefromshuffle() {
		if let index = shuffled.firstIndex(where: {$0 == selected}) {
			shuffled.remove(at: index)
		}
	}
	
	func moveselector(direction: Direction)  {
		var i = selected.index
		Jukebox.shared.stop()
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
	
	func selectfirstsong() -> Bool {
		if songsystem.components.isEmpty {
			return false
		}
		selected 		= songsystem[0]
		selected.state 	= .selected
		
		// texturemover needs to be called so it instantiates or else delegate doesn't work
		TextureMover.shared.updatechartericon(icon: selected.song.icon ?? "blank")
		updatesongselection(newsong: selected, state: .selected)
		let column 	= selected.entity?.component(ofType: ColumnComp.self)
		column!.highlight()
		return true
	}
	
	//MARK: UpNext Helper
	/// returns a lis of songs tiles for the UpNext list
	/// - Parameter index: The currently selected Index
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
	
	/// adds cover art to art within frustrum camera after a 0.15 second delay
	func frustrumreveal() {
		frustrumreveal(after: 0.15)
	}
	/// adds cover art to art within frustrum camera after a given delay
	/// - Parameter after: delay to wait for reveal
	func frustrumreveal(after: Double) {
		DispatchQueue.main.asyncAfter(deadline: .now() + after){
			let covers = mainView.nodesInsideFrustum(of: frustum!)
			smanager.revealcoverart(covers: covers)
		}
	}
}


//MARK: - Private Funcs
private extension SongManager {	
	/// lays out cover art into a grid of columns
	func flowcoverart () {
		
		var index 		= 0
		var char		 	= ""
		var row 			= CGFloat(1)
		var column 		= CGFloat(1)
		/// this is the first column used always
		var colnode 	= makeColumn(name: "col-" + column.description)
		var columncomp = ColumnComp(column: column, node: colnode)
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
				char 	= tchar
				row 	= 0
				column 	+= 1
				// creat a new column and comp
				colnode 			= makeColumn(name: "col-" + column.description)
				columncomp 			= ColumnComp(column: column, node: colnode)
				columncomp.index 	= index
				colsystem.addComponent(columncomp)
				colnode.position.x = column
				columncomp.addletter(char: char)
			}
			comp.index 					= index
			index 						+= 1
			comp.cover.position.y 	= row
			comp.row 					= row
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
	
	/// camera base culling of cover art
	/// - Parameter covers: reveals cover art if within camera frustrum
	func revealcoverart(covers: [SCNNode]) {
		for cover in covers {
			addcoverarttonode(cover: cover)
		}
	}
}

let smanager = SongManager()
