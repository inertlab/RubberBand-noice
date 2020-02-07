//
//  KeyPaths.swift
//  RubberBand
//
//  Created by Fernando on 5/9/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation


/// Valid KeyPaths for sorting album art
///
/// - song: Title of Song
/// - Currently only for ProDrums, in the future it needs to adapt to different instruments
enum SortKeypath {
	case song, artist, tier, score, genre, stars
	func value() -> String {
		switch self {
		case .song:
			return "title"
		case .artist:
			return "artist"
		case .tier:
			if instrument() == "prodrums" {
				return "tier.drums"
			}
			return "tier.\(instrument())"
		case .score:
			// by stat
			return "\(self.instrument()).stars"
		case .genre:
			return "genre"
		case .stars:
			// by stat
			return "\(self.instrument()).score.stars"
		}
	}
	
	func instrument() -> String {
		switch User.current.instrument {
		case .bass:
			return "bass"
		case .drums:
			return "drums"
		case .guitar:
			return "guitar"
		case .keys:
			return "keys"
		case .prodrums:
			return "prodrums"
		}
	}
}
