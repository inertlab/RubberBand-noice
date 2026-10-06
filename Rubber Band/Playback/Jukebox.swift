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
	var mutetrack: Track?
	var previewing = DispatchWorkItem {
		print("dsipatch here")
	}
//	var previewtimer = DispatchWorkItem
	let rewindplayer = try! AVAudioPlayer(
		contentsOf: URL(
			string: Bundle.main.path(forResource: "sounds/rewind_01", ofType: "m4a")!)!)
	
	/// Position driving track animation
	/// - Returns: time in secods to be converted to cgfloats
	func currenttime() -> Double? {
		return noiceplayer.dj.synchronizer.currentTime().seconds
	}
	
	/// The Volume set for previews
	/// - Returns: mulitplied by the master volume, if master vol is off so are previews
	func prevol() -> Float {
		return vol_prev * volume
	}
	

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print("i'm done you'll")
	}
	
	/// creates multiple audio players to play all audio files found by OggNo.aacPaths()
	///
	/// - Parameter aacURL: an Array of audio file URLs
	func play() {
		trackurls.removeValue(forKey: .preview)
		setmutetrack()
		noiceplayer.play(trackurls: trackurls)
		noiceplayer.setvolume(volume)
	}
	
	func previewsong(song: SongComp) {

		getsongfiles(folder: song.song.folder!)
		
		guard !trackurls.isEmpty else {
			print("no players found, you should exit here")
			return
		}
	
//		if preview track is found no timer necessary
		if let previewtrack = trackurls[.preview] {
			
			noiceplayer.play(trackurls: [.preview: previewtrack])
			setvolume(vol: prevol())
			return
		}
		
		
		var starttime = song.song.preview
		if starttime == 0 { starttime = 20}
		
//		crowd is not needed for previews
		trackurls.removeValue(forKey: .crowd)
		noiceplayer.play(trackurls: trackurls, startTime: starttime)
		noiceplayer.fade(from: 0, to: prevol())
		
		previewing = DispatchWorkItem{ self.fadeout()}
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(20), execute: previewing )
	}
	
	func instrumentvolume(vol: Float = Jukebox.shared.volume) {
		if let track = mutetrack {
			noiceplayer.setvolume(vol, track: track)
		}
	}
	
	func singalong() {
		if let _ = trackurls[.crowd] {
			noiceplayer.fadetrack(track: .crowd, to: vol_crowd * volume)
		}
	}
	
	func stopsinging() {
		if let _ = trackurls[.crowd] {
			noiceplayer.fadetrack(track: .crowd, from: vol_crowd * volume, to: 0)
		}
	}
	
	func stop() {
		previewing.cancel()
		self.noiceplayer.stop()
	}
	
	func fadeout() {
		noiceplayer.fadeoutpreview()
	}
	
//	only used with slider
	func setvolume(vol: Float) {
		self.volume = vol
		var times:Float = 1.0
		if stagemc.machine.currentState is MenuState {
			times = vol_prev
		}
		noiceplayer.setvolume(vol * times)
	}
	
	/// used only while setting volume with menu sliders
	/// - Parameter vol: volume number from menu slider
	func setpreviewvol(vol: Float) {
		vol_prev = vol
//		only change the player volume if in preview mode
		if stagemc.machine.currentState is MenuState {
			noiceplayer.setvolume(vol_prev * volume)
		}
	}
	
	/// used only while setting volume with sliders
	/// - Parameter vol: volume number from menu slider
	func setcrowdnoise(vol: Float) {
		vol_crowd = vol
		noiceplayer.setvolume(vol * volume, track: .crowd)
	}
	
	func pauseMusic() {
		Task{
			await noiceplayer.dj.pause()
		}
	}

	func resumePlay() {
		Task{
			await noiceplayer.dj.resume()
		}
	}
	
	func rewind() {
		rewindplayer.volume = volume * 0.25
		rewindplayer.play()
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
		case guitar, song, bass, vocals, rhythm, keys, preview, crowd
	}
}

private extension Jukebox {
	func setmutetrack(){
		mutetrack = nil
		if trackurls.count > 1 {
			switch User.current.instrument.track() {
			case .drums:
				if let _ = trackurls[.drums]{
					mutetrack = .drums
				}
			case .bass:
				if let _ = trackurls[.bass]{
					mutetrack = .bass
				}
			case .guitar:
				if let _ = trackurls[.guitar]{
					mutetrack = .guitar
				}
			case .keys:
				if let _ = trackurls[.keys]{
					mutetrack = .keys
				}
			default:
				break
			}
		}
	}
}
