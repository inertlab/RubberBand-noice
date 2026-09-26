	//
	//  FZMIK2.swift
	//  RubberBand
	//
	//  Created by Fernando Zamora on 6/8/19.
	//  Copyright © 2019 Artecolote. All rights reserved.
	//


import Foundation
import SceneKit

typealias TimeBtn = (time:Double, btn:Button)
typealias BtnList = [TimeBtn]
/// Sets up gem not locations etc from MIDI events
class MusicSheet {
	static let shared = MusicSheet()
	var difficultyConfig = DifficultyConfig()
	var fzmidi: FZMIDI?
	private init() {}
	
	/// Updates timesheet with the current song music sequence
	/// - Parameter url: File location of notes.mid file
	///
	/// When a new sequence is set, TimeCode gets updated here
	/// this will have to change when multiplayer is added as we don't want to conflict 2 TimeCodes
	func setSeq (url: URL) {
		if let fzmidi = FZMIDI(url: url) {
			self.fzmidi = fzmidi
		}

		self.difficultyConfig = User.current.instrument.config(diff: User.current.diff)
		setaveragetempo()
	}
	
	typealias Chord = (btns: Set<Button>, start: Double, end: Double, beats: CGFloat?)
	
	/// [Chord]
	///
	/// Chord: (btns: Set[Button], start: Double, end: Double)
	///
	/// The time values have been translated from MidiTimestamps to Seconds - if end == 0, then the note has no duration or tail. I'm using endTimeStamp instead of Duration to define where the tail ends clearly
	typealias ChordList = [Chord]
	
	/// Returns a sorted ChordList from the User current instrument selection
	func get5lanenotes() -> ChordList {
		
		var chordlist = ChordList()
		
		guard let events = fzmidi?.notes else {
			print("no events")
			return chordlist
		}
		
		var chord = Chord([], -1, 0, nil)
		var time: Float64 = -1
		
		for event in events {
			if case .note(_,_,_,let beats) = event {
				if appendSP(event) {continue}
				if let button = difficultyConfig[event.note!] {
					if event.time == time {
						chord.btns.insert(button)
						continue
					}
					if !chord.btns.isEmpty {
						chordlist.append(chord)
					}
					time = event.time
					chord = Chord([button], event.time, 0, nil)
					if beats > 0.26 {
						chord.end = event.end!
						chord.beats = CGFloat(beats) // the old way used beats instead of seconds might be bad?
					}
				}
			}
		}
		
		chordlist.append(chord)
//		not sure if sorting is needed
		return chordlist.sorted { $0.start < $1.start }
	}
	
	
	/// gets all the notes for track
	///
	/// - Returns: returns a list of timestamps and .colors
	/// this doesn't work because string instruments require endtimestamps
	func getDrumNotes() -> BtnList {
		if User.current.instrument == .drums {
			return drumnotesVanilla()
		}
		return drumnotesPro()
	}
	
	func drumnotesVanilla() -> BtnList {

		var btnlist = BtnList()
		
		guard let noteevents = fzmidi?.notes else {
			return btnlist
		}
		
		for nevent in noteevents {
			
			guard let note = nevent.note else {continue} // this no longer filters out text events
			
			if appendSP(nevent) {
				continue
			}
			
			if let button = difficultyConfig[note] {
				var timebtn = TimeBtn(nevent.time, button)
				switch button{
				case .plus:
						// in future add start time to a different note for activator tail
//					activator goes at the end of the tail
					timebtn.time = nevent.end!
				case .blue, .green, .yellow:
					// timebtn doesn't get added to list
					continue
				case .yellow_c:
					timebtn.btn = .yellow
				case .blue_c:
					timebtn.btn = .blue
				case .green_c:
					timebtn.btn = .green
				default:
					// .orange
					break
				}
				btnlist.append(timebtn)
			}
			
		}
		
		return btnlist.sorted {$0.0 < $1.0 }
	}
	
	/// retrieves drum note information with discoflips etc
	///
	/// - Returns: a tuple array with MusicTimeStamp (beat) and the ControlInput (like .yellow_c) sorted by musicstamp, small to big
	func drumnotesPro () -> BtnList {
		/// an array of Tupples [(MusicTimeStamp, Button)]
		var drumbtnlist = BtnList()
		guard var drumevents = fzmidi?.notes else {return drumbtnlist}
		
		
		drumevents.sort(by: {($0.time, $1.note!) < ($1.time, $0.note!)})
		

		var flip = false // while this is true, we flip red and yellow_c
		var yellow = 0.0
		var blue = 0.0
		var green = 0.0
		
		for event in drumevents {
			switch event {
			case .meta(let event, _):
				if let drumevent = DrumEvent(rawValue: event) {
					flip = drumevent.flip()
				}
				break;
			case .note(_,_,_,_):
				if appendSP(event) {break}
				
				if let button = difficultyConfig[event.note!] {
					var timebtn = TimeBtn(event.time, button)
					switch button {
					case .plus:
						timebtn.time = event.end!
					case .red:
						if flip {
							timebtn.btn = .yellow_c
						}
					case .yellow_c:
						if flip {
							timebtn.btn = .red
							break;
						}
						if event.time <= yellow {
							timebtn.btn = .yellow
						}
					case .blue_c:
						if event.time <= blue {
							timebtn.btn = .blue
						}
					case .green_c:
						if event.time <= green {
							timebtn.btn = .green
						}
					case .blue:
						blue = event.end!
						continue
					case .yellow:
						yellow = event.end!
						continue
					case .green:
						green = event.end!
						continue
					default:
						break;
					}
					drumbtnlist.append(timebtn)
				}
				break;
			default: //lyric
				continue
			}
		}
		return drumbtnlist.sorted(by: { $0.0 < $1.0 })
	}
	
	private func setaveragetempo() {
		var bpm = 120.0
		if let tempos = fzmidi?.tempos {
			bpm = tempos.reduce(0.0, +) / Double(tempos.count)
		}
		pace.setFPS(miditempo: round(Double(bpm)))
	}
	
	/// makes and layers beat marks on the track
	///
	/// - Note: at the end of the track beats tend to dip
	func layBeat () -> Int {
		if let beats = fzmidi?.beats {
			laybeattrack(beats)
			return (beats.count)
		}
		
		return laybeattrack()
	}
}

private extension MusicSheet {
	
	/// Checks if note is Star Power, If it is then it appends it to SP list and returns True
	/// - Parameter n: midi note event
	func appendSP (_ event: NoteEvent) -> Bool {
		if event.note == 116 {
			stagemc.track.sp.starnotes.append(([.plus], event.time, event.end!, nil))
			return true
		}
		return false
	}
	
	func laybeattrack(_ beats: NoteEvents) {
		for beat in beats {
			if let note = beat.note {
				var line: SCNNode
				if note == 12 {
					line = gemmaker.beat.fat.clone()
				} else {
					line = gemmaker.beat.thin.clone()
				}
				line.position.z = CGFloat(beat.time) * pace.fps
				stagemc.track.hwy.beatlines.addChildNode(line)
			}
		}
	}
	
	func laybeattrack() -> Int {
		let length = fzmidi!.getmusiclength()
		let beats = Int(length.beats)
		let bps = length.beats / length.seconds
		for beat in 0...beats {
			var line: SCNNode
			let z = Double(beat) * bps * pace.fps
			if beat % 4 != 3 {
				line = gemmaker.beat.fat.clone()
			} else {
				line = gemmaker.beat.thin.clone()
			}
			line.position.z = z
			stagemc.track.hwy.beatlines.addChildNode(line)
		}
		return beats
	}
}

