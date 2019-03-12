//
//  ControlInputs.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/10/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation


struct ControlInputs {
	var roland = [Controller:UInt8]()
	init(){
		self.roland[.blue] = 1
	}
}

let roland:[Controller:UInt8] = [
	.red		: 38,
	.yellow		: 48,
	.blue 		: 45,
	.green		: 41,
	.orange		: 36,
	.yellow_2	: 46,
	.blue_2		: 52,
	.green_2	: 49
]


enum Controller {
	case red, yellow, blue, green, orange, yellow_2, blue_2, green_2
}


