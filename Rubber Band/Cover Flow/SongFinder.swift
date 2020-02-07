//
//  SongFinder.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/2/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

//let songfinder = SongFinder(path: home+"/rubberband/")
//let songlist = songfinder.songList()

let labeln 			= menuOverlay?.childNode(withName: "name") 		as! SKLabelNode
let labela 			= menuOverlay?.childNode(withName: "artist") 	as! SKLabelNode
let labelt 			= menuOverlay?.childNode(withName: "time") 		as! SKLabelNode
let labeldetails 	= menuOverlay?.childNode(withName: "details")!
let othersongsg 	= menuOverlay?.childNode(withName: "relatedsongs")!
let othersongname 	= othersongsg?.childNode(withName: "othersong")	as! SKLabelNode
let labelphrase 	= labeldetails?.childNode(withName: "phrase") 	as! SKLabelNode
let labelcharter 	= labeldetails?.childNode(withName: "charter") 	as! SKLabelNode
let labelalbum	 	= labeldetails?.childNode(withName: "album") 	as! SKLabelNode
let labelyear	 	= labeldetails?.childNode(withName: "year") 	as! SKLabelNode
let labelgenre	 	= labeldetails?.childNode(withName: "genre") 	as! SKLabelNode
let labelDiff 		= labeldetails?.childNode(withName: "difficulty") as! SKLabelNode
let lebelInst 		= labeldetails?.childNode(withName: "instrument") as! SKLabelNode
let labelicon 		= menuOverlay?.childNode(withName: "icon") 		as! SKSpriteNode


/// placeholder stat for songs without stats
//var selectedStat = Stats(context: pc.viewContext)
//let player1 = setplayer(name: "guest")


/// Reads and parses ini files from song folders and adds them to coredata catalog
/// - attention: does not manage songs once inside core data
/// - precondition: requires pc (persistent container) to be defined already
/// - bug: Will duplicate data if run more than once without deleting current data
class SongFinder {
	/// Players home directory on the computer
	let homeDirectory 	= NSHomeDirectory()
	/// location of music folder/folders
	let library:String
	/// instance of FileManager
	let fileManager 	= FileManager()
	/// init with default song path "user/rubberband/"
	init() {
		self.library = self.homeDirectory.description + "/Music/noice/"
		fileManager.changeCurrentDirectoryPath(self.library)
		print(self.library)
	}
	
	/// init with a specified path for music folder
	///
	/// - Parameter path: url path to the music folder
	init(path: String){
		self.library = path
		fileManager.changeCurrentDirectoryPath(self.library)
	}
	
	///	parses data from ini files and adds them to Catalog (coredata)
	///
	/// This is to catalog all songs in the library
	func catalogSongs () {
		/// array of paths to song folders
		let inis 	= songIniPaths()
		/// array of songs to be added to catalog
		var songs 	= [String:Song]()
		/// array of albums to be added to catalog
		var albums 	= [String:Album]()

		for ini in inis! {
			/// managed object Album to be inserted into pc context
			var album:Album
			
			let songmeta = iniToMeta(iniPath: ini)
			
			let song	= newsongfrominipath(songmeta: songmeta)
			addstattosong(song: song)

//				this combines artis + album to indentify unique albulms
			let albumID = songmeta[SongData.artist]!.lowercased() + songmeta[SongData.album]!.lowercased()
			
			// look for album in current album dictionary else make a new album
			if let al = albums[albumID] {
				album 			= al
			}else{
				album 			= Album(context: pc.viewContext)
				album.name 		= songmeta[SongData.album]
				album.albumArt 	= song.folder?.appendingPathComponent("album.png")
			}
			
			song.trackOf 		= album
			
			songs[song.title!] 	= song
			albums[albumID] 	= album
		}
		
		do{
			try pc.viewContext.save()
		} catch let err as NSError {
			print(err)
		}
	}
	
	/// refernce library ini files against cataloged song directories to find new ones
	func scanfornewsongs() {
		if let inipaths = songIniPaths() {
			for path in inipaths {
				let pathstring = path.components(separatedBy: "song.ini")[0]
				let url = URL(fileURLWithPath: pathstring)
				if !fetchsongbyfolder(folder: url.absoluteString) {
					print("adding:", pathstring, "to catalog")
					addsongtocatalog(inipath: path)
				}
			}
			print("done scanning")
		}
	}
	
	/// compares Song.modified to ini file modification date to check for changes
	func scanforinichanges() {
		if let songs = fetchaallsongs() {
			let finder = FileManager()
			for s in songs {
				do {
					let inipath = s.folder!.appendingPathComponent("song.ini").path
					let modate = try finder.attributesOfItem(atPath:inipath)[.modificationDate]
					if modate as! Date > s.modfied! {
						let meta = iniToMeta(iniPath: inipath)
						mapSongMetatoSong(song: s, meta: meta)
						s.trackOf?.name = meta[.album]
						do{
							try pc.viewContext.save()
						} catch let err as NSError {
							print(err)
						}
					}
					
				} catch let err as NSError {
					print(err)
				}
			}
			print("done scanning for ini changes")
		}
	}
}

private extension SongFinder {
	
	func fetchaallsongs() -> [Song]? {
		let request:NSFetchRequest<Song> = Song.fetchRequest()
		do {
			return try pc.viewContext.fetch(request)
		}catch let err as NSError {
			print(err)
		}
		return nil
	}
	
	func addsongtocatalog(inipath: String) {
		let songmeta = iniToMeta(iniPath: inipath)
		let song = newsongfrominipath(songmeta: songmeta)
		addstattosong(song: song)
		if let album = getsongalbum(songmeta: songmeta) {
			song.trackOf = album
		} else {
			song.trackOf = Album(context: pc.viewContext)
			song.trackOf?.name = songmeta[.album]
			song.trackOf?.albumArt = song.folder?.appendingPathComponent("album.png")
		}
		do{
			try pc.viewContext.save()
		} catch let err as NSError {
			print(err)
		}
	}
	
	/// Returns existing album, or makes a new one
	/// - Parameter songmeta: SongMeta
	func getsongalbum(songmeta: SongMeta) -> Album? {
		let fet:NSFetchRequest<Album> = Album.fetchRequest()
		fet.predicate 	= NSPredicate(format: "name == %@", songmeta[.album]!)
		let albums 		= try? pc.viewContext.fetch(fet)
		if !albums!.isEmpty {
			for a in albums! {
				for song in a.contains as! Set<Song> {
					if song.artist == songmeta[.artist] {
						return a
					}
				}
			}
		}
		return nil
	}
	
	/// loots for existing stats and links it to song if any
	/// - Parameter song: the song to loot for
	func addstattosong (song: Song) {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
//		fet.fetchLimit = 1
		fet.predicate = NSPredicate(format: "songid == %@", song.uuid!.uuidString)
//		fet.predicate = NSPredicate(format: "pindex == %@", User.current.player.index.description)
		let stats = try? pc.viewContext.fetch(fet)
		if stats!.count == 1 {
//			print("found", song.title, song.uuid, stats![0].songid)
			stats![0].song = song
		}
	}
	
	/// Loots fro a stat matching this song id also set by the current user
	/// - Parameter song: Song Entity
	func findstatforsong(song: Song) {
		let stata 	= fetchstats()
		let stat = stata.first(where: {$0.songid == song.uuid})
		
		if stat != nil {
			stat!.song			= song
			stat!.songid		= song.uuid
			stat!.pindex		= 0
			stat!.setby			= User.current.player
		}
	}
	
	/// creates a new song in coredata from midi file path
	/// - Parameter inipath: the path string to the ini file
	func newsongfrominipath(songmeta: SongMeta) -> Song {
		let song 			= Song(context: pc.viewContext)
			song.tier 		= maketier()
			mapSongMetatoSong(song: song, meta: songmeta)
		return song
	}
	
	
	/// maps data from ini SongMeta to a Song
	/// - Parameter song: song to be updated
	/// - Parameter meta: SongMeta from ini
	func mapSongMetatoSong (song: Song, meta: SongMeta) {
		song.modfied = Date()
		for s in meta {
			switch s.key {
			case .artist:
				song.artist 	= s.value
			case .name:
				song.title 		= s.value
			case .year:
				if s.value.count == 4{
					song.year 	= Int16(s.value)!
				} else {
					let split = s.value.components(separatedBy: " ")
					
					if let year = Int16(split[0]){
						song.year = year
					}else{
						if let year = Int16(split.last!){
							song.year = year
						}else{
							song.year = 0
						}
					}
				}
			case .genre:
				song.genre 			= s.value
			case .directory:
				song.folder 		= URL(fileURLWithPath: s.value)
			case .diff_drums:
				song.tier?.drums 	= Int16(s.value) ?? -1
			case .diff_guitar:
				song.tier?.guitar 	= Int16(s.value) ?? -1
			case .diff_bass:
				song.tier?.bass 	= Int16(s.value) ?? -1
			case .diff_keys:
				song.tier?.keys 	= Int16(s.value) ?? -1
			case .delay:
				if let delay = Double(s.value){
					song.delay	= delay * 0.001
				}else{
					song.delay	= 0
				}
			case .icon:
				song.icon = s.value.lowercased()
			case .charter:
				song.charter = s.value
			case .loading_phrase:
				song.phrase = s.value
			case .song_length:
				if let sec = Double(s.value){
					song.length =  sec / 1000
				}
			case .preview_start_time:
				if let start = Double(s.value) {
					song.preview = start / 1000
				}
			default:
				break;
			}
		}
		song.uuid = uuidfrommeta(song: song)
	}
	
	/// Fetches song by URL.string
	/// - Parameter folder: folder URL in string format
	func fetchsongbyfolder(folder: String) -> Bool {
		let fetch:NSFetchRequest<Song> = Song.fetchRequest()
		fetch.predicate 	= NSPredicate(format: "folder == %@", folder)
		fetch.fetchLimit 	= 1
		let array = try? pc.viewContext.fetch(fetch)
		if array!.isEmpty {
			return false
		}
		return true
	}
	
	
	func fetchstats () -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
//		let sorter = NSSortDescriptor(key: sortBy, ascending: true)
//				fet.fetchLimit = 5
//		fet.predicate = NSPredicate(format: "song != %@", "nil")
//		fet.sortDescriptors = [sorter]
		let array = try? pc.viewContext.fetch(fet)
		return array!
	}
	
	func maketier() -> Tiers {
		return Tiers(context: pc.viewContext)
	}
	
	func fetchstat () -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let array = try? pc.viewContext.fetch(fet)
		return array!
	}
	
	/// Finds all ini files in all subdirectories
	///
	/// - Returns: an Array of paths to the song folders containing ini files
	func songIniPaths () -> [String]?{
		var songInis = [String]()
		if let enumPaths 	= fileManager.enumerator(atPath: self.library){
			let	allPaths 	= enumPaths.allObjects as! [String]
			songInis 		= allPaths.filter{$0.contains("song.ini")}
		}
		return songInis.sorted()
	}
	
	/// opens ini file and returns lines containing " = " as an array
	///
	/// - Parameter path: path to ini file
	/// - Returns: array of parameters as string ("artist = so and so")
	func songIniLines (path: String) -> [String] {
		var lines = [String]()
		do{
			let filestring = try String(contentsOfFile: path, encoding: String.Encoding.isoLatin1 )
			filestring.enumerateLines{l, _ in lines.append(l)}
		}catch let err as NSError {
			print(err)
		}
		return lines.filter{$0.contains(" = ")}
	}
	
	/// Converts string parameters from ini files to enum SongData
	///
	/// - Parameter iniPath: path to ini file
	/// - Returns: array of SongData
	func iniToMeta (iniPath: String) -> SongMeta {
		let inilines = songIniLines(path: iniPath)
		var songdata = SongMeta()
		songdata[SongData.directory] = iniPath.components(separatedBy: "song.ini")[0]
		
		for line in inilines {
			let splitdata = line.components(separatedBy: " = ")
			if let data = SongData(rawValue: splitdata[0]) {
				if splitdata[1] != " " && splitdata[1] != ""{
					songdata[data] = splitdata[1].trimmingCharacters(in: .whitespaces)
				}
			}
		}
		if songdata[SongData.album] == nil {
			songdata[SongData.album] = ""
		}
		return songdata
	}
	
	/// Create a UUID from song data to avoid duplicated songs
	/// - Parameter song: song entity stored in coredata
	/// - Parameter charter: group that charted the song
	func uuidfrommeta(song: Song) -> UUID {
		let charter = song.charter?.lowercased() ?? "null"
		let thex	= String.init(format: "%0x", song.title!.lowercased().hash).padding(toLength: 8, withPad: "0", startingAt: 0)
		var ahex	= String.init(format: "%0x", song.artist!.lowercased().hash).padding(toLength: 8, withPad: "0", startingAt: 0)
			ahex.insert("-", at: ahex.index(ahex.startIndex, offsetBy: 4))
		let yhex	= String.init(format: "%0x", song.year).padding(toLength: 4, withPad: "0", startingAt: 0)
		let chex	= String.init(format: "%0x", charter.hash).padding(toLength: 8, withPad: "0", startingAt: 0)
		let ichex 	= String.init(format: "%0x", song.icon!.hash).padding(toLength: 4, withPad: "0", startingAt: 0)
		let finalstring = "\(thex)-\(ahex)-\(yhex)-\(chex)\(ichex)"
		return UUID(uuidString: finalstring)!
	}
}

fileprivate typealias SongMeta = [SongData:String]
/// parameters/meta data contained in a Song
///
/// - name: title of song
/// - artist: artist name
/// - album: album title
/// - year: year album or song was released
/// - genre: genre
/// - multiplier_note: the value used to determine overall score
/// - diff_drums: drum difficulty
/// - diff_guitar: guitar difficulty
/// - directory: folder containing all files for this song
/// - video: video to be used as background
enum SongData: String {
	case name, artist, album, year, genre, diff_drums, diff_guitar, diff_bass, diff_keys, directory, video, delay, icon, charter, song_length, loading_phrase, preview_start_time
}

