//
//  Seconds.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/7/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import MIKMIDI


class TimeCode {
	/// keeps internal count of seconds
	private var clock = 0.0
	/// list of tempo events updated with seconds and previous bmp and timestamp
	private var events = [fzTempoEvent]()
	
	init(seq: MIKMIDISequence) {
		updateevents(seq: seq)
	}
	
	/// converts the MusicTimeStamps in an array of tuples to Seconds
	///
	/// - Parameter seq: midi sequence to analyze
	/// - return: an array of tuples
	func convertmtstosec(notes: [( Double, String)]) -> [(Double, String)]{
		var newnotes = [(Double, String)]()
		var oldnote = 0.0
		var oldtime = 0.0
		for note in notes {
//			print(note)
			var newnote = (0.0, note.1)
			
			if note.0 == oldnote {
				newnote.0 = oldtime
		
			} else {
				
				oldnote = note.0
				
				for event in events {
					if note.0 < event.mts {
//						print(event)
						if note.0 == event.prev_mts {
							newnote.0 = event.time
							oldtime = event.time
							break
						}
						newnote.0 = mtstosec(fzte: event, timestamp: note.0)
						oldtime = newnote.0
						//					print(event)
						break
					}
				}
//							print(newnote)
			}
			
			newnotes.append(newnote)
		}
//		print(newnotes)
		return newnotes
	}
	
	func beattosec(beat: Double) -> Double {
		var sec = 0.0
		for event in events {
			if beat < event.mts {
				sec = mtstosec(fzte: event, timestamp: beat)
				break
			}
		}
		return sec
	}
}

private extension TimeCode {

	/// converts musicTimeStamps into seconds and adjusts for song delay
	///
	/// - Parameters:
	///   - fzte: fzTempoEvent
	///   - timestamp: double representing a musicTimeStamp
	/// - Returns: time stamp in seconds with delay built in
	func mtstosec(fzte: fzTempoEvent, timestamp: Double ) -> Double  {
		let beatoffest = timestamp - fzte.prev_mts
		return (beatoffest * secperbeat(bpm: fzte.bpm)) + fzte.time + selectedSong.delay
	}
	
	/// converts tempo events into fzTempoEvents and stores them in self.events
	///
	/// - Parameter seq: musicSequence - aka midi file track
	func updateevents(seq: MIKMIDISequence) {
		let totalbeats = seq.length
		let tempos = seq.tempoEvents()
		var bpm = 100.0
		
		var prev_tstamp = 0.0
		
		for t in tempos {
			// first time stamp is added to the array and then skips the rest of the procedure
			// timeline[0] = initial bpm
			if t.timeStamp == 0 {
				bpm = t.bpm
				prev_tstamp = t.timeStamp
				continue
			}
			
			let tevent = fzTempoEvent(mts: t.timeStamp, bpm: bpm, time: clock, prev_mts: prev_tstamp)
			
			updateclock(fzte: tevent)
			
			bpm = t.bpm
			prev_tstamp = t.timeStamp
			self.events.append(tevent)
		}
		
		/// the last timestamp in midi file, contains the last bpm and time offset
		let lastevent = fzTempoEvent(mts: totalbeats, bpm: bpm, time: clock, prev_mts: prev_tstamp)
		self.events.append(lastevent)
		clock = 0
	}
	
	/// Upades Clock elapsed time
	///
	/// - Parameter fzte: fzTempoEvent
	func updateclock(fzte: fzTempoEvent)  {
		let beatoffest = fzte.mts - fzte.prev_mts
		clock += beatoffest * secperbeat(bpm: fzte.bpm)
	}
	
	/// finds how many seconds in 1 beat
	///
	/// - Parameter bpm: beeps per min from midi file
	/// - Returns: sec/beat Double
	func secperbeat(bpm: Double) -> Double {
		return 1 / bpm * 60
	}

}


/// fztempoevents holds the previous tempo event to find offest
struct fzTempoEvent {
	/// current musictimestamp
	let mts:		Double
	/// previous bpm
	let bpm:		Double
	/// time in seconds
	let time:		Double
	/// previous musictimestamp
	let prev_mts:	Double
}

