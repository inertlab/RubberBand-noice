//
//  TextureMover.swift
//  RubberBand
//
//  Created by Fernando Zamora on 5/23/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

class TextureMover {
	static let shared 	= TextureMover()
	
	let difInitial 	= menutext.detailnode?.childNode(withName: "easy", recursively: false)
	let disklabel 	= smanager.record.node.childNode(withName: "label", recursively: false)
	let labelicon 	= menuOverlay?.childNode(withName: "icon") as! SKSpriteNode

	let starmat 	= menutext.detailnode?.geometry?.firstMaterial
	
	private init(){
		smanager.delegate = self
		User.current.delegate = self
	}
	
	/// updates the star texture by using the selected stat
	func updateStars() {
		if let stat = ScoreManager.selectStat(smanager.selected.song) {
			updateStars(stat)
		} else {
			nofc()
			noscore()
		}
	}
	
	/// updates the star texture by stat
	/// - Parameter stat: the stat to get score from
	func updateStars(_ stat: Stats) {
		updateStars(score: User.current.instrument.getscore(stat))
	}
	
	/// updates the star texture by score
	/// - Parameter score: Score
	func updateStars(score: Score?) {
		let starmat = menutext.detailnode?.geometry?.firstMaterial
		
		if score == nil {
			difInitial?.opacity = 0
			starmat?.transparent.contentsTransform.m41 = getm41(0)
		} else {
			let ms = getm41m42(score!.difficulty)
			difInitial?.geometry?.firstMaterial?.transparent.contentsTransform.m41 = ms.m41
			difInitial?.geometry?.firstMaterial?.transparent.contentsTransform.m42 = ms.m42
			
			difInitial?.opacity = 1
			starmat?.transparent.contentsTransform.m41 = getm41(score!.stars)
			//		this should include a scenario for a perfect score aka 7 Stars
			if score!.stars > 5 {
				starmat?.diffuse.contents = NSColor.rbYellow
			} else {
				starmat?.diffuse.contents = NSColor.rblitegray
			}
			
			// make this into a sep func in future
			// need to remove ref to smanager.
			switch score!.fc {
			case 3:
				// gold record
				fced()
			case -1:
				nofc()
			default:
				fcedsilver()
			}
		}
	
	}
	
	/// resets star texture to zero if no score was found
	func noscore() {
		difInitial?.opacity = 0
		starmat?.diffuse.contents = NSColor.rblitegray
		starmat?.transparent.contentsTransform.m41 = getm41(0)
	}
	
	/// updates the tier on the album record
	/// - Parameter diff: the tier
	/// - Parameter node: the node
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
	
	func nofc () {
		smanager.record.node.geometry?.firstMaterial?.diffuse.intensity = 0.25
		smanager.record.node.geometry?.firstMaterial?.multiply.intensity = 0
	}
	
	func fced () {
		smanager.record.node.geometry?.firstMaterial?.diffuse.intensity = 1
		smanager.record.node.geometry?.firstMaterial?.multiply.intensity = 1
	}
	
	func fcedsilver () {
		smanager.record.node.geometry?.firstMaterial?.diffuse.intensity = 1.4
		smanager.record.node.geometry?.firstMaterial?.multiply.intensity = 0
	}
	
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


extension TextureMover: SongManagerDelegate, UserDelegate {
	func changedinstrument(tier: Int16) {
		updateTier(tier: tier)
		updateStars()
	}
	
	func newsongselected(song: Song) {
		updatechartericon(icon: song.icon!)
		updateStars()
		updateTier()
	}
}
