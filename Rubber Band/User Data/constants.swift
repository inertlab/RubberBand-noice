//
//  constants.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/9/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation


enum Difficulty:Int16 {
	case easy, medium, hard, expert
	mutating func next () {
		self =  Difficulty(rawValue: rawValue + 1) ?? .easy
		labelDiff.text = self.text()
	}
	func config() -> InstConfig {
		switch self {
		case .easy:
			return drumsEasy
		case .medium:
			return drumsMedium
		case .hard:
			return drumsHard
		case .expert:
			return drumsExpert
		}
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
}

enum Instrument: String {
	case drums, prodrums, guitar
}
