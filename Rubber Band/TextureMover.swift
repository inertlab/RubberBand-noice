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
	static let shared 	= TextureMover()
	let difInitial 		= menutext.detailnode?.childNode(withName: "easy", recursively: false)
	let disklabel 		= smanager.record.node.childNode(withName: "label", recursively: false)
	private init(){}
	
	func updateStars() {
		if let stat = scorekeeper.selectStat(smanager.selected.song) {
			updateStars(stat)
			difInitial?.opacity = 1
		} else {
			difInitial?.opacity = 0
			updateStars(0, dif: 0)
		}
	}
	
	func updateStars(_ stat: Stats) {
		updateStars(User.current.instrument.getstars(stat), dif: User.current.instrument.getscoredif(stat))
	}
	
	func updateStars(_ stars:Int16, dif: Int16) {
//		print(stars)
		let starmat = menutext.detailnode?.geometry?.firstMaterial
		starmat?.transparent.contentsTransform.m41 = getm41(stars)
		let ms = getm41m42(dif)
		difInitial?.geometry?.firstMaterial?.transparent.contentsTransform.m41 = ms.m41
		difInitial?.geometry?.firstMaterial?.transparent.contentsTransform.m42 = ms.m42
		if stars > 5 {
			starmat?.diffuse.contents = NSColor.rbYellow
		} else {
			starmat?.diffuse.contents = NSColor.rblitegray
		}
	}

	func changeDifficulty(diff:Int16, node: SCNNode) {
		let transform = difficulty(diff: diff)
		node.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = transform.m41
		node.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = transform.m42
	}
	
	func updateTier() {
		updateTier(tier: User.current.instrument.gettier())
	}
	
	func updateTier(tier: Int16) {
		let transform = difficulty(diff: tier)
		disklabel!.geometry?.firstMaterial?.diffuse.contentsTransform.m41 = transform.m41
		disklabel!.geometry?.firstMaterial?.diffuse.contentsTransform.m42 = transform.m42
	}
	
	func offsetright (node: SCNNode) {
		node.geometry?.firstMaterial?.diffuse.contentsTransform.m41 += 0.02
	}
	
	func updatechartericon (icon: String) {
		let texturename = IconFile[icon] ?? icon
		let texture = iconAtlas.textureNamed(texturename)
		labelicon.texture = texture
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
			return 0.5
		case 4:
			return 0.6666
		case 5, 6, 7:
			return 0.8333
		default:
			return 0.0
		}
	}
	
	func getm41m42(_ diff:Int16) -> (m41:CGFloat, m42:CGFloat) {
		switch diff {
		case 0: // tier: novice
			return (0, 0)
		case 1:
			return (0.5, 0)
		case 2:
			return (0, 0.5)
		case 3:
			return (0.5, 0.5)
		default:
			return (0, 0) // case = nil and -1
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
