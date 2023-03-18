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
	var folder 		= URL(fileURLWithPath: "upnext")
	var timer 		= Timer()
	var time		= 0.0
	var volume		: Float = 0.0
	var vol_prev	: Float = 0.0
	var vol_crowd	: Float = 0.0
	var silenced 	= false
	let rewindplayer = try! AVAudioPlayer(
		contentsOf: URL(
			string: Bundle.main.path(forResource: "sounds/rewind_01", ofType: "m4a")!)!)
	let pla = AVAudioPlayer()
	
	func prevol() -> Float {
		return vol_prev * volume
	}
	
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
	
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		NotificationCenter.default.post(name: .player_playbackCompleted, object: self)
		print("i'm dond youall")
	}
	
	/// creates multiple audio players to play all audio files found by OggNo.aacPaths()
	///
	/// - Parameter aacURL: an Array of audio file URLs
	func play() {
		timer.invalidate()
		
//		MARK: Oggs, working
		if ogg {
			fplayers.removeValue(forKey: .preview)
			let startTime = getavaudiotime()
			for fp in fplayers {
				if fp.key == .crowd { fp.value.volume = 0 }
				fp.value.volume = volume
				fp.value.beginplayback(attime: startTime)
			}
			return
		}
		
//		MARK: native files
		
		players.removeValue(forKey: .preview)
		let devicetime = players[.guitar]?.deviceCurrentTime
		for p in players {
			if p.key == .crowd { p.value.volume = 0 }
			p.value.volume = volume
			p.value.prepareToPlay()
			p.value.play(atTime: devicetime! + 0.5)
		}
	}
	

	
	func preview(from: Double) {
		
		if vol_prev == 0 {return}
		
//		MARK: Ogg, working kinda
		if ogg {
			if let fp = fplayers[.preview] {
				fp.volume = prevol()
				fp.beginPlayback()
				return
			}
//			this block no longer needed?
			if fplayers.count == 1 {
				fplayers[.guitar]?.volume = 0
				fplayers[.guitar]?.seek(to: from)
				fplayers[.guitar]?.togglePlayPause()
				fplayers[.guitar]?.audioEngine.fade(from: 0, to: prevol(), duration: 1.5)
				return
			}
//			crowd is not needed in preview
			fplayers.removeValue(forKey: .crowd)
			for fp in fplayers {
				fp.value.seek(to: from)
			}
			
			let startTime = getavaudiotime()
			
			for fp in fplayers.values {
				fp.volume = 0
				fp.beginplayback(attime: startTime)
				fp.audioEngine.fade(from: 0, to: prevol(), duration: 1.5)
			}
			
			return
		}
		
//		MARK: Native files
		if let player = players[.preview] {
			player.volume = 0
			player.prepareToPlay()
			player.play()
			player.setVolume(vol_prev * volume, fadeDuration: 1.5)
			return
		}
//		crowd is not needed for previews
		players.removeValue(forKey: .crowd)
		let devicetime = players[.guitar]?.deviceCurrentTime
		for p in players {
			p.value.volume = 0
			p.value.currentTime = from
			p.value.prepareToPlay()
			// sets playtime with delay - according to apple this ensures syncing
			p.value.play(atTime: devicetime! + 0.25)
			p.value.setVolume(vol_prev * volume, fadeDuration: 1.5)
		}
	}
	
	func muteinstrument(track: Track) {
		if players.count + fplayers.count == 1 {return}
		players[track]?.volume = 0
		fplayers[track]?.volume = 0
	}
	
	func unmuteinstrument(track: Track) {
		if players.count + fplayers.count == 1 {return}
		players[track]?.volume = volume
		fplayers[track]?.volume = volume
	}
	
	func singalong() {
		if let crowd = players[.crowd] {
			crowd.setVolume(vol_crowd * volume, fadeDuration: 1)
		}
		
		if let crowd = fplayers[.crowd] {
			crowd.audioEngine.fade(from: 0, to: vol_crowd * volume, duration: 1)
		}
	}
	
	func stopsinging() {
		if let crowd = players[.crowd] {
			crowd.setVolume(0, fadeDuration: 1)
		}
		if let crowd = fplayers[.crowd] {
			crowd.audioEngine.fade(from: vol_crowd * volume, to: 0, duration: 1)
		}
	}
	
	func stop() {
		// when timer is invalid, previews won't start to avoid a race condition
		timer.invalidate()
		for fp in fplayers {
			fp.value.stop()
		}
		
		for p in players {
			p.value.stop()
		}
		NotificationCenter.default.post(name: .player_playbackCompleted, object: nil)
	}
	
	func fadeout() {
		for fp in fplayers {
			fp.value.audioEngine.fadeOutpreview()
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
	
	/// used only while setting volume with sliders
	/// - Parameter vol: volume number from menu slider
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
	
	/// used only while setting volume with sliders
	/// - Parameter vol: volume number from menu slider
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
				fp.value.seek(to: time)
			}
			
			let startTime = getavaudiotime()
			
			for fp in fplayers {
				if fp.key == .crowd {continue}
				fp.value.volume = 0
				fp.value.beginplayback(attime: startTime)
				fp.value.audioEngine.fade(from: 0, to: volume, duration: 2)
			}
			return
		}
		
		let devicetime = players[.guitar]!.deviceCurrentTime
		for p in players {
			if p.key == .crowd { p.value.volume = 0 }
			p.value.volume = 0
			p.value.currentTime = time
			p.value.play(atTime: devicetime)
			p.value.setVolume(volume, fadeDuration: 2)
		}
	}
	
	func rewind() {
		rewindplayer.volume = volume * 0.25
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
//				stops the player completely 5 seconds after fadeout
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
		
		// change .guitar to .song - when there are multitracks we silence guitar, if there is only one track we don't want to silence the whole song
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
			// root is the players that notifies song is over
			dic[.guitar]?.root = true
		}
		return dic
	}
	
	
	/// gets the AVAudiotime position from the .guitar file
	/// - Returns: AVAudioTime
	func getavaudiotime() -> AVAudioTime {
//		when i swap .guiar with .song, things get wonky
		let now = fplayers[.guitar]!.audioEngine.playerNode.lastRenderTime?.sampleTime ?? AVAudioFramePosition(0)
		return AVAudioTime(sampleTime: now, atRate: 44100)
	}

}



