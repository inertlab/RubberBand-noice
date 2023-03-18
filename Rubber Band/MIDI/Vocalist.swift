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
	private let track	: MIKMIDITrack?
	private var lyrics 	= [(Double, String)]()
	
	var count 	= 0
	
	init() {
		if let trak = MusicSheet.shared.getTrackByName(partname: .vocals) {
			self.track = trak
			lyricist()
		} else {
//			lyrics is guaranteed to have 3 phrases
			lyrics = [(0, ""), (0, ""), (0, "")]
			track = nil
		}
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
		let tc 		= TimeCode.tc
		var phrase 	= (0.0, "")
		var text 	= ""
		var time 	= 0.0
		_ = track!.events(of: MIKMIDIMetaLyricEvent.self, fromTimeStamp: 0, toTimeStamp: (track!.events.last?.timeStamp)!)
		
		for event in track!.events {
			if event.eventType == .midiNoteMessage {
				let note = event as! MIKMIDINoteEvent
				if note.note == 105 || note.note == 106 {
					if text == "" {
						time = tc.beattosec(beat: note.timeStamp)
						continue
					}
					// minus .5 seconds too have phrase appear ahead of time
					phrase = (time - 0.5, rephrase(text: text))
					lyrics.append(phrase)
					time = tc.beattosec(beat: note.timeStamp)
					text = ""
				}
				continue
			}
			
			var eventstring : String?
			if event.eventType == .metaLyricText {
				if let e = event as? MIKMIDIMetaLyricEvent {
					eventstring = e.string
				}
			}
			
			if event.eventType == .metaText {
				if let e = event as? MIKMIDIMetaTextEvent {
					eventstring = e.string
				}
			}
			
			if let str = eventstring {
				if str.first == "[" {continue}
				if	str.last == "+" {continue}
				text +=  (str + " ")
				continue
			}
		}
		
		lyrics.append((time, text))
		lyrics.append((time + 2, ""))
		lyrics.append((time + 1000, ""))
	} // end of lyricist
	
	
	func rephrase(text: String) -> String {
		var newtext = text.replacingOccurrences(of: "= ", with: "")
		newtext = newtext.replacingOccurrences(of: "# |ß|§|_", with: " ", options: .regularExpression, range: nil)
		newtext = newtext.replacingOccurrences(of: "#|-# |-\\^ |%|\\^|=|\\|-", with: "", options: .regularExpression, range: nil)
		return newtext.replacingOccurrences(of: "- ", with: "")
	}
}
