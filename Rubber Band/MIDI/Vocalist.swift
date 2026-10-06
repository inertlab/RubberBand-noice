//
//  Vocalist.swift
//  RubberBand
//
//  Created by Fernando Zamora on 3/19/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit

typealias Lyric = (time: Double, text: String)

/// prapares final lyrics from midievents to be used in UI
///
/// Does not handle lyric display or tracking -> see VocalCoach for that
/// Always creates at least 3 lyric events
class Vocalist {
	private var lyrics = [Lyric]()
	var count = 0
	
	init() {
		if var events = MusicSheet.shared.fzmidi?.lyrics {
			events.sort(by: {($0.time, $1.note!) < ($1.time, $0.note!)})
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

		var phrase = Lyric(0.0, "")
		
		for event in events {
			
			switch event{
			case .lyric(let lyric, _):
				if lyric == "+" {break}
				phrase.text += "\(lyric) "
				break
			case .note(let note, let time, _, _):
				if ![105, 106].contains(note) {break} // might need to add 106 too
				if phrase.text != "" {
					lyrics.append(cleanphrase(phrase))
					phrase.text = ""
				}
				phrase.0 = time
				break
			case .meta(let type, time: let time):
				if type == "[idle]" {
					if phrase.text != "" {
						lyrics.append(cleanphrase(phrase))
					}
					phrase = (time, "* * *")
				}
				break
			}
		}
		
		lyrics.append(cleanphrase(phrase))
		lyrics.append((phrase.time + 3, ""))
		lyrics.append((phrase.time + 5, ""))
	}
	
	func cleanphrase(_ phrase: Lyric) -> Lyric {
		let newphrase = Lyric(
			phrase.time,
			phrase.text.replacingOccurrences(of: "- ", with: "")
			.replacingOccurrences(of: "-# ", with: "")
			.replacingOccurrences(of: "#", with: "")
			.replacingOccurrences(of: "^", with: "")
			.replacingOccurrences(of: "= ", with: "-")
			.replacingOccurrences(of: "_", with: " ")
		)
		return newphrase
	}
	
}
