//
//  GemBit.swift
//  noice
//
//  Created by fernando on 2/21/22.
//  Copyright © 2022 Artecolote. All rights reserved.
//

import Foundation



/// Deprecated
///
/// still used by pianostage. update keys before deleting
struct GemBit {
	static let green 	= 1 << 0
	static let red 		= 1 << 1
	static let yellow 	= 1 << 2
	static let blue 	= 1 << 3
	static let orange 	= 1 << 4
	static let greenc	= 1 << 5
	static let yelloc	= 1 << 6
	static let bluec	= 1 << 7
	static let tail 	= 1 << 8
	static let dead		= 1 << 9
	static var activate:Int{
		return self.green | self.greenc
	}
	static let cymbals  = [GemBit.yelloc, GemBit.bluec, GemBit.greenc]
	static func assign(_ btn: Button) -> Int {
		switch btn {
		case .blue:
			return self.blue
		default:
			return self.blue
		}
	}
}
