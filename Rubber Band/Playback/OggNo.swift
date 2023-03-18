//
//  OggNo.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/10/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import AVFoundation



var playa = URL(string: "")


/// creates audi players, finds audio files (m4v, aac, mp3) in Song folder and plays all files found
class OggNo: NSObject, AVAudioPlayerDelegate {

	static let sharedInstance = OggNo()
	
	private override init() {}
	
	var players = [URL:AVAudioPlayer]()
	var duplicatePlayers = [AVAudioPlayer]()
	
	/// searches song folder for audio files of the same format. It looks for m4v first, if not found then aac and then mp3
	///
	/// - Parameter folder: path to song folder
	/// - Returns: an array of URLs of all the audio files found of the same format
	func aacPaths (folder: URL) -> [URL] {
		var aacURLs = [URL]()
		// returns all the paths to ini files in all subdirectories
		do{
			let soundfiles = try FileManager.default.contentsOfDirectory(atPath: folder.path)
			let aacfiles = soundfiles.filter{$0.contains(".m4a")}
			for a in aacfiles {
				if a == "preview.m4a" || a == "crowd.m4a" { continue }
				let url = folder.appendingPathComponent(a)
				if a == "guitar.m4a"	{playa = url}
				aacURLs.append(url)
			}
			if aacURLs.isEmpty {
				let aacfiles = soundfiles.filter{$0.contains(".aac")}
				for a in aacfiles {
					if a == "preview.aac" { continue }
					let url = folder.appendingPathComponent(a)
					aacURLs.append(url)
				}
			}
			if aacURLs.isEmpty {
				let aacfiles = soundfiles.filter{$0.contains(".mp3")}
				for a in aacfiles {
					if a == "preview.mp3" { continue }
					let url = folder.appendingPathComponent(a)
					aacURLs.append(url)
				}
			}
		}catch{
			
		}
		return aacURLs
	}
	
	
	/// creates multiple audio players to play all audio files found by OggNo.aacPaths()
	///
	/// - Parameter aacURL: an Array of audio file URLs
	func playSounds(aacURL: [URL]) {
		for path in aacURL {
			playSound(aacURL: path)
		}
	}
	
	func pauseSounds() {
		for p in self.players.enumerated() {
			p.element.value.pause()
		}
	}
	
	func resumePlay() {
		for p in self.players.enumerated() {
			p.element.value.play()
		}
	}

	/// creates an audio player and plays a single audio file
	///
	/// - Parameter aacURL: URL to a audio file
	func playSound (aacURL: URL){

		if let player = players[aacURL] { 	//player for sound has been found
			if player.isPlaying == false { 	//player is not in use, so use that one
				player.prepareToPlay()
				player.play()

			} else { 						// player is in use, create a new, duplicate, player and use that instead
				let duplicatePlayer = try! AVAudioPlayer(contentsOf: aacURL)
				//use 'try!' because we know the URL worked before.
					duplicatePlayer.delegate = self
					//assign delegate for duplicatePlayer so delegate can remove the duplicate once it's stopped playing
					duplicatePlayers.append(duplicatePlayer)
					//add duplicate to array so it doesn't get removed from memory before finishing
					duplicatePlayer.prepareToPlay()
					duplicatePlayer.play()
			}
			
		} else { //player has not been found, create a new player with the URL if possible
			do{
				let player = try AVAudioPlayer(contentsOf: aacURL)
					players[aacURL] = player
				
					player.prepareToPlay()
					player.play()
			} catch {
				print("Could not play sound file!")
			}
		}
	}
	
	func stop() {
		players.removeAll()
		duplicatePlayers.removeAll()
	}
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		//Remove the duplicate player once it is done
		duplicatePlayers.remove(at: duplicatePlayers.firstIndex(of: player)!)
	}
}

