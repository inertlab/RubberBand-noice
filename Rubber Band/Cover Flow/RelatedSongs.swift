//
//  RelatedSongs.swift
//  RubberBand
//
//  Created by Fernando Zamora on 1/18/20.
//  Copyright © 2020 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit


final class RelatedSongs {
	static let share = RelatedSongs()
	
	let listnode 	= othersongsg?.childNode(withName: "list")!
	let artist 		= othersongsg?.childNode(withName: "artist") 	as! SKLabelNode
	let moreup 		= othersongsg?.childNode(withName: "moreup") 	as! SKLabelNode
	let moredown 	= othersongsg?.childNode(withName: "moredown") 	as! SKLabelNode
	let timemore 	= othersongsg?.childNode(withName: "time_other") as! SKLabelNode
	
	var list = [Song]()
	var nodes = [SKLabelNode]()
	
	var index = 0
	
	private let leading:CGFloat = 30
	private let ptSmall:CGFloat = 12
	private let ptLarge:CGFloat = 15
	
	/// Clears the previous list and listnode and loads a new list
	/// - Parameter artistsong: Song - CoreData entity
	func loadlist(artistsong: Song) -> Int {
		listnode!.removeAllChildren()
		list.removeAll()
		nodes.removeAll()
		
		list = smanager.allsongsfromartist(song: artistsong)
		if list.count < 2 {
			return 0
		}
		index = list.firstIndex(of: artistsong) ?? 0
		return list.count
	}
	
	func makesonglist(artist: String) {
		if nodes.count == 0 {
			self.artist.text = artist
			listsongs()
		}
			listnode?.position.y = CGFloat(index) * leading
			changechartericon(song: list[index])
			moreorless()
			updatetime()
	}
	
	func scrollup() {
		if index == nodes.count - 1 { return }
		listnode?.position.y += leading
		deselectlabel()
		index += 1
		selectlabel()
	}

	func scrolldown() {
		if index == 0 { return }
		listnode?.position.y -= leading
		deselectlabel()
		index -= 1
		selectlabel()
	}
}


private extension RelatedSongs {
	func deselectlabel() {
		nodes[index].fontColor = NSColor.white
		nodes[index].fontSize = ptSmall
	}
	
	func labelselected() {
		nodes[index].fontColor = NSColor.black
		nodes[index].fontSize = ptLarge
	}
	
	func selectlabel() {
		changechartericon(song: list[index])
		moreorless()
		updatetime()
		labelselected()
	}
	
	func updatetime() {
		timemore.text = format.string(from: list[index].length)
	}
	
	func listsongs() {
		var y:CGFloat = 0
		for song in list {
			let label = makelabel()
			nodes.append(label)
			listnode?.addChild(label)
			label.position = CGPoint(x: 0, y: y)
			label.text = song.title
			y -= leading
		}
		labelselected()
	}
	
	func makelabel() -> SKLabelNode{
		let label = SKLabelNode()
		label.fontSize = ptSmall
		label.fontName = "SFProText-Medium"
		label.verticalAlignmentMode = .center
		label.numberOfLines = 1
		return label
	}
	
	func changechartericon (song: Song) {
		let texturename = IconFile[song.icon!] ?? song.icon!
		let texture = iconAtlas.textureNamed(texturename)
		
		labelicon.texture = texture
	}
	
	func moreorless() {
		let above = index - 3
		if above > 0 {
			moreup.text = "…\(above)+"
		} else {
			moreup.text = ""
		}
		let below = list.count - 7 - index
		if below > 0 {
			moredown.text = "…\(below)+"
		} else {
			moredown.text = ""
		}
	}
}
