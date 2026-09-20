//
//  Vocalist.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/19/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit

/// combines midi lyric events into phrases for display in spritekit
class Vocalist {
	private var lyrics = [(Double, String)]()
	var count = 0
	
	init() {
		if let events = MusicSheet.shared.fzmidi?.lyrics {
			lyricist(events)
		} else {
			lyrics = [(0, ""), (0, ""), (0, "")]
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
	func lyricist(_ events: NoteEvents){

		var phrase = (0.0, "")
		
		for event in events {
			switch event{
			case .lyric(let lyric):
				if lyric == "+" {break}
				phrase.1 += "\(lyric) "
				break
			case .note(let note, let time, _, _):
				if note != 105 {break} // might need to add 106 too
				if phrase.1 != "" {
					phrase.1 = phrase.1.replacingOccurrences(of: "- ", with: "")
						.replacingOccurrences(of: "= ", with: "-")
						.replacingOccurrences(of: "-# ", with: "")
						.replacingOccurrences(of: "#", with: "")
					lyrics.append(phrase)
					phrase.1 = ""
				}
				phrase.0 = time
				break
			case .meta(let type, time: let time):
				if type == "[idle]" {
					lyrics.append(phrase)
					phrase = (time, "* * *")
				}
				break
			}
		}
		
		lyrics.append(phrase)
		lyrics.append((phrase.0 + 2, ""))
		lyrics.append((phrase.0 + 1000, ""))
	}
	
}
