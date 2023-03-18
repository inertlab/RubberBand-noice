//
//  DrumKit.swift
//  noice
//
//  Created by fernando on 2/21/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

//import Foundation

/// Describes a Drumkit Controller
///	## Raw Names
/// the drumkit parts (bass, snare, etc)
/// ## Raw Values
/// Midi Notes representing each instrument in the song.mid file ("97" "98")
/// - Note: Midi Notes do not match midi notes sent from instrument
//enum DrumKit: String {
//	case o_bass = "96"	, r_snare 	= "97"
//	case y_hihat = "98"	, b_ride 	= "99"	, g_crash 	= "100" 	// cymbals
//	case y_tom 	= "110"	, b_tom 	= "111"	, g_tom 	= "112" 	// toms
//	/// Drumkit Attributes
//	/// # Atributtes
//	/// ## pos = horizontal position on highway (based on color)
//	///	## color = controller color (derrived from rb instruments)
//	/// ## note = Musical notation in flats (not sharps)
//	struct Metrics {
//		let pos: GemPos, color: NSColor, note: MidiNote, bit: Int
//	}
//	/// metrics - notation, position, color, instrument name, gem shape
//	var metrics: Metrics {
//		switch self {
//		case .o_bass:
//			return Metrics(pos: .o, color: .rbOrange, note: .C6	, bit: GemBit.orange)
//		case .r_snare:
//			return Metrics(pos: .r, color: .rbRed 	, note: .Db6, bit: GemBit.red	)
//		case .y_hihat:
//			return Metrics(pos: .y, color: .rbYellow, note: .D6	, bit: GemBit.yelloc)
//		case .b_ride:
//			return Metrics(pos: .b, color: .rbBlue 	, note: .Eb6, bit: GemBit.bluec	)
//		case .g_crash:
//			return Metrics(pos: .g, color: .rbGreen , note: .E6	, bit: GemBit.greenc)
//		case .y_tom:
//			return Metrics(pos: .y, color: .rbYellow, note: .D7	, bit: GemBit.yellow)
//		case .b_tom:
//			return Metrics(pos: .b, color: .rbBlue	, note: .Eb7, bit: GemBit.blue	)
//		case .g_tom:
//			return Metrics(pos: .g, color: .rbGreen , note: .E7	, bit: GemBit.green	)
//		}
//	}
//}


/// not used - reference only
//enum MidiNote: String {
//	case C6 = "96", Db6 = "97", D6 = "98", Eb6 = "99", E6 = "100", D7 = "110", Eb7 = "111", E7 = "112"
//}
