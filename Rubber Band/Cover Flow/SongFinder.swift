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
let labelphrase 	= labeldetails?.childNode(withName: "phrase") 	as! SKLabelNode
let labelcharter 	= labeldetails?.childNode(withName: "charter") 	as! SKLabelNode
let labelalbum	 	= labeldetails?.childNode(withName: "album") 	as! SKLabelNode
let labelyear	 	= labeldetails?.childNode(withName: "year") 	as! SKLabelNode
let labelgenre	 	= labeldetails?.childNode(withName: "genre") 	as! SKLabelNode
let labelDiff 		= labeldetails?.childNode(withName: "difficulty") as! SKLabelNode
let labelicon 		= menuOverlay?.childNode(withName: "icon") 		as! SKSpriteNode

var selectedSong = Song()
var selectedStat = Stats()
//let player1 = setplayer(name: "guest")


/// Reads and parses ini files from song folders and adds them to coredata catalog
/// - attention: does not manage songs once inside core data
/// - precondition: requires pc (persistent container) to be defined already
/// - bug: Will duplicate data if run more than once without deleting current data
class SongFinder {
	/// Players home directory on the computer
	let homeDirectory 	= NSHomeDirectory()
	/// location of music folder/folders
	let songPath:String
	/// instance of FileManager
	let fileManager 	= FileManager()
	/// init with default song path "user/rubberband/"
	init() {
		self.songPath = self.homeDirectory.description + "/rubberband/"
		fileManager.changeCurrentDirectoryPath(self.songPath)
	}
	
	/// init with a specified path for music folder
	///
	/// - Parameter path: url path to the music folder
	init(path: String){
		self.songPath = path
		fileManager.changeCurrentDirectoryPath(self.songPath)
	}
	
	///	parses data from ini files and adds them to Catalog (coredata)
	func catalogSongs () {
		let stata 	= fetchstats()
		/// array of paths to song folders
		let inis 	= songIniPaths()
		/// array of songs to be added to catalog
		var songs 	= [String:Song]()
		/// array of albums to be added to catalog
		var albums 	= [String:Album]()
//		var stats	= [Stats]()
		for ini in inis! {
			/// managed object Song to be inserted into pc context
			let song 		= Song(context: pc.viewContext)
				song.tier 	= maketier()
			
			/// managed object Album to be inserted into pc context
			var album:Album
			
			var charter = ""
			
			if var songmeta = iniToMeta(iniPath: ini){
				songmeta[SongData.directory] = ini.components(separatedBy: "song.ini")[0]
				
//				this combines artis + album to indentify unique albulms
				let artalbum = songmeta[SongData.artist]!.lowercased() + songmeta[SongData.album]!.lowercased()
				
				for s in songmeta {
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
						charter = s.value.lowercased()
					case .loading_phrase:
						song.phrase = s.value
					case .song_length:
//						print(s.value)
						if let sec = Double(s.value){
//						let sec 	= Int16(s.value)
							song.length =  sec / 1000
						}
//						print(sec)
					case .preview_start_time:
						if let start = Double(s.value) {
							song.preview = start / 1000
						}
					default:
						break;
					}
				}
				
				if let al = albums[artalbum] {
					album 			= al
				}else{
					album 			= Album(context: pc.viewContext)
					album.name 		= songmeta[SongData.album]
					album.albumArt 	= song.folder?.appendingPathComponent("album.png")
				}
				
				song.uuid 			= uuidfrommeta(song: song, charter: charter)
				song.trackOf 		= album
				
				var stat = stata.first(where: {$0.songid == song.uuid})
				
				if stat == nil {
					stat			= Stats(context: pc.viewContext)
				}
//				update the list of songs and albums
				stat!.song			= song
				stat!.songid		= song.uuid
				stat!.pindex		= 0
				stat!.setby			= User.current.player
//				stats.append(stat)
				songs[song.title!] 	= song
				albums[artalbum] 	= album
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
	
	/// Finds all ini files in all subdirectories
	///
	/// - Returns: an Array of paths to the song folders containing ini files
	func songIniPaths () -> [String]?{
		var songInis = [String]()
		if let enumPaths 	= fileManager.enumerator(atPath: self.songPath){
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
	func iniToMeta (iniPath: String) -> [SongData:String]?{
		let inilines = songIniLines(path: iniPath)
		var songdata = [SongData:String]()
		
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
	
	func uuidfrommeta(song: Song, charter: String) -> UUID {
		let thex	= String.init(format: "%0x", song.title!.lowercased().hash).padding(toLength: 8, withPad: "0", startingAt: 0)
		var ahex	= String.init(format: "%0x", song.artist!.lowercased().hash).padding(toLength: 8, withPad: "0", startingAt: 0)
			ahex.insert("-", at: ahex.index(ahex.startIndex, offsetBy: 4))
		let yhex	= String.init(format: "%0x", song.year).padding(toLength: 4, withPad: "0", startingAt: 0)
		let chex	= String.init(format: "%0x", charter.hash).padding(toLength: 8, withPad: "0", startingAt: 0)
		var ichex 	= ""
		if let icon = Icon[song.icon!]{
			ichex = icon
		}else{
			ichex = "0000"
		}
		let finalstring = "\(thex)-\(ahex)-\(yhex)-\(chex)\(ichex)"
		return UUID(uuidString: finalstring)!
	}
	
	
}

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
	case name, artist, album, year, genre, diff_drums, diff_guitar, directory, video, delay, icon, charter, song_length, loading_phrase, preview_start_time
}

