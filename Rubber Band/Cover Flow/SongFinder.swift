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


/// Reads and parses ini files from song folders and adds them to coredata catalog
/// - attention: does not manage songs once inside core data
/// - precondition: requires pc (persistent container) to be defined already
/// - bug: Will duplicate data if run more than once without deleting current data
class SongFinder {
	//MARK: - Vars
	/// Players home directory on the computer
	let homeDirectory = NSHomeDirectory()
	/// location of music folder/folders
	let library:String
	/// instance of FileManager
	let fileManager = FileManager()
	let libraryurl: URL
	//MARK: - Inits
	/// init with default song path "user/rubberband/"
	init() {
		self.library = self.homeDirectory.description + "/Music/noice/"
		fileManager.changeCurrentDirectoryPath(self.library)
		self.libraryurl = URL(fileURLWithPath: self.library)
	}
	
	/// init with a specified path for music folder
	///
	/// - Parameter path: url path to the music folder
	init(path: String){
		self.library = path
		self.libraryurl = URL(fileURLWithPath: self.library)
		fileManager.changeCurrentDirectoryPath(self.library)
	}
	
	//MARK: - Public Funcs
	///	parses data from ini files and adds them to Catalog (coredata)
	///
	/// This is to catalog all songs in the library
	func catalogSongs () {
		/// array of paths to song folders
		if let inis = songIniPaths() {
			catalogSongs(inis: inis)
		}
	}
	
	/// parses data from ini files and adds them to Catalog (coredata)
	/// - Parameter inis: A list of paths to ini files
	func catalogSongs (inis: [String]) {
		/// array of songs to be added to catalog
		var songs = [String:Song]()
		/// array of albums to be added to catalog
		var albums = [String:Album]()

		for ini in inis {
			/// managed object Album to be inserted into pc context
			var album: Album
			let songmeta = iniToMeta(iniPath: ini)
			let song = newsongfrominipath(songmeta: songmeta)
			
			addstattosong(song: song)

			// this combines artis + album to indentify unique albulms
			let albumID = songmeta[SongData.artist]!.lowercased() + songmeta[SongData.album]!.lowercased()
			
			// look for album in current album dictionary else make a new album
			if let al = albums[albumID] {
				album = al
			}else{
				album = Album(context: pc.viewContext)
				album.name = songmeta[SongData.album]
				album.albumArt 	= song.folder?.appendingPathComponent("album.png")
			}
			
			song.trackOf = album
			songs[song.title!] = song
			albums[albumID] = album
		}
		
		do{
			try pc.viewContext.save()
		} catch let err as NSError {
			print(err)
		}
	}
	
	enum Status {
		case noinis, nosongs, nonothing
	}
	
	/// checks if library folder has been modified
	///
	/// does not check if inis have been modified
	func librarymodified () {
		do {
			let modate = try fileManager.attributesOfItem(atPath:library)[.modificationDate]
			let config = Defaults.config()
			
			if let libdate = config.libupdate {
				if modate as! Date > libdate {
				// library has been modified
					print("library changed")
					scanlibrarychanges(date: libdate)
					savedate(config: config)
					return
				}
				print("no changes to library")
				return // library hasn't changed do nothing
			}
			// there is no saved date, catalog library for the first time
			print("this is first time scanning library")
			smanager.deleteCatalog()
			catalogSongs()
			savedate(config: config)
		} catch let err as NSError {
			print(err)
		}
	}
	
	func savedate(config: Config) {
		config.libupdate = Date()
		do{
			try pc.viewContext.save()
		} catch let err as NSError {
			print(err)
		}
	}
	
	func scanlibrarychanges (date: Date) {
		if let inipaths = songIniPaths() {
			if let songs = fetchaallsongs() {
				for song in songs {
					// delete songs from database if folder does not exist
					if !fileManager.fileExists(atPath: (song.folder?.appendingPathComponent("song.ini").path)!) {
						print("deleting ", song.folder?.path ?? "no path")
						pc.viewContext.delete(song)
						do{
							try pc.viewContext.save()
						} catch {
							print("could not delete songs")
						}
					}
				}
				// add songs not found in library
				scanfornewsongs(inis: inipaths)
				return
			}
			// no songs found in coredata
			print("cataloging")
			catalogSongs(inis: inipaths)
			return
		}
		// no ini paths found, delete
		print("deleeting your shit")
		smanager.deleteCatalog()
	}
	
	/// reference library ini files against cataloged song directories to find new ones
	func scanfornewsongs() {
		if let inipaths = songIniPaths() {
			scanfornewsongs(inis: inipaths)
		}
	}
	
	/// reference library ini files against cataloged song directories to find new ones
	func scanfornewsongs(inis: [String]) {
		for path in inis {
			let pathstring 	= path.components(separatedBy: "song.ini")[0]
			let url = URL(fileURLWithPath: pathstring)
			if let _ = fetchsongbyfolder(folder: url.absoluteString) {
			} else {
				print("song not found, add to library")
				addsongtocatalog(inipath: path)
			}
		}
		print("done scanning")
	}
	
	func updatemetadata() {
		if let inis = songIniPaths() {
			let date = Defaults.config().libupdate ?? Date()
			scanforinichanges(inis: inis, date: date)
		}
	}
	
	/// compares Song.modified to ini file modification date to check for changes
	/// - Parameters:
	///   - songs: list of Song
	///   - date: Date the music library was last updated
	func scanforinichanges(inis: [String], date: Date) {
		for inipath in inis {
			do {
				let modate 	= try fileManager.attributesOfItem(atPath:inipath)[.modificationDate]
				if modate as! Date > date {
					let pathstring 	= inipath.components(separatedBy: "song.ini")[0]
					let url = URL(fileURLWithPath: pathstring)
					if let song = fetchsongbyfolder(folder: url.absoluteString) {
						let meta = iniToMeta(iniPath: inipath)
						mapSongMetatoSong(song: song, meta: meta)
					}
				}
			} catch let err as NSError {
				print(err)
			}
		}
		do{
			try pc.viewContext.save()
		} catch let err as NSError {
			print(err)
		}
	}
}

private extension SongFinder {
	//MARK: - Private Funcs
	func libmoddate() -> Date? {
		do {
			let modate 	= try fileManager.attributesOfItem(atPath:library)[.modificationDate]
			return (modate as! Date)
		} catch let err as NSError {
			print(err)
			return nil
		}
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
		fet.predicate = NSPredicate(format: "name == %@", songmeta[.album]!)
		let albums = try? pc.viewContext.fetch(fet)
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
		let stata = fetchstats()
		let stat = stata.first(where: {$0.songid == song.uuid})
		
		if stat != nil {
			stat!.song = song
			stat!.songid = song.uuid
			stat!.pindex = 0
			stat!.setby = User.current.player
		}
	}
	
	/// creates a new song in coredata from midi file path
	/// - Parameter inipath: the path string to the ini file
	func newsongfrominipath(songmeta: SongMeta) -> Song {
		let song = Song(context: pc.viewContext)
			song.tier = Tiers(context: pc.viewContext)
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
				song.artist = s.value
			case .name:
				song.title = s.value
			case .year:
				if s.value.count == 4{
					song.year = Int16(s.value)!
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
				song.genre = s.value
			case .directory:
				song.folder = URL(fileURLWithPath: s.value)
			case .diff_drums:
				song.tier?.drums = Int16(s.value) ?? -1
			case .diff_guitar:
				song.tier?.guitar = Int16(s.value) ?? -1
			case .diff_bass:
				song.tier?.bass = Int16(s.value) ?? -1
			case .diff_keys:
				song.tier?.keys = Int16(s.value) ?? -1
			case .delay:
				if let delay = Double(s.value){
					song.delay = delay * 0.001
				}else{
					song.delay = 0
				}
			case .icon:
				song.icon = s.value.lowercased()
			case .charter:
				song.charter = s.value
			case .loading_phrase:
				song.phrase = s.value
			case .song_length:
				if let sec = Double(s.value){
					song.length = sec / 1000
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
	
	//MARK: Fetching
	/// Fetches song by URL.string
	/// - Parameter folder: folder URL in string format
	func fetchsongbyfolder(folder: String) -> Song? {
		let fetch:NSFetchRequest<Song> = Song.fetchRequest()
		fetch.predicate = NSPredicate(format: "folder == %@", folder)
		fetch.fetchLimit = 1
		let array = try? pc.viewContext.fetch(fetch)
		if array!.isEmpty {
			return nil
		}
		return array![0]
	}
	
	func fetchaallsongs() -> [Song]? {
		let request:NSFetchRequest<Song> = Song.fetchRequest()
		do {
			let songs = try pc.viewContext.fetch(request)
			if songs.count == 0 { return nil}
			return songs
		}catch let err as NSError {
			print(err)
			return nil
		}
	}
	
	func fetchstats () -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let array = try? pc.viewContext.fetch(fet)
		return array!
	}
	
	//MARK: ini Files
	/// Finds all ini files in all subdirectories
	///
	/// - Returns: an Array of paths to the song folders containing ini files
	func songIniPaths () -> [String]? {
		if let enumPaths = fileManager.enumerator(atPath: self.library){
			let	allPaths = enumPaths.allObjects as! [String]
			let songInis = allPaths.filter{$0.contains("song.ini")}
			if songInis.count != 0 {
				return songInis
			}
		}
		return nil
	}
	
	/// opens ini file and returns lines containing " = " as an array
	///
	/// - Parameter path: path to ini file
	/// - Returns: array of parameters as string ("artist = so and so")
	func songIniLines (path: String) -> [String] {
		var lines = [String]()
		print("path: ", path)
		
		let url = libraryurl.appending(component: path)

		if let filestring = String.loadcleanini(at: url) {
			filestring.enumerateLines{l, _ in lines.append(l)}
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
		let thex = String.init(format: "%0x", song.title!.lowercased().hash).padding(toLength: 8, withPad: "0", startingAt: 0)
		var ahex = String.init(format: "%0x", song.artist!.lowercased().hash).padding(toLength: 8, withPad: "0", startingAt: 0)
			ahex.insert("-", at: ahex.index(ahex.startIndex, offsetBy: 4))
		let yhex = String.init(format: "%0x", song.year).padding(toLength: 4, withPad: "0", startingAt: 0)
		let chex = String.init(format: "%0x", charter.hash).padding(toLength: 8, withPad: "0", startingAt: 0)
		let ichex = String.init(format: "%0x", song.icon!.hash).padding(toLength: 4, withPad: "0", startingAt: 0)
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

