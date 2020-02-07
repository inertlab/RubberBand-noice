//
//  Instruments.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/8/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation

/// The midi notes representing every diff in every intrument
typealias DifficultyConfig = [UInt8: Button]

// MARK: - 5Lane difficulties
/// 5Lane Expert Difficulty
let fiveExpert:[UInt8: Button] = [
	96	: .green,
	97 	: .red,
	98 	: .yellow,
	99	: .blue,
	100	: .orange
]

/// 5Lane Hard Difficulty
let fiveHard:[UInt8: Button] = [
	84	: .green,
	85 	: .red,
	86 	: .yellow,
	87	: .blue,
	88	: .orange
]

/// 5Lane Medium Difficulty
let fiveMedium:[UInt8: Button] = [
	72	: .green,
	73 	: .red,
	74 	: .yellow,
	75	: .blue,
	76	: .orange
]

/// 5Lane Easy Difficulty
let fiveEasy:[UInt8: Button] = [
	60	: .green,
	61 	: .red,
	62 	: .yellow,
	63	: .blue,
	64	: .orange
]


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

/// Ptodrums - Medium Difficulty
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

/// drums - Easy Difficulty
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
