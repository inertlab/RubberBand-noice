//
//  VocalCoach.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/19/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit


/// visual represenation of lyrics
///
/// includes animations
class Vocalcoach {
	var lyrics = [Lyric]()
	var abc = [0,1,2]
	var count = 0
	var phrases = [SKLabelNode]()
	let phrase_a = scoreDisplay?.childNode(withName: "lyrics/phrase_a") as! SKLabelNode
	let phrase_b = scoreDisplay?.childNode(withName: "lyrics/phrase_b") as! SKLabelNode
	let phrase_c = scoreDisplay?.childNode(withName: "lyrics/phrase_c") as! SKLabelNode
	let a_exit = SKAction(named: "exit")
	let a_enter = SKAction(named: "enter")
	let a_appear = SKAction(named: "appear")
	let posy:CGFloat = -50
	var observer:Any = NSObject()
	
	init() {
		phrases.append(self.phrase_a)
		phrases.append(self.phrase_b)
		phrases.append(self.phrase_c)
		scoreDisplay?.isPaused = false
		emptylyrics()
	}
	
<<<<<<< HEAD
	deinit {
//		Jukebox.shared.noiceplayer.trackmanager.synchronizer.removeTimeObserver(observer)
	}
	
	func getsyng() async {
		let songtimes = lyrics.map{$0.0}
		observer = try await Jukebox.shared.noiceplayer.trackmanager.synchronizer.addBoundaryTimeObserver(forTimes: songtimes as [NSValue], queue: .main) { [weak self] in
			if let me = self{
				me.tracklyrics(songtime: Jukebox.shared.noiceplayer.trackmanager.synchronizer.currentTime().seconds)
			}
		}
		tracklyrics(songtime: 0)
=======
	func gettimes() -> [NSValue] {
		return lyrics.map{$0.time - 0.5} as [NSValue]
>>>>>>> vocal_change
	}
	
	/// Keeps track of Song play position and updates lyrics accordingy
	/// - Parameter songtime: The current time of the song playback in seconds - Unaltered
	func tracklyrics(songtime: Double)  {
<<<<<<< HEAD
		if songtime > lyrics[count].0 {
=======
		
		while songtime >= lyrics[count].time - 0.6 {
>>>>>>> vocal_change
			switch count % 3 {
			case 0:
				abc = [0,1,2]
			case 1:
				abc = [1,2,0]
			default:
				abc = [2,0,1]
			}
			
			if count + 1 < lyrics.count {
				phrases[abc[1]].text = lyrics[count + 1].text
				
				phrases[abc[0]].run(a_enter!, withKey: "entering")
				phrases[abc[1]].run(a_appear!, withKey: "appearing")
				phrases[abc[2]].run(a_exit!, withKey: "exiting")
				count += 1
			}
		}
	}
	
	func loadlyrics(lyrics: [Lyric]) {
		self.lyrics = lyrics
		self.count = 0
		startposition()
	}
}

private extension Vocalcoach {
	
	func reset(){
		resetloc()
		resetyrlics()
	}
	
	func emptylyrics() {
		for p in phrases {
			p.removeAllActions()
			p.text = ""
		}
	}
	
//TODO: Lyric positioning
	func startposition() {
		abc = [0,1,2]
		phrases[abc[0]].position.y = posy
		phrases[abc[0]].alpha = 0.25
		phrases[abc[1]].position.y = posy
		phrases[abc[1]].alpha = 0
		phrases[abc[2]].position.y = posy
		phrases[abc[2]].alpha = 0
		resetyrlics()
	}
	
	func resetyrlics() {
		phrases[abc[0]].text = lyrics[0].text
		phrases[abc[1]].text = lyrics[1].text
		phrases[abc[2]].text = lyrics[2].text
	}
	
	func resetloc(){
		phrases[abc[0]].position.y = posy
		phrases[abc[0]].alpha = 0
		phrases[abc[1]].position.y = 0
		phrases[abc[1]].alpha = 1
		phrases[abc[2]].position.y = posy
		phrases[abc[2]].alpha = 0.25
	}
	
	func resetanim(){
		phrase_a.removeAllActions()
		phrase_b.removeAllActions()
		phrase_c.removeAllActions()
		resetloc()
	}
}
