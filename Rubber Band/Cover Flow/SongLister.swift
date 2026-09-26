//
//  SongList.swift
//  noice
//
//  Created by Fernando Zamora on 3/17/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

// this should replace history and related songs
import SpriteKit

/// This is identical to Related Songs but the list is updated with history
final class SongLister {
	
	private enum Mode {
		case history, recentlyadded, relatedsongs
		func description () -> String {
			switch self {
			case .history:
				return "Play History"
			case .recentlyadded:
				return "Last Added"
			default:
				return "Songs By"
			}
		}
	}
	
	static let shared = SongLister()
	
	var ready 		= false
	let node		= menuOverlay?.childNode(withName: "relatedsongs")
	let listnode 	= menuOverlay?.childNode(withName: "relatedsongs/list")!
	let artist 		= menuOverlay?.childNode(withName: "relatedsongs/artist") 		as! SKLabelNode
	let moreup 		= menuOverlay?.childNode(withName: "relatedsongs/moreup") 		as! SKLabelNode
	let moredown 	= menuOverlay?.childNode(withName: "relatedsongs/moredown") 	as! SKLabelNode
	let timemore 	= menuOverlay?.childNode(withName: "relatedsongs/time_other") 	as! SKLabelNode
	let stars 		= menuOverlay?.childNode(withName: "relatedsongs/stars") 		as! SKLabelNode
	let diff 		= menuOverlay?.childNode(withName: "relatedsongs/difficulty")	as! SKLabelNode
	let description = menuOverlay?.childNode(withName: "relatedsongs/description") 	as! SKLabelNode
	let countlabel  = menuOverlay?.childNode(withName: "details/morelabel") 		as! SKLabelNode
	
	private var stats = [Stats]()
	private var nodes = [SKLabelNode]()
	var songs = [Song]()
	
	/// currently selected song
	var song:Song? = nil
	
	private var index = 0
	private var indexes = [Mode: Int]()
	private var limit = 0
	
	//MARK: Styles
//	controls the size of the song list
	private let leading:CGFloat = 65 //todo: make relative to screen height
	private let ptSmall:CGFloat = 22
	private let ptLarge:CGFloat = 26
	private var mode = Mode.relatedsongs
	

	func songhistory() {
		mode = .history
		description.text = mode.description()
		index = indexes[mode] ?? 0
		listnode?.removeAllChildren()
		nodes.removeAll()
		listhistory()
		movelist()
		selectlabel()
	}
	
	func recentlyadded() {
		mode = .recentlyadded
		description.text = mode.description()
		index = indexes[mode] ?? 0
		listnode?.removeAllChildren()
		nodes.removeAll()
		
		songs = smanager.fetchSongs(sortBy: "modfied", 100, false)
		limit = songs.count
		if songs.isEmpty {return}

		var y:CGFloat = 0
		for song in songs {
			let label = makelabel()
			nodes.append(label)
			listnode?.addChild(label)
			label.position = CGPoint(x: 0, y: y)
			label.text = song.title!
			y -= leading
		}
		movelist()
		selectlabel()
	}
	
	/// displays a list of related songs by the same artist. the list of songs needs to be preloaded before running
	/// - Parameter artist: Artist name
	func relatedsongs(_ artist: String) {
		mode = .relatedsongs
		description.text = mode.description()
		if nodes.count == 0 {
			self.artist.text = artist
			listrelatedsongs()
		}
			movelist()
			moreorless()
			updatetime()
			selectlabel()
	}
	
	/// Clears the previous list and listnode and loads a new list
	/// - Parameter artistsong: Song - CoreData entity
	func loadreleatedsongs(artistsong: Song) {
		ready = true
		listnode?.removeAllChildren()
		songs.removeAll()
		nodes.removeAll()
		
		songs = smanager.allsongsfromartist(song: artistsong)
		if songs.count < 2 {
			ready = false
			countlabel.text = ""
			return
		}
		countlabel.text = "…\(songs.count)+"
		index = songs.firstIndex(of: artistsong) ?? 0
	}
	
	func scrollup() {
		if nodes.count < 2 { return }
		deselectlabel()
		if index == nodes.count - 1 {
		// seelction is at the end of the list
			wraparoundup()
			return
		}
		listnode?.removeAllActions()
		index += 1
		movelist()
		selectlabel()
	}

	func scrolldown() {
		if nodes.count < 2 { return }
		deselectlabel()
		if index == 0 {
			wraparounddown()
			return
		}
		listnode?.removeAllActions()
		index -= 1
		movelist()
		selectlabel()
	}
}

private extension SongLister {
	
	func movelist() {
		listnode?.position.y = CGFloat(index) * leading - 10
	}
	
	func wraparoundup() {
		index = 0
		if nodes.count < 4 {
			listnode?.position.y = 0
		} else {
			listnode?.run(SKAction.moveBy(x: 0, y: 120, duration: 0.10)) {
				self.listnode?.position.y = -180
				self.listnode?.run(SKAction.moveTo(y: 0, duration: 0.10))
				self.selectlabel()
			}
		}
	}
	
	func wraparounddown() {
		index = nodes.count - 1
		let posy = leading * CGFloat(index)
		if nodes.count < 4 {
			listnode?.position.y = posy
		} else {
			listnode?.run(SKAction.moveBy(x: 0, y: -180, duration: 0.13)) {
				self.listnode?.position.y = posy + 120
				self.listnode?.run(SKAction.moveTo(y: posy, duration: 0.07))
				self.selectlabel()
			}
		}
	}
	
	func deselectlabel() {
		nodes[index].fontColor = NSColor.white
		nodes[index].fontSize = ptSmall
	}
	
	func labelselected() {
		nodes[index].fontColor = NSColor.black
		nodes[index].fontSize = ptLarge
	}
	
	func selectlabel() {
		indexes[mode] = index
		switch mode {
		case .history:
			song = stats[index].song!
			artist.text = stats[index].song!.artist
			updatestars(stat: stats[index])
		case .recentlyadded:
			song = songs[index]
			artist.text = song!.artist
			updatestars(song: song!)
		default:
			// this one doesn't change the artists label
			song = songs[index]
			updatestars(song: song!)
		}
		
		TextureMover.shared.updatechartericon(icon: song?.icon ?? "")
		moreorless()
		updatetime()
		labelselected()
	}
	
	func updatetime() {
		switch song?.length {
		case nil, 0:
			timemore.text = ""
		default:
			timemore.text = dateformat.string(from: song!.length)
		}
	}

	func updatestars(song: Song)  {
		if let stat = (song.stats as! Set<Stats>).first(where: {$0.setby == User.current.player}){
			updatestars(stat: stat)
		} else {
			stars.text = "• • • • •"
			diff.text = ""
		}
	}
	
	func updatestars(stat: Stats)  {
		if let score = User.current.instrument.getscore(stat) {
			diff.text = Difficulty(rawValue: score.difficulty)?.text()
			switch score.stars {
			case 1:
				stars.text = "• • • • 􀋅"
			case 2:
				stars.text = "• • • 􀋅􀋅"
			case 3:
				stars.text = "• • 􀋅􀋅􀋅"
			case 4:
				stars.text = "• 􀋅􀋅􀋅􀋅"
			case 5:
				stars.text = "􀋅􀋅􀋅􀋅􀋅"
			case 6:
				stars.text = "􀋆􀋆􀋆􀋆􀋆"
			default:
				stars.text = "• • • • •"
			}
		} else {
			stars.text = "• • • • •"
			diff.text = ""
		}
	}
	// ☆􀋆􀋅􀋆☆􀋆􀋆☆☆
	
	/// creates sklabel list in menu from an array of stats
	func listhistory() {
		stats = User.current.player.stats?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: false)]) as! [Stats]
		var y:CGFloat = 0
		if stats.count == 0 {return}
		var limit = 100
		for stat in stats {
			if let song = stat.song {
				limit -= 1
				let label = makelabel()
				nodes.append(label)
				listnode?.addChild(label)
				label.position = CGPoint(x: 0, y: y)
				label.text = song.title!
				y -= leading
				if limit == 0 { break }
			}
		}
		self.limit = nodes.count
	}
	
	/// list of songs is loaded prior to running this
	func listrelatedsongs() {
		var y:CGFloat = 0
		limit = songs.count
		for song in songs {
			let label = makelabel()
			nodes.append(label)
			listnode?.addChild(label)
			label.position = CGPoint(x: 0, y: y)
			label.text = song.title
			y -= leading
		}
	}
	
	/// Makes an SKLabelNode for list items
	/// - Returns: SKLabelNode
	func makelabel() -> SKLabelNode{
		let label = SKLabelNode()
		label.fontSize = ptSmall
		label.fontName = "SFProText-Medium"
		label.verticalAlignmentMode = .baseline
		label.numberOfLines = 1
		label.preferredMaxLayoutWidth = 800 //to do: Make dynmic - should be relative to screen
		label.lineBreakMode = .byTruncatingMiddle
		return label
	}
	
	func moreorless() {
		let above = index - 3
		if above > 0 {
			moreup.text = "…\(above)+"
		} else {
			moreup.text = ""
		}
		let below = limit - 7 - index
		if below > 0 {
			moredown.text = "…\(below)+"
		} else {
			moredown.text = ""
		}
	}
}

