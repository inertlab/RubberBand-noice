//
//  GameViewController.swift
//  Rubber Band
//
//  Created by Fernando on 2/8/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit
import MIKMIDI
import AVFoundation
import WebKit



var mainView = SCNView()

let home	= NSHomeDirectory()


class GameViewController: NSViewController, WKUIDelegate {
	
	let rpc = DiscordRP()
//	let p = FPlayer()
	
    @IBOutlet var boxview: SCNView!
    override func viewDidLoad() {
		
//		let file = AudioFileContext(forFile: URL(fileURLWithPath: "/Users/fernando/Downloads/noice/_done/The Rembrandts - I'll Be There for You/guitar.ogg"))
//		p.play(fileContext: file!)
//
//		print("file position is ", p.seekPosition)
		
		
        mainView 		= self.view as! SCNView
		mainView.scene 	= SCNScene()
		
		mainView.backgroundColor 	= NSColor.black

		setupMidiDevice()
		mainView.overlaySKScene 	= loadingscreen
		loadingscreen?.scaleMode 	= .aspectFill
		
		mainView.isPlaying			= false
		mainView.autoresizesSubviews = true
//		mainView.showsStatistics 	= true
		
//		Anal.shared.track = true
		Anal.shared.addsubview(mainView)
		
		if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
			if let label = loadingscreen?.childNode(withName: "version") {
				(label as! SKLabelNode).text = "version \(version)"
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			smanager.coverflow()

			DispatchQueue.main.asyncAfter(deadline: .now() + 3.5 ) {
				stagemc.loadmenu()
				updatekeycode(User.current.instrument)
				menuOverlay?.scaleMode = .aspectFit
			}
		}
		
		
    }
	
    //    MARK: - window shit
    override func viewDidAppear() {
		super.viewDidAppear()
		super.view.window?.contentAspectRatio = NSSize(width: 1.6, height: 1)
		rpc.initRPC()
    }
}

fileprivate func resetDatabase() {
	do {
		try pc.persistentStoreCoordinator.managedObjectModel.entities.forEach { (entity) in
			if let name = entity.name {
				let fetch 	= NSFetchRequest<NSFetchRequestResult>(entityName: name)
				let request = NSBatchDeleteRequest(fetchRequest: fetch)
				try pc.viewContext.execute(request)
			}
		}
		try pc.viewContext.save()
	} catch {
		print("error resenting the database: \(error.localizedDescription)")
	}
}

extension NSPersistentStoreCoordinator {
	func destroyPersistentStore(type: String) -> NSPersistentStore? {
		guard
			let store 		= persistentStores.first(where: { $0.type == type }),
			let storeURL 	= store.url
			else {
				return nil
		}
		try? destroyPersistentStore(at: storeURL, ofType: store.type, options: nil)
		return store
	}
}

