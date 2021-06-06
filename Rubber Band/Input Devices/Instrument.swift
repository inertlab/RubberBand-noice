//
//  constants.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/9/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation

/// extend to different handle different diffs later
enum DrumEvent: String {
	typealias RawValue = String
	case 	mix3d0		= "[mix 3 drums0]" ,
			mix3d1 		= "[mix 3 drums1]" ,
			mix3d2 		= "[mix 3 drums2]" ,
			mix3d3 		= "[mix 3 drums3]" ,
			mix3d4 		= "[mix 3 drums4]" ,
			mix3d0d 	= "[mix 3 drums0d]",
			mix3d1d		= "[mix 3 drums1d]",
			mix3d2d 	= "[mix 3 drums2d]",
			mix3d3d 	= "[mix 3 drums3d]",
			mix3d4d 	= "[mix 3 drums4d]"
	func flip() -> Bool {
		switch self {
		case .mix3d0d, .mix3d1d, .mix3d2d, .mix3d3d, .mix3d4d:
			return true
		default:
			return false
		}
	}
	func noflip() -> Bool {
		switch self {
		case .mix3d0, .mix3d1, .mix3d2, .mix3d3, .mix3d4:
			return true
		default:
			return false
		}
	}
}


enum Difficulty:Int16 {
	case easy, medium, hard, expert
	mutating func next () {
		self =  Difficulty(rawValue: rawValue + 1) ?? .easy
		labelDiff.text = self.text()
	}
	
	mutating func previous () {
		self =  Difficulty(rawValue: rawValue - 1) ?? .expert
		labelDiff.text = self.text()
	}
	
	func text() -> String {
		switch self {
		case .easy:
			return "Easy Peasy"
		case .medium:
			return "Middle"
		case .hard:
			return "Hard Rock"
		case .expert:
			return "Expert"
		}
	}
	
	func short() -> String {
		switch self {
		case .easy:
			return "E"
		case .medium:
			return "M"
		case .hard:
			return "H"
		case .expert:
			return "X"
		}
	}
	
	func noflipevent() -> String {
		switch self {
		case .easy:
			return "[mix 0 drums0]"
		case .medium:
			return "[mix 1 drums0]"
		case .hard:
			return "[mix 2 drums0]"
		default:
			return "[mix 3 drums0]"
		}
	}
	
	/// doesn't cover all disco flip cases like [mix 3 drums3d]
	func flipevent() -> String {
		switch self {
		case .easy:
			return "[mix 0 drums0d]"
		case .medium:
			return "[mix 1 drums0d]"
		case .hard:
			return "[mix 2 drums0d]"
		default:
			return "[mix 3 drums0d]"
		}
	}
}


/// The playable instruments
enum Instrument: Int16 {
	case drums, prodrums, guitar, bass, keys
	
	mutating func next () {
		self = Instrument(rawValue: rawValue + 1) ?? .drums
	}
	
	mutating func previous () {
		self = Instrument(rawValue: rawValue - 1) ?? .keys
	}
	
	func gettier() -> Int16 {
		switch self {
		case .drums, .prodrums:
			return smanager.selected.song.tier!.drums
		case .bass:
			return smanager.selected.song.tier!.bass
		case .guitar:
			return smanager.selected.song.tier!.guitar
		case .keys:
			return smanager.selected.song.tier!.keys
		}
	}
	
	func getstars(_ stat: Stats) -> Int16 {
		return getscore(stat)?.stars ?? 0
	}
	
	func getscoredif(_ stat: Stats) -> Int16 {
		return getscore(stat)?.difficulty ?? 0
	}
	
	/// Retrieves a Score entity from coreData for the selected instrument
	/// - Parameter stat: Stats entity for current song
	func getscore(_ stat: Stats) -> Score? {
		return (stat.scores as! Set<Score>).first(where: {$0.instrument == self.rawValue}) ?? nil
	}
	
	func name() -> String {
		switch self {
		case .drums:
			return "Vanilla Drums"
		case .prodrums:
			return "Pro Drums"
		case .guitar:
			return "Plastic Guitar"
		case .keys:
			return "Casio Lite"
		case .bass:
			return "Bass"
		}
	}
	/// returns the track name to retrive from MIDI file
	///
	/// - Returns: MIDI track name - ie: "PART BASS"
	func track() -> TrackName {
		switch self {
		case .drums, .prodrums:
			return .drums
		case .guitar:
			return .guitar
		case .bass:
			return .bass
		case .keys:
			return .keys
		}
	}
	
	/// Maps the notes for the current instrument with the Input Controller
	///
	/// - Parameter diff: Song difficulty (default, the User's set difficulty
	/// - Returns: The instrument note input config Dictionary for each difficulty
	func config(diff: Difficulty) -> DifficultyConfig {
		switch self {
		case .prodrums, .drums:
			switch diff {
			case .easy:
				return drumsEasy
			case .medium:
				return drumsMedium
			case .hard:
				return drumsHard
			case .expert:
				return drumsExpert
			}
		default:
			switch diff {
			case .easy:
				return fiveEasy
			case .medium:
				return fiveMedium
			case .hard:
				return fiveHard
			case .expert:
				return fiveExpert
			}
		}
	}
}

/// MIDI Track part name
///
enum TrackName: String {
	case drums 	= "PART DRUMS",
		 bass 	= "PART BASS",
		 guitar = "PART GUITAR",
		 keys 	= "PART KEYS",
		 vocals = "PART VOCALS",
		 beat 	= "BEAT",
		 events = "EVENTS"
}
