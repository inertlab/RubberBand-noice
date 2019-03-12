//
//  SongManager.swift
//  RubberBand
//
//  Created by Fernando on 3/7/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Cocoa
import SceneKit
import SpriteKit

/// reference to the song catalog in coredata
let pc: NSPersistentContainer = {
	let container = NSPersistentContainer(name: "catalog")
//	container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
	container.loadPersistentStores(completionHandler: { (storeDescription, error) in
		if let error = error {
			
			fatalError("Unresolved error \(error)")
		}
	})
	return container
}()


/// Retrieves Song information from coredata and creates album art for menu display
class SongManager {
	let noart	= NSImage(byReferencingFile: "noart.jpg")
	/// the scnnodes containing a row of covers
	var columns = covernode.childNodes
	var coverlimit = [CGFloat]()
	var sortedby = "title"
	var cols = 0
	var sorted = [Stats]()
	/// array of the coverart, this needs to be retrieved again if songs are recataloged
	var covers = [CoverArt]()
	/// Creates and displays cover art for songs in the core library arranged by Artist
	func coverflow () {
		covers			= []
		coverlimit		= []
		sorted 			= fetchSong(sortBy: "song.title")
		
		var char:Character 	= ")"
		let index 			= String.Index(encodedOffset: 0)
		var row 			= CGFloat(1)
		var col 			= CGFloat(0)
		var scncol 			= SCNNode()
		
		for stat in sorted {
			let song = stat.song!
			let tchar = song.title![index]
			if char == ")" {
				char = tchar
			}
			if tchar == char {
				row -= 1
			}else{
				self.coverlimit.append(row)
				char 				= tchar
				row 				= 0;
				col 				+= 1
				scncol 				= makeColumn(name: "col-"+col.description)
				scncol.position.x 	= col
			}
			
			let cover = CoverArt(id: song.uuid!)
			let arturl = song.trackOf?.value(forKey: "albumArt") as! URL
			
			let art:NSImage! = NSImage(byReferencing: arturl)
			
			if art.isValid {
				cover.geometry?.firstMaterial?.diffuse.contents = art
//				cover = makeCover(albumart: art)
			}else{
				cover.geometry?.firstMaterial?.diffuse.contents = noart
				print(art)
//				cover = makeCover(albumart: noart)
			}
		
//			cover.name 			= song.uuid?.uuidString
			
			cover.position.y 	= row
			scncol.addChildNode(cover)
			covers.append(cover)
		}
//		print(sorted)
		self.resetcolumns()
	}
	
	/// Retrieves list of songs ordered by Artist or Album
	/// - parameter sortBy: sorting key: Artist or Album
	/// - Returns: An array of Song sorted by Artist or Album
	func fetchSong (sortBy: String) -> [Stats] {
		let fet:NSFetchRequest<Stats> = Stats.fetchRequest()
		let sorter = NSSortDescriptor(key: sortBy, ascending: true)
		fet.predicate = NSPredicate(format: "song != %@", "nil")
		fet.sortDescriptors = [sorter]
		fet.fetchLimit = 100
		let array = try? pc.viewContext.fetch(fet)
		return array!
	}
	
	/// Retrives song from coredata with the given ID (cover name)
	///
	/// - Parameter id: unique Int id for song - also used as name for cover (cover.name)
	/// - Returns: First song in the array of Songs found
	func fetchSongById (id: String) -> Song {
		let fetch:NSFetchRequest<Song> = Song.fetchRequest()
			fetch.predicate 	= NSPredicate(format: "uuid == %@", id)
			fetch.fetchLimit 	= 1
		let array = try? pc.viewContext.fetch(fetch)
		
//		print(array![0].uuid)
		return array![0]
	}
	
	/// Retrives song from coredata with the given ID (cover name)
	///
	/// - Parameter id: unique Int id for song - also used as name for cover (cover.name)
	/// - Returns: First song in the array of Songs found
//	func fetchStatByID (id: String) -> Stats? {
//		let fetch:NSFetchRequest<Stats> = Stats.fetchRequest()
//		fetch.predicate 	= NSPredicate(format: "songid == %@", id)
//		fetch.fetchLimit 	= 1
//		let array = try? pc.viewContext.fetch(fetch)
//		if array?.count == 0 {
//			return nil
//		}
//		return array![0]
//	}
	
	func fetchStatByID (id: String) -> Stats {
		let fetch:NSFetchRequest<Stats> = Stats.fetchRequest()
		fetch.predicate 	= NSPredicate(format: "songid == %@", id)
		fetch.fetchLimit 	= 1
		let array = try? pc.viewContext.fetch(fetch)
		if array?.count == 0 {
			return createstats(uuid: id)!
		}else{
		}
		//		print(array![0].uuid)
		return array![0]
	}
	
	/// Removes all songs from coredata and cover art from view
	func deleteCatalog() {
		let delete:NSFetchRequest<Song> = Song.fetchRequest()
//		let del = NSBatchDeleteRequest(fetchRequest: delete)
		do {
			let songarray = try pc.viewContext.fetch(delete)
			for s in songarray {
				pc.viewContext.delete(s)
			}
			try pc.viewContext.save()
		}catch let err as NSError {
			print(err)
		}
		self.removecovers()
	}
	
	/// Sorts cover flow by parameter
	///
	/// - Parameter category: sorting category; "artist" or "title", default is "title"
	func reflow (category: String = "title") {
		if self.sortedby != category {
			covernode.position.x = 0
			covernode.runAction(SCNAction.move(to: SCNVector3(0,0,0), duration: 0.5))
			self.sortedby 		= category

			self.coverlimit 	= [] // reset cover limit
			let tempcol			= self.movecoverstotempcol()
			self.sorted 		= fetchSong(sortBy: category)
			var char:Character 	= ")"
			let index 			= String.Index(encodedOffset: 0)
			var row 			= CGFloat(1)
			var col 			= CGFloat(0)
			var scncol 			= SCNNode()
			
			for stat in sorted {
				let song 	= stat.song!
				let name 	= song.value(forKey: category) as! String
				let tchar 	= name[index]
				if char == ")" {
					char = tchar
				}
				if tchar == char {
					row -= 1
				}else{
					self.coverlimit.append(row)
					char 				= tchar
					row 				= 0;
					col 				+= 1
					scncol 				= makeColumn(name: "col-"+col.description)
					scncol.position.x 	= col
				}
				
				let cover			= covers.first(where: {$0.id == song.uuid!})
//				let cover 			= tempcol.childNode(withName: song.uuid!.uuidString, recursively: false)
				cover?.position.y 	= row
				if (cover != nil) {
					scncol.addChildNode(cover!)
				} else {
					row += 1
				}
			}
			self.columns = covernode.childNodes
			tempcol.removeFromParentNode()
			coverindex = (Int(0), Array(repeating: 0, count: self.columns.count))
			self.cols = self.columns.count - 1
			animatecover(column: self.columns[coverindex.0])
		}
	}
	
	func connectsongtostats() {
		let fetstat:NSFetchRequest<Stats> = Stats.fetchRequest()
		fetstat.predicate = NSPredicate(format: "song == %@", "nil")
		
		do {
			let stats = try pc.viewContext.fetch(fetstat)
			for s in stats {
				print("the song is = " + (s.songid?.description)!)
			}
		}catch let err as NSError {
			print(err)
		}
	}
}


private extension SongManager {
	
	func createstats(uuid: String) -> Stats? {
		let stat = Stats(context: pc.viewContext)
		let song = fetchSongById(id: uuid)
		song.addToStats(stat)
		userdef.player.addToStats(stat)
		stat.songid 	= song.uuid
		stat.pindex		= userdef.player.index
		try? pc.viewContext.save()

		print("created stat line 223")
		return stat
	}

	/// Creates a single column of 3D album covers
	///
	/// - Parameter name: this is set in reflow() or coverflow()
	/// - Returns: 3D column of album covers
	func makeColumn (name: String) -> SCNNode {
		let column 		= SCNNode()
			column.name = name
		covernode.addChildNode(column)
		return column
	}
	
	/// Deletes all album art from covernode
	func removecovers () {
		for col in covernode.childNodes {
			col.removeFromParentNode()
		}
		self.resetcolumns()
	}
	
	/// creates a temporary node to hold existing album covers for resorting into new columns. this node gets discarded after used
	///
	/// - Returns: temporary albums holder
	func movecoverstotempcol () -> SCNNode {
		let tempcol = SCNNode()
		menuScene.rootNode.addChildNode(tempcol)
		for col in covernode.childNodes {
			
			for cover in col.childNodes {
				tempcol.addChildNode(cover)
			}
			col.removeFromParentNode()
		}
		return tempcol
	}
	
	/// resets all params to 0 and recounts columns and limits
	func resetcolumns() {
		covernode.position.x = 0
		self.columns 	= covernode.childNodes
		self.cols 		= self.columns.count - 1
		coverindex 		= (Int(0), Array(repeating: 0, count: self.columns.count))
	}
}



