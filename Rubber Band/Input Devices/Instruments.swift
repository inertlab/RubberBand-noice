//
//  Instruments.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/8/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation


typealias InstConfig = [UInt8: Button]
// MARK: - Drum difficulties

/// Drums - Expert Difficulty
let drumsExpert:[UInt8: Button] = [
	96	: .orange,
	97 	: .red,
	98 	: .yellow_c,
	99	: .blue_c,
	100	: .green_c,
	110	: .yellow,
	111 : .blue,
	112	: .green,
	120	: .plus
]

/// Drums - Hard Difficulty
let drumsHard:[UInt8: Button] = [
	84	: .orange,
	85 	: .red,
	86 	: .yellow_c,
	87	: .blue_c,
	88	: .green_c,
	110	: .yellow,
	111 : .blue,
	112	: .green,
	120	: .plus
]

/// Drums - Medium Difficulty
let drumsMedium:[UInt8: Button] = [
	72	: .orange,
	73 	: .red,
	74 	: .yellow_c,
	75	: .blue_c,
	76	: .green_c,
	110	: .yellow,
	111 : .blue,
	112	: .green,
	120	: .plus //star activator
]

/// Drums - Easy Difficulty
let drumsEasy:[UInt8: Button] = [
	60	: .orange,
	61 	: .red,
	62 	: .yellow_c,
	63	: .blue_c,
	64	: .green_c,
	110	: .yellow,
	111 : .blue,
	112	: .green,
	120	: .plus
]
