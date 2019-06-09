//
//  TextureMover.swift
//  RubberBand
//
//  Created by Fernando Zamora on 5/23/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit


class TextureMover {
	static let shared =  TextureMover()
	private init(){}
	
	func changeStars(_ stars:Int16) {
		menutext.detailnode?.geometry?.firstMaterial?.transparent.contentsTransform.m41 = getm41(stars)
	}

	func changeDifficulty(diff:Int16, node: SCNNode) {
		let transform = difficulty(diff: selectedSong.tier?.drums ?? 0)
		node.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = transform.m41
		node.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = transform.m42
	}
	
	func offsetright (node: SCNNode) {
		node.geometry?.firstMaterial?.diffuse.contentsTransform.m41 += 0.02
	}
}

private extension TextureMover {
	
	
	func getm41(_ stars:Int16) -> CGFloat {
		switch stars {
		case 1:
			return 0.1666
		case 2:
			return 0.3333
		case 3:
			return 0.8333
		case 4:
			return 0.6666
		case 5, 6:
			return 0.8333
		default:
			return 0.0
		}
	}
	
	func difficulty(diff:Int16) -> (m41:CGFloat, m42:CGFloat) {
		switch diff {
		case 0: // tier: novice
			return (0, 0)
		case 1:
			return (0.333, 0)
		case 2:
			return (0.666, 0)
		case 3:
			return (0, 0.333)
		case 4:
			return (0.333, 0.333)
		case 5:
			return (0.666, 0.333)
		case 6: // tier: devil
			return (0, 0.666)
		default:
			return (0.333, 0.666) // case = nil and -1
		}
	}
}
