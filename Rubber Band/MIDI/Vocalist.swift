//
//  Vocalist.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/19/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import MIKMIDI
import SpriteKit

class Vocalist {
	private let track	: MIKMIDITrack
	private var lyrics 	= [(Double, String)]()
	
	var count 	= 0
	
	init() {
		self.track 	= MusicSheet.shared.getvocals()
		lyricist()
	}
	
	func updatecoach(coach: Vocalcoach)  {
		coach.loadlyrics(lyrics: lyrics) 
	}
}

fileprivate typealias Phrase = (Double, String)
private extension Vocalist {
	/// retrieves lyrics from lyric track in an array of phrases [(time, phrase)]
	///
	/// - Parameter tc: timecode instance
	func lyricist(){
		let tc = TimeCode.tc
		var phrase 		= (0.0, "")
		var text 	 	= ""
		var time 		= 0.0
		_ = track.events(of: MIKMIDIMetaLyricEvent.self, fromTimeStamp: 0, toTimeStamp: (track.events.last?.timeStamp)!)
	
		
		for e in track.events{
			if e.eventType == .metaLyricText {
				let t = e as! MIKMIDIMetaLyricEvent
				if t.string != nil {
					if	t.string!.last == "+" { continue }
					text +=  (t.string! + " ")
				}
				continue
			}
			if e.eventType == .metaText {
				let event = e as! MIKMIDIMetaTextEvent
				
				if event.string == "[idle]" {
					phrase = (time, rephrase(text: text))
					lyrics.append(phrase)
					time = tc.beattosec(beat: event.timeStamp)
					text = "***"
				}
				continue
			}
			
			if e.eventType ==  .midiNoteMessage {
				let note = e as! MIKMIDINoteEvent
				if note.note == 105 || note.note == 106 {
					if text == "" {
						time = tc.beattosec(beat: note.timeStamp)
						continue
					}
					
					phrase = (time, rephrase(text: text))
					lyrics.append(phrase)
					time = tc.beattosec(beat: note.timeStamp)
					text = ""
				}
			}
		} // end for loop
		
		lyrics.append((time, text))
		lyrics.append((time + 2, ""))
		lyrics.append((time + 1000, ""))
	} // end of lyricist
	
	func rephrase(text: String) -> String {
		var newtext = text.replacingOccurrences(of: "= ", with: "-")
		newtext = text.replacingOccurrences(of: "#|(ß)|(§)|(_)", with: " ", options: .regularExpression, range: nil)
		
		return newtext.replacingOccurrences(of: "#|(- )|(-# )|(-\\^ )|(\\^)", with: "", options: .regularExpression, range: nil)
	}
}
