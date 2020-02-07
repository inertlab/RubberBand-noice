//
//  OggNo.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/10/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//
import AVFoundation



/// creates audi players, finds audio files (m4v, aac, mp3) in Song folder and plays all files found
class Jukebox: NSObject, AVAudioPlayerDelegate {
	
	static let shared = Jukebox()
	
	private override init() {}

	var players = [Track:AVAudioPlayer]()
	var folder 	= URL(fileURLWithPath: "upnext")
	var timer 	= Timer()
	var time	= 0.0
	
	/// creates multiple audio players to play all audio files found by OggNo.aacPaths()
	///
	/// - Parameter aacURL: an Array of audio file URLs
	func play() {
		self.timer.invalidate()
		let devicetime = players[.guitar]?.deviceCurrentTime
		for p in players {
			if p.key == .preview { continue }
			if p.key == .crowd { p.value.volume = 0 }
//			p.value.currentTime = 0
			p.value.prepareToPlay()
			p.value.play(atTime: devicetime! + 0.5)
		}
	}
	
	func preview(from: Double) {
		if let player = players[.preview] {
			player.prepareToPlay()
			player.play()
			return
		}

		let devicetime = players[.guitar]?.deviceCurrentTime
//		self.timer.invalidate()
		for p in players {
			if p.key == .crowd { continue}
			p.value.volume = 0
			p.value.currentTime = from
			p.value.prepareToPlay()
			p.value.play(atTime: devicetime! + 0.5) 	// sets playtime with delay - according to apple this ensures syncing
			p.value.setVolume(1, fadeDuration: 1.5)
		}
//		print(from)
//		self.timeit()
	}
	
	func stop() {
		if let player = players[.preview] {
			player.stop()
			return
		}
		for p in players {
			p.value.stop()
		}
	}
	
	func fadeout() {
		for p in players {
			p.value.setVolume(0.1, fadeDuration: 2)
		}
	}
	
	func pauseMusic() {
		for p in self.players.enumerated() {
			p.element.value.pause()
		}
	}
	
	func resumePlay() {
		for p in self.players.enumerated() {
			p.element.value.play()
		}
	}
	
	func timeit() {
		self.time = 0
		self.timer.invalidate()
		self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true){tim in
			self.time += tim.timeInterval
			if self.time == 25 {
				Jukebox.shared.fadeout()
			}
			if self.time > 25 {
				Jukebox.shared.stop()
				tim.invalidate()
			}
		}
	}
	
	/// retrieves all the music files from song folder
	///
	/// - Parameter folder: URL to song folder
	/// - Returns: array of song file paths
	func getsongfiles (folder: URL) {
		self.folder 	= folder
		var songfiles 	= [Track:AVAudioPlayer]()
		var allfiles 	= [String]()
		//		var dic 	= [Track:URL]()
		do {
			allfiles =  try FileManager.default.contentsOfDirectory(atPath: folder.path)
		}catch {
			print("folder is empty?") // in future add function to update current folder
			// return empty array
			return
		}
		
		songfiles = urls(format: "m4a", files: allfiles)
		if !songfiles.isEmpty {
			players = songfiles
			return
		}
		
		songfiles = urls(format: "aac", files: allfiles)
		if !songfiles.isEmpty {
			players = songfiles
			return
		}
		
		songfiles = urls(format: "mp3", files: allfiles)
		if !songfiles.isEmpty {
			players = songfiles
			return
		}
	}
	
	/// The valid soundfiles to play
	///
	/// - drums: mixed drums - all
	/// - drums_1: kick or snare
	/// - drums_2: kick or snare
	/// - drums_3: other
	/// - drums_4: other
	/// - guitar: guitar and driving file
	/// - song: all other sounds not split into other instruments
	/// - vocals: vocals
	/// - rhythm: mixed sounds
	/// - keys: keyboard
	/// - preview: preview segment
	/// - crowd: sign alongs
	enum Track: String {
		case drums, drums_1, drums_2, drums_3, drums_4
		case guitar, song, vocals, rhythm, keys, preview, crowd
	}
}


private extension Jukebox {
	
	/// finds the urls to all sound files in a folder
	///
	/// - Parameter folder: URL path to the song folder
	/// - format: The extension of the sound file to retreat
	/// - Returns: Array of URLs for every sound file
	func urls (format: String, files: [String]) -> [Track:AVAudioPlayer] {
		var dic 		= [Track:AVAudioPlayer]()
		let musicfiles 	= files.filter{$0.contains(format)}
		for a in musicfiles {
			if let track 	= Track.init(rawValue: a.split(separator: ".").first!.description) {
				let player 	= try! AVAudioPlayer(contentsOf: folder.appendingPathComponent(a))
				dic[track] 	= player
			}
		}
		
		if !dic.isEmpty {
			if dic[.guitar] == nil {
				dic[.guitar] = dic[.song]
				dic.removeValue(forKey: .song)
			}
		}
		return dic
	}
}



