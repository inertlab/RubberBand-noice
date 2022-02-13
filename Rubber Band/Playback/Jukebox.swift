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
	
	var ogg 		= false
	var players 	= [Track:AVAudioPlayer]()
	var fplayers 	= [Track:FPlayer]()
//	var oggcontext 	= [Track:AudioFileContext]()
	var folder 		= URL(fileURLWithPath: "upnext")
	var timer 		= Timer()
	var time		= 0.0
	var volume		: Float = 0.0
	var vol_prev	: Float = 0.0
	var vol_crowd	: Float = 0.0
	let rewindplayer = try! AVAudioPlayer(
		contentsOf: URL(
			string: Bundle.main.path(forResource: "sounds/rewind_01", ofType: "m4a")!)!)
	let pla = AVAudioPlayer()
	
	func timeremaining () -> Double  {
		if ogg {
			if fplayers[.guitar]!.state == .stopped {return 0}
			return fplayers[.guitar]!.playingFile.format.duration - fplayers[.guitar]!.seekPosition
		}
		return players[.guitar]!.duration - players[.guitar]!.currentTime
	}

	func currenttime() -> Double? {
		if ogg {
			return fplayers[.guitar]?.seekPosition
		}
		return players[.guitar]?.currentTime
	}
	
	func duration() -> Double? {
		if ogg {
			return fplayers[.guitar]?.playingFile.format.duration
		}
		return players[.guitar]?.duration
	}
	
	
	/// creates multiple audio players to play all audio files found by OggNo.aacPaths()
	///
	/// - Parameter aacURL: an Array of audio file URLs
	func play() {
		timer.invalidate()
		
		if ogg {
			let now = fplayers[.guitar]!.audioEngine.playerNode.lastRenderTime?.sampleTime ?? AVAudioFramePosition(0)
			let startTime = AVAudioTime(sampleTime: now, atRate: 44100)
			for fp in fplayers {
				if fp.key == .preview {continue}
				if fp.key == .crowd { fp.value.volume = 0 }
				fp.value.volume = volume
				fp.value.beginplayback(attime: startTime)
			}
			return
		}
		
		let devicetime = players[.guitar]?.deviceCurrentTime
		for p in players {
			if p.key == .preview { continue }
			if p.key == .crowd { p.value.volume = 0 }
			p.value.volume = volume
			p.value.prepareToPlay()
			p.value.play(atTime: devicetime! + 0.5)
		}
	}
	
	
	func preview(from: Double) {
		
		if vol_prev == 0 {return}
		
		if ogg {
			if let fp = fplayers[.preview] {
				fp.volume = vol_prev * volume
				fp.beginPlayback()
				return
			}
			
			if fplayers.count == 1 {
				fplayers[.guitar]?.seek(to: from)
				fplayers[.guitar]?.beginPlayback()
				return
			}
			
//			fplayers[.guitar]!.seek(to: from)
//			let seek 	= fplayers[.guitar]!.seekPosition
			let now 	= fplayers[.guitar]!.audioEngine.playerNode.lastRenderTime?.sampleTime ?? AVAudioFramePosition(0)
//			let rate 	= fplayers[.guitar]!.audioFormat.sampleRate
//			let av 		= AVAudioTime(sampleTime: now! + Int64(( rate + 0.5)), atRate: rate)
//			let now = audioPlayers.first!.lastRenderTime?.sampleTime ?? AVAudioFramePosition(0)
			let startTime = AVAudioTime(sampleTime: now, atRate: 44100)
			
			for fp in fplayers {
				if fp.key == .crowd {continue}
				fp.value.volume = vol_prev * volume
//				try! fp.value.decoder.seek(to: from)
				fp.value.beginplayback(attime: startTime)
			}
			
			return
		}
		
		
		if let player = players[.preview] {
			player.volume = 0
			player.prepareToPlay()
			player.play()
			player.setVolume(vol_prev * volume, fadeDuration: 1.5)
			return
		}

		let devicetime = players[.guitar]?.deviceCurrentTime
		for p in players {
			if p.key == .crowd { continue }
			p.value.volume = 0
			p.value.currentTime = from
			p.value.prepareToPlay()
			p.value.play(atTime: devicetime! + 0.5) 	// sets playtime with delay - according to apple this ensures syncing
			p.value.setVolume(vol_prev * volume, fadeDuration: 1.5)
		}
	}
	
	func singalong() {
		if let crowd = players[.crowd] {
			crowd.setVolume(vol_crowd * volume, fadeDuration: 1)
			print("singing")
		}
	}
	
	func stopsinging() {
		if let crowd = players[.crowd] {
			crowd.setVolume(0, fadeDuration: 1)
			print("shutup")
		}
	}
	
	func stop() {
		// when timer is invalid, previews won't start. avoid a race condition
		timer.invalidate()
		for fp in fplayers {
			fp.value.stop()
		}
		for p in players {
			p.value.stop()
		}
	}
	
	func fadeout() {
		for fp in fplayers {
			fp.value.stop()
		}
		for p in players {
			p.value.setVolume(0, fadeDuration: 2)
		}
	}
	
	func setvolume(vol: Float) {
		volume = vol
		// the oggs
		for fp in fplayers {
			if fp.key == .crowd {
				continue
			}
			fp.value.volume = volume
		}
		
		for p in players {
			if p.key == .crowd {
				continue
			}
			p.value.volume = volume
		}
	}
	
	func setpreviewvol(vol: Float) {
		vol_prev = vol
		for p in players {
			if p.key == .crowd {
				continue
			}
			p.value.volume = vol_prev * volume
		}
		
		for fp in fplayers {
			if fp.key == .crowd {
				continue
			}
			fp.value.volume = vol_prev * volume
		}
	}
	
	func setcrowdnoise(vol: Float) {
		vol_crowd = vol
		for p in players {
			if p.key == .crowd {
				p.value.volume = vol_crowd * volume
				return
			}
		}
	}
	
	func pauseMusic() {
		for fp in fplayers {
			fp.value.togglePlayPause()
		}
		
		for p in players {
			p.value.pause()
		}
	}

	func resumePlay() {
		
		var time = currenttime()!
		
		if time > 2 {
			time -= 2
		} else {
			time = 0
		}
		
		if ogg {
			for fp in fplayers {
				fp.value.togglePlayPause()
			}
			return
		}
		
		let devicetime = players[.guitar]!.deviceCurrentTime
		for p in players {
			p.value.currentTime = time
			p.value.play(atTime: devicetime)
		}
	}
	
	func rewind() {
		rewindplayer.volume = volume * 0.4
		rewindplayer.play()
	}
	
	func timeit() {
		time = 0
		timer.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true){
			tim in
			self.time += tim.timeInterval
			if self.time == 20 {
				Jukebox.shared.fadeout()
			}
			if self.time > 20 {
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
		ogg 		= false
		self.folder = folder
		players 	= [Track:AVAudioPlayer]()
		fplayers 	= [Track: FPlayer]()
		var allfiles 	= [String]()
		//		var dic 	= [Track:URL]()
		do {
			allfiles =  try FileManager.default.contentsOfDirectory(atPath: folder.path)
		}catch {
			print("folder is empty?") // in future add function to update current folder
			// return empty array
			return
		}
		
		players = urls(format: "m4a", files: allfiles)
		if !players.isEmpty {
			return
		}
		
		players = urls(format: "aac", files: allfiles)
		if !players.isEmpty {
			return
		}
		
		players = urls(format: "mp3", files: allfiles)
		if !players.isEmpty {
			return
		}
		
		fplayers = urloggs(files: allfiles)
		if !fplayers.isEmpty {
			ogg = true
		}
//		oggcontext = oggnodes(files: allfiles)
//		if !oggcontext.isEmpty {
//			ogg = true
//		}
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
	
	func urloggs (files: [String]) -> [Track:FPlayer] {
		print("looking for the logs")
		var dic 		= [Track:FPlayer]()
		let musicfiles 	= files.filter{$0.contains("ogg")}
		for a in musicfiles {
			if let track 	= Track.init(rawValue: a.split(separator: ".").first!.description) {
				if let context = AudioFileContext(forFile: folder.appendingPathComponent(a)) {
					let fplayer = FPlayer(file: context)
					dic[track] 	= fplayer
				}
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



