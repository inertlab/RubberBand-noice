//
//  Jukebox.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/10/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//
import AVFoundation
import SceneKit
import AudioToolbox

/// creates audio players, finds audio files (m4v, aac, mp3, ogg) in Song folder and plays all files found
class Jukebox: NSObject, AVAudioPlayerDelegate {
	
	static let shared = Jukebox()
	
	private override init() {}

	var noiceplayer = NoiceAudioPlayer()
	var trackurls = [Track: URL]()
	var folder = URL(fileURLWithPath: "upnext")
	var time = 0.0
	var volume: Float = 0.0
	var vol_prev: Float = 0.0
	var vol_crowd: Float = 0.0
	var trying = false
	let rewindplayer = try! AVAudioPlayer(
		contentsOf: URL(
			string: Bundle.main.path(forResource: "sounds/rewind_01", ofType: "m4a")!)!)
	
	/// Position driving track animation
	/// - Returns: time in secods to be converted to cgfloats
	func currenttime() -> Double? {
		return noiceplayer.trackmanager.synchronizer.currentTime().seconds
	}
	
	/// The Volume set for previews
	/// - Returns: mulitplied by the master volume, if master vol is off so are previews
	func prevol() -> Float {
		return vol_prev * volume
	}
	
	func timeremaining() -> Double  {
		return noiceplayer.length - noiceplayer.trackmanager.synchronizer.currentTime().seconds
	}

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print("i'm done youall")
	}
	
	/// creates multiple audio players to play all audio files found by OggNo.aacPaths()
	///
	/// - Parameter aacURL: an Array of audio file URLs
	func play() {
		trackurls.removeValue(forKey: .preview)
		noiceplayer.play(trackurls: trackurls)
	}
	
	func previewsong(song: SongComp) {

		getsongfiles(folder: song.song.folder!)
		
		guard !trackurls.isEmpty else {
			print("no players found, you should exit here")
			return
		}
	
		var starttime = song.song.preview
		
		if starttime == 0 { starttime = 20}
//		 if song duration is not marked get the song duration
		if song.song.length < 1 {
			song.song.length = noiceplayer.length
			try? pc.viewContext.save()
		}
	
		if let previewtrack = trackurls[.preview] {
			noiceplayer.play(trackurls: [.preview: previewtrack], startTime: starttime)
		}
//		crowd is not needed for previews
		trackurls.removeValue(forKey: .crowd)
		noiceplayer.play(trackurls: trackurls, startTime: starttime)
	}
	
	func muteinstrument(track: Track) {
//		if players.count + oggtracks.count == 1 {return}
//		players[track]?.volume = 0
	}
	
	func unmuteinstrument(track: Track) {
//		if players.count + oggtracks.count == 1 {return}
//		players[track]?.volume = volume
	}
	
	func singalong() {
//		if let crowd = players[.crowd] {
//			crowd.setVolume(vol_crowd * volume, fadeDuration: 1)
//		}
		
//		if let crowd = fplayers[.crowd] {
//			crowd.audioEngine.fade(from: 0, to: vol_crowd * volume, duration: 1)
//		}
	}
	
	func stopsinging() {
//		if let crowd = players[.crowd] {
//			crowd.setVolume(0, fadeDuration: 1)
//		}
//		if let crowd = fplayers[.crowd] {
//			crowd.audioEngine.fade(from: vol_crowd * volume, to: 0, duration: 1)
//		}
	}
	
	func stop() {
//		stop is delayed to allow ffmpeg to finish seeking if seeking is in progress
//		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			
			self.noiceplayer.stop()
//		}
	}
	
	func fadeout() {
		noiceplayer.fadeoutpreview()
	}
	
//	only used with slider
	func setvolume(vol: Float) {
//		volume = vol
//		// the oggs
//		var times:Float = 1.0
//		
//		if stagemc.machine.currentState is MenuState {
//			times = vol_prev
//		}
		
//		for fp in fplayers {
//			if fp.key == .crowd {
//				continue
//			}
//			fp.value.volume = volume * times
//		}
		
//		for p in players {
//			if p.key == .crowd {
//				continue
//			}
//			p.value.volume = volume * times
//		}
	}
	
	/// used only while setting volume with menu sliders
	/// - Parameter vol: volume number from menu slider
	func setpreviewvol(vol: Float) {
//		vol_prev = vol
////		only change the player volume if in preview mode
//		if stagemc.machine.currentState is MenuState {
//			for p in players {
//				if p.key == .crowd {
//					continue
//				}
//				p.value.volume = vol_prev * volume
//			}
//			
////			for fp in fplayers {
////				if fp.key == .crowd {
////					continue
////				}
////				fp.value.volume = vol_prev * volume
////			}
//		}
	}
	
	/// used only while setting volume with sliders
	/// - Parameter vol: volume number from menu slider
	func setcrowdnoise(vol: Float) {
//		vol_crowd = vol
//		for p in players {
//			if p.key == .crowd {
//				p.value.volume = vol_crowd * volume
//				return
//			}
//		}
	}
	
	func pauseMusic() {
//		for p in players {
//			p.value.pause()
//		}
	}

	func resumePlay() {
//		var time = currenttime()!
//		
//		if time > 2 {
//			time -= 2
//		} else {
//			time = 0
//		}
//		
//		let devicetime = players[.guitar]!.deviceCurrentTime
//		for p in players {
//			if p.key == .crowd { p.value.volume = 0 }
//			p.value.volume = 0
//			p.value.currentTime = time
//			p.value.play(atTime: devicetime)
//			p.value.setVolume(volume, fadeDuration: 2)
//		}
	}
	
	func rewind() {
//		rewindplayer.volume = volume * 0.25
//		rewindplayer.play()
	}
	
	/// retrieves all the music files from song folder
	///
	/// - Parameter folder: URL to song folder
	/// - Returns: array of song file paths
	func getsongfiles (folder: URL) {

		self.folder = folder
		
		trackurls.removeAll()
		
		let allfiles = try! FileManager.default.contentsOfDirectory(atPath: folder.path)
		if allfiles.isEmpty {
			print("folder is empty?")
			return
		}
		
		let musicfiles = allfiles.filter{
//		possible formats = .m4a, .mp3, .aac, .wav, .caf, .aiff
			$0.contains(".m4a") ||
			$0.contains(".mp3") ||
			$0.contains(".aac") ||
			$0.contains(".ogg")
		}

		for file in musicfiles {
			print("playing :", file)
			if let track = Track.init(rawValue: file.split(separator: ".").first!.description) {
				trackurls[track] = folder.appendingPathComponent(file)
			}
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
