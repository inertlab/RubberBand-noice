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
	private let track: MIKMIDITrack
	private var lyrics = [(Double, String)]()
	
	var count 	= 0
	
	init(track: MIKMIDITrack, tc: TimeCode) {
		self.track 		= track
		lyricist(tc: tc)
	}
	
	func updatecoach(coach: Vocalcoach)  {
		coach.loadlyrics(lyrics: lyrics) 
	}
}

private extension Vocalist {
	/// retrieves lyrics from lyric track in an array of phrases [(time, phrase)]
	///
	/// - Parameter tc: timecode instance
	func lyricist(tc: TimeCode){
		var phrase 		= (0.0, "")
		var text 	 	= ""
		var time 		= 0.0
		let levents = track.events(of: MIKMIDIMetaLyricEvent.self, fromTimeStamp: 0, toTimeStamp: (track.events.last?.timeStamp)!)
		
		
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
				if levents.count == 0 {
					if event.string != nil{
						let st = event.string!
						switch st.last{
						case "-":
							text += st.dropLast()
						case "+":
							continue
						default:
							text += (st + " ")
						}
					}
				} else if event.string! == "[idle]" {
					phrase = (time, text)
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
					text = text.replacingOccurrences(of: "= ", with: "-")
					phrase = (time, text.replacingOccurrences(of: "#|(- )|(-# )|(-^ )", with: "", options: .regularExpression, range: nil))
					lyrics.append(phrase)
					time = tc.beattosec(beat: note.timeStamp)
					text = ""
				}
			}
		} // end for loop
		lyrics.append((time, text))
		lyrics.append((time + 2, ""))
		lyrics.append((time + 1000, ""))
//		lyrics.append((tc.beattosec(beat: (track.events.last?.timeStamp)!), ""))
	} // end of lyricist
	
}
