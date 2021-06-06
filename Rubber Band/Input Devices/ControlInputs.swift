//
//  ControlInputs.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/10/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit


/// allowed Button inputs for the game
enum Button: UInt8 {
	case green, red, yellow, blue, orange, yellow_c, blue_c, green_c, plus, minus, start, select, home, strum, up, down, left, right
	
	struct Metrics {
		let pos: GemPos, bit: Int
	}
	struct Metric {
		let posD: CGFloat, posS: CGFloat, color: NSColor
	}
	var metric: Metric {
		switch self {
		case .green, .green_c, .plus:
			return Metric(posD: -1.26	, posS: 1.6	, color: .rbGreen)
		case .red:
			return Metric(posD: 1.26	, posS: 0.8	, color: .rbRed)
		case .yellow, .yellow_c:
			return Metric(posD: 0.42	, posS: 0	, color: .rbYellow)
		case .blue, .blue_c:
			return Metric(posD: -0.42 	, posS: -0.8, color: .rbBlue)
		default:
			return Metric(posD: 0		, posS: -1.6, color: .rbOrange)
		}
	}
}

struct ButtonMetric {
	let posD: CGFloat, posS: CGFloat, color: NSColor
}

func buttonMetric(_ btn: Button) -> ButtonMetric {
	switch btn {
	case .green, .green_c, .plus:
		return ButtonMetric(posD: -1.26	, posS:  1.6, color: .rbGreen)
	case .red:
		return ButtonMetric(posD:  1.26	, posS:  0.8, color: .rbRed)
	case .yellow, .yellow_c:
		return ButtonMetric(posD:  0.42	, posS:  0	, color: .rbYellow)
	case .blue, .blue_c:
		return ButtonMetric(posD: -0.42 , posS: -0.8, color: .rbYellow)
	default:
		return ButtonMetric(posD:  0	, posS: -1.6, color: .rbOrange)
	}
}


typealias MidiCode = [UInt8:Button]
/// note config for Roland ekit TD3
let roland:MidiCode = [
	38:	.red,		// Snare (head) *
	40:	.red,		// Snare (rim)
	48:	.yellow,	// Tom 1
	45:	.blue,		// Tom 2
	41:	.green,		// Tom 3
	36:	.orange,	// Kick
	
	46:	.yellow_c, 	// Open Hi-hat (bow) *
	26:	.yellow_c, 	// Open Hi-hat (edge)
	42:	.yellow_c, 	// closed Hi-hat (bow)
	22:	.yellow_c, 	// closed Hi-hat (edge)
	
	51:	.green_c,	// Ride (bow) *
	53:	.green_c,	// Ride (edge) TD-3
	59:	.green_c,	// Ride (edge) V
	
	49:	.blue_c, 	// Crash 1 (bow) *
	55:	.blue_c 	// Crash 1 (edge)
]

typealias KeyCode = [UInt16:Button]
/// button config for Mac keyboard
var keycode = KeyCode()

/// button config for Mac keyboard
let keycodea:KeyCode = [
	38:		.red,		// j
	40:		.yellow_c,	// k
	37:		.blue_c,	// l
	41:		.green_c,	// :
	49:		.orange,	// spacebar
	34:		.yellow,	// i
	31:		.blue,		// o
	35:		.green,		// p
	24: 	.plus, 		// +
	27: 	.minus, 	// -
	36:		.start, 	// return
	1:		.select, 	// s
	0: 		.home,		// a
	123:	.left,	 	// left
	124: 	.right, 	// right
	126: 	.up, 		// up
	125:	.down, 		// down
]

/// button config for Mac keyboard
let keycode_basic:KeyCode = [
	24: 	.plus, 		// +
	27: 	.minus, 	// -
	36:		.start, 	// return
	12:		.select, 	// q
	13: 	.home,		// w
	123:	.left, 		// left
	124: 	.right, 	// right
	126: 	.up, 		// up
	125:	.down, 		// down
]

/// button config for Mac keyboard
let keycode_guitar:KeyCode = [
	0:		.green,		// j
	1:		.red,		// k
	2:		.yellow,	// l
	3:		.blue,		// :
	5:		.orange,	// '
	49:		.strum,		// spacebar
//	24: 	.plus, 		// +
]

/// button config for Mac keyboard
let keycode_drums:KeyCode = [
	38:		.red,		// j
	34:		.yellow,	// i
	40:		.yellow_c,	// k
	31:		.blue,		// o
	37:		.blue_c,	// l
	35:		.green,		// p
	41:		.green_c,	// :
	49:		.orange,	// spacebar
]

func combinekeycode(_ keycode: KeyCode) -> KeyCode {
	return keycode_basic.merging(keycode) {(old, _) in old}
}

func updatekeycode(_ inst: Instrument) {
	switch inst {
		case .drums, .prodrums:
		keycode = combinekeycode(keycode_drums)
		default:
		keycode = combinekeycode(keycode_guitar)
	}
}
