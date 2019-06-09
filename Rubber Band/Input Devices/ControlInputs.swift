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
enum Button: Int {
	case red, yellow, blue, green, orange, yellow_c, blue_c, green_c, plus, minus, start, select, home
	
	struct Metrics {
		let pos: GemPos, bit: Int
	}
	/// metrics - notation, position, color, instrument name, gem shape
	var metrics: Metrics {
		switch self {
		case .orange:
			return Metrics(pos: .o, bit: GemBit.orange	)
		case .red:
			return Metrics(pos: .r, bit: GemBit.red		)
		case .yellow_c:
			return Metrics(pos: .y, bit: GemBit.yelloc	)
		case .blue_c:
			return Metrics(pos: .b, bit: GemBit.bluec	)
		case .green_c:
			return Metrics(pos: .g, bit: GemBit.greenc	)
		case .yellow:
			return Metrics(pos: .y, bit: GemBit.yellow	)
		case .blue:
			return Metrics(pos: .b, bit: GemBit.blue	)
		case .plus:
			return Metrics(pos: .g, bit: GemBit.activate)
		default:
			return Metrics(pos: .g, bit: GemBit.green	)
		}
	}
}

/// note config for Roland ekit TD3
let roland:[UInt8:Button] = [
	38:	.red,
	48:	.yellow,
	45:	.blue,
	41:	.green,
	36:	.orange,
	46:	.yellow_c,
	52:	.blue_c,
	49:	.green_c
]

/// button config for Mac keyboard
let keycode:[UInt16:Button] = [
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
	123:	.blue_c	, 	//left key
	124: 	.green_c, 	//right key
	126: 	.yellow, 	// up key
	125:	.blue, 		//down key
]
