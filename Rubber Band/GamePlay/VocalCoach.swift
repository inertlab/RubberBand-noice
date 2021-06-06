//
//  VocalCoach.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/19/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import MIKMIDI
import SpriteKit


class Vocalcoach {
	var lyrics 		= [(0.0, "")]
	var abc  		= [0,1,2]
	var count 		= 0
	let lyricnode 	= scoreDisplay?.childNode(withName: "lyrics")!
	var phrases 	= [SKLabelNode]()
	let phrase_a	: SKLabelNode
	let phrase_b	: SKLabelNode
	let phrase_c	: SKLabelNode
	let a_exit 		= SKAction(named: "exit")
	let a_enter 	= SKAction(named: "enter")
	let a_appear 	= SKAction(named: "appear")
//	let slidetoview = SKAction(named: "slidetoview", from: "actions.sks")
	
	init() {
		self.phrase_a 	= lyricnode!.childNode(withName: "phrase_a") as! SKLabelNode
		self.phrase_b 	= lyricnode!.childNode(withName: "phrase_b") as! SKLabelNode
		self.phrase_c 	= lyricnode!.childNode(withName: "phrase_c") as! SKLabelNode
		phrases.append(self.phrase_a)
		phrases.append(self.phrase_b)
		phrases.append(self.phrase_c)
		scoreDisplay?.isPaused = false
		emptylyrics()
	}
	
	/// Keeps track of Song play position and updates lyrics accordingy
	/// - Parameter songtime: The current time of the song playback in seconds - Unaltered
	func tracklyrics(songtime: Double)  {
	
		if songtime > lyrics[count].0  {
//			resetanim()
//			resetloc()
			switch count % 3 {
			case 0:
				abc = [0,1,2]
			case 1:
				abc = [1,2,0]
			default:
				abc = [2,0,1]
			}
			
			if count + 1 < lyrics.count {
				phrases[abc[1]].text = lyrics[count + 1].1
				
				phrases[abc[0]].run(a_enter!)
				phrases[abc[1]].run(a_appear!)
				phrases[abc[2]].run(a_exit!)
				count += 1
			}
		}
	}
	
	func loadlyrics(lyrics: [(Double, String)]) {
		self.lyrics = lyrics
		self.count 	= 0
		startposition()
	}
}

private extension Vocalcoach {
	
	func reset(){
		resetloc()
		resetyrlics()
	}
	
	func emptylyrics() {
		print("emptying lyrics")
		for p in phrases {
			p.removeAllActions()
			p.text = ""
		}
	}
	
	func startposition() {
		abc = [0,1,2]
		phrases[abc[0]].position.y 	= -25
		phrases[abc[0]].alpha 		= 0.25
		phrases[abc[1]].position.y 	= -25
		phrases[abc[1]].alpha 		= 0
		phrases[abc[2]].position.y 	= -25
		phrases[abc[2]].alpha 		= 0
		resetyrlics()
	}
	
	func resetyrlics() {
		phrases[abc[0]].text = lyrics[0].1
		phrases[abc[1]].text = lyrics[1].1
		phrases[abc[2]].text = lyrics[2].1
	}
	
	func resetloc(){
		phrases[abc[0]].position.y 	= -20
		phrases[abc[0]].alpha 		= 0
		phrases[abc[1]].position.y 	= 0
		phrases[abc[1]].alpha 		= 1
		phrases[abc[2]].position.y 	= -20
		phrases[abc[2]].alpha 		= 0.25
	}
	
	func resetanim(){
		phrase_a.removeAllActions()
		phrase_b.removeAllActions()
		phrase_c.removeAllActions()
		resetloc()
	}
}


let skfadin25 	= SKAction.fadeAlpha(to: 0.25, duration: 1)
let skfadein1 	= SKAction.fadeAlpha(to: 1, duration: 0.25)
let skfadeout 	= SKAction.fadeOut(withDuration: 0.1)
let skmoveup 	= SKAction.moveTo(y: CGFloat(0), duration: 1)

let skslideup 	= SKAction.group([skmoveup, skfadein1])

//let vocalcoach  	= Vocalcoach()
