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
			return "song.title"
		case .artist:
			return "song.artist"
		case .tier:
			return "song.tier.drums"
		case .score:
			return "prodrums.stars"
		case .genre:
			return "song.genre"
		case .stars:
			return "prodrums.score.stars"
		}
	}
}
