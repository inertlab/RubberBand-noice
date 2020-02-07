//
//  FZMIK2.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/8/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//


import Foundation
import MIKMIDI
import SceneKit

typealias NoteList = [(start:Double, btn:Button)]

class MusicSheet {
	static let shared = MusicSheet()
	
	var seq = MIKMIDISequence()
	/// MIDI notes in the chart by difficulty
	var difficultyConfig = DifficultyConfig()
	/// convenience reference to timecop
	let tc = TimeCode.tc
	private init() {}
	
	/// Updates timesheet with the current song music sequence
	/// - Parameter url: File location of notes.mid file
	///
	/// When a new sequence is set TimeCode gets updated here
	/// this will have to change when multiplayer is added as we don't want to conflict 2 TimeCodes
	func setSeq (url: URL) {
	  	self.seq = try! MIKMIDISequence(fileAt: url, convertMIDIChannelsToTracks: false)
		self.difficultyConfig = User.current.instrument.config(diff: User.current.diff)
		TimeCode.tc.initTimeCode(seq: self.seq)
	}
	
	func getTrackByName (partname: TrackName = .drums) -> MIKMIDITrack? {
		var track:MIKMIDITrack?
		
		loop: for t in seq.tracks{
			for e in t.events(of: MIKMIDIMetaTrackSequenceNameEvent.self, fromTimeStamp: 0, toTimeStamp: 10) {
				let nevent = e as! MIKMIDIMetaTrackSequenceNameEvent
				if nevent.string == partname.rawValue {
					track = t
					break loop
				}
			}
		}
		return track
	}


	typealias Chord = (btns: Set<Button>, start: Double, end: Double)
	/// [Chord]
	///
	/// Chord: (btns: Set[Button], start: Double, end: Double)
	///
	/// The time values have been translated from MidiTimestamps to Seconds - if end == 0, then the note has no duration or tail. I'm using endTimeStamp instead of Duration to define where the tail ends clearly
	typealias ChordList = [Chord]
	
	/// Returns a sorted ChordList from the User current instrument selection
	func get5lanenotes() -> ChordList {
		
		let track 		= getTrackByName(partname: User.current.instrument.track())
		var chordlist 	= ChordList()
		var chord 		= Chord([], -1, 0)
		
		for n in track!.notes {
			
			if appendSP(n) { continue }

			/// if true, button was found in valid set of notes
			if let button = difficultyConfig[n.note] {
				// note belongs in the current chord
				// there will never be a note at -1
				if chord.start == n.timeStamp {
					chord.btns.insert(button)
					continue
				}
				chord.start = tc.beattosec(beat: chord.start)
				chordlist.append(chord)
				chord = ([button], n.timeStamp, 0)
				if n.duration > 0.26 {
					chord.end = tc.beattosec(beat: Double(n.endTimeStamp))
				}
			}
		}
		// append the last chord to the list
		chordlist.append(chord)
		return chordlist.sorted { $0.start < $1.start }
	}
	
	
	/// gets all the notes for track
	///
	/// - Returns: returns a list of timestamps and .colors
	/// this doesn't work because string instruments require endtimestamps
	func getDrumNotes () -> NoteList {
		if User.current.instrument == .drums {
			return drumnotesVanilla()
		}
		return drumnotesPro()
	}
	
	func drumnotesVanilla () -> NoteList {
		print("this is happening")
		var notes = NoteList()
		
		let track = getTrackByName()
		
		for n in track!.notes {

			if appendSP(n) {
				continue
			}
			
			if let button = difficultyConfig[n.note] {
				let starttime = tc.beattosec(beat: n.timeStamp)
				switch button{
				case .plus:
					// in future add start time to a different note for activator tail
					notes.append((tc.beattosec(beat: n.endTimeStamp), button))
				case .blue, .green, .yellow:
					continue
				case .yellow_c:
					notes.append((starttime, .yellow))
				case .blue_c:
					notes.append((starttime, .blue))
				case .green_c:
					notes.append((starttime, .green))
				default:
					notes.append((starttime, button))
					break
				}
			}
		}
		
		let sortednotes = notes.sorted {$0.0 < $1.0 }
		return sortednotes
	}
	
	/// retrieves drum note information with discoflips etc
	///
	/// - Returns: a tuple array with MusicTimeStamp (beat) and the ControlInput (like .yellow_c) sorted by musicstamp, small to big
	func drumnotesPro () -> NoteList {
		/// an array of Tupples [(MusicTimeStamp, Button)]
		var drumnotes = NoteList()
		
		/// the track from the midi sequence
		let drumtrack = getTrackByName()
		
		//		temporaty note holders for comparison
		var tom110:		[MIKMIDINoteEvent] = []
		var tom111:		[MIKMIDINoteEvent] = []
		var tom112:		[MIKMIDINoteEvent] = []
		var cymbal98:	[MIKMIDINoteEvent] = []
		var cymbal99:	[MIKMIDINoteEvent] = []
		var cymbal100:	[MIKMIDINoteEvent] = []
		
		/// [whether to flip or not, start of the flip, end of the flip]
		var discoFlipMe = [(Bool, MusicTimeStamp, MusicTimeStamp)]()
		
		guard let textevents 	= drumtrack?.events(of: MIKMIDIMetaTextEvent.self, fromTimeStamp: 0, toTimeStamp: (drumtrack?.events.last?.timeStamp)!) else { return [] }
		
		var fliptuple 	= (false, 0.0, 0.0)
		
		// this works now, some midi files aren't marked with a nodiscoflip event, in which case add a closing event at the end of the file
		for e in textevents{
			let starttime 	= tc.beattosec(beat: e.timeStamp)
			let etext 		= e as! MIKMIDIMetaTextEvent
			
			if etext.string == User.current.diff.flipevent() {
				fliptuple.0 = true
				fliptuple.1 = starttime
			}
			
			if etext.string == User.current.diff.noflipevent() && fliptuple.0 {
				fliptuple.2 = starttime
			}
			
			if fliptuple.0 && fliptuple.2 > fliptuple.1 {
				discoFlipMe.append(fliptuple)
				fliptuple = (false, 0.0, 0.0)
			}
		}
		// check if there is a fliptuple without a nodiscoflip event. if there is one add it
		if fliptuple.0 {
			fliptuple.2 = tc.beattosec(beat: drumtrack!.length)
			discoFlipMe.append(fliptuple)
		}
		
		for n in drumtrack!.notes{
			
			if appendSP(n) { continue }
			
			if let cinput = difficultyConfig[n.note] {
				switch cinput{
				case .yellow:
					tom110.append(n)
				case .blue:
					tom111.append(n)
				case .green:
					tom112.append(n)
				case .yellow_c:
					cymbal98.append(n)
				case .blue_c:
					cymbal99.append(n)
				case .green_c:
					cymbal100.append(n)
				case .plus:
					// in future add start time to a different note for activator tail
					drumnotes.append((tc.beattosec(beat: n.endTimeStamp), cinput))
				default:
					drumnotes.append((tc.beattosec(beat: n.timeStamp), cinput))
					break
				}
			}
		}
		
		swapCymbaltoTom(toms: tom110, cymbals: &cymbal98	, dnotes: &drumnotes)
		swapCymbaltoTom(toms: tom111, cymbals: &cymbal99	, dnotes: &drumnotes)
		swapCymbaltoTom(toms: tom112, cymbals: &cymbal100	, dnotes: &drumnotes)
		
		for (f, start, end) in discoFlipMe {
			print("flipping")
			if f {
				for ( i, dn) in drumnotes.enumerated() {
					switch dn.0 {
					case start...end:
						if dn.1 == .red 		{drumnotes[i].1 = .yellow_c	}
						if dn.1 == .yellow_c 	{drumnotes[i].1 = .red		}
					default:
						break
					}
				}
			}
		}
		
		let sortednotes = drumnotes.sorted(by: { $0.0 < $1.0 })
		return sortednotes
	}
	
	func averagetempo() -> Double {
		let bpmlist 	= seq.tempoEvents()
		var bpms:Double	= 0
		for t in bpmlist {
			bpms += t.bpm
		}
		bpms = round(bpms / Double(bpmlist.count))
		pace.setFPS(miditempo: bpms)
		//		self.setOverallTempo(bpms)
		return bpms
	}
	
	func getvocals() -> MIKMIDITrack {
		return getTrackByName(partname: .vocals)!
	}
	
	/// makes and layers beat marks on the track
	///
	/// - Note: at the end of the track beats tend to dip
	func layBeat () {
		let beats = getTrackByName(partname: .beat)
		if beats == nil {
			layBeatnotrack()
		} else {
			layBeatwithtrack()
		}
	}
}

private extension MusicSheet {
	
	/// Checks if note is Star Power, If it is then it appends it to SP list and returns True
	/// - Parameter n: midi note event
	func appendSP (_ n: MIKMIDINoteEvent) -> Bool {
		if n.note == 116 {
			let sta = tc.beattosec(beat: n.timeStamp)
			let end = tc.beattosec(beat: n.endTimeStamp)
			stagemc.track.sp.starnotes.append(([.plus], sta, end))
			return true
		}
		return false
	}
	
	/// Swaps cymbals to toms for Pro Drums
	///
	/// - Parameters:
	///   - toms: Arry of tom markers
	///   - cymbals: Array of cymbal notes
	///   - dnotes: array of collected notes
	func swapCymbaltoTom (toms: [MIKMIDINoteEvent], cymbals: inout [MIKMIDINoteEvent], dnotes: inout NoteList){
		// removes the tom corresponding to cymbals
		for c in toms {
			for (i, t) in cymbals.enumerated().reversed() {
				switch t.timeStamp {
				case c.timeStamp...c.endTimeStamp:
					dnotes.append((tc.beattosec(beat: t.timeStamp), difficultyConfig[c.note]!))
					cymbals.remove(at: i)
				default:
					break
				}
			}
		}
		//	add remainding results to drumnotes
		for r in cymbals{
			dnotes.append((tc.beattosec(beat: r.timeStamp), difficultyConfig[r.note]!))
		}
	}
	
	func layBeatwithtrack () {
		let beats 		= getTrackByName(partname: .beat)
		if beats == nil {return} // what happens if there is no beat track?
		let fatline 	= gems.beat_fat
		let thinline 	= gems.beat_thin
		
		for beat in beats!.notes {
			var line: SCNNode
			let time = tc.beattosec(beat: beat.timeStamp)
			if beat.noteLetter == "C" {
				line = fatline.clone()
			} else {
				line = thinline.clone()
			}
			line.position.z = CGFloat(time) * pace.fps
			stagemc.track.hwy.beatlines.addChildNode(line)
		}
	}
	
	func layBeatnotrack () {
		let fatline 	= gems.beat_fat
		//		let thinline 	= drumScene.rootNode.childNode(withName: "thinline"	, recursively: false)!
		//		let beats		= SCNNode()
		for beat in 0...Int(seq.length) {
			let z 	= CGFloat(tc.beattosec(beat: Double(beat))) * pace.fps
			let fl 	= fatline.clone()
			//			let tl 	= thinline.clone()
			fl.position.z 	= z
			//			fl.name			= "fat"
			//			tl.position.z 	= z - (pace.fps * 0.5)
			//			tl.name			= "thin"
			stagemc.track.hwy.beatlines.addChildNode(fl)
			//			stagemc.track.hwy.beatlines.addChildNode(tl)
		}
	}
	
	func lyricist() -> [(Double, String)] {
		let lyrictrack 	=  getTrackByName(partname: .vocals)
		var phrases 	= [(Double, String)]()
		var phrase 		= (0.0, "")
		var text 	 	= ""
		var time 		= 0.0
		
		for e in lyrictrack!.events{
			if e.eventType == .metaLyricText {
				let t = e as! MIKMIDIMetaLyricEvent
				if t.string != nil {
					let st = t.string!
					switch st.last{
					case "-":
						text += st.dropLast()
					case "+":
						continue
					default:
						text += (st + " ")
					}
				}
				continue
			}
			
			if e.eventType ==  .midiNoteMessage {
				let note = e as! MIKMIDINoteEvent
				if note.note == 105 || note.note == 106 {
					phrase = (time, text)
					phrases.append(phrase)
					time = tc.beattosec(beat: note.timeStamp)
					text = ""
				}
			}
		}
		return (phrases)
	}
}

