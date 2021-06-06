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
	
    @IBOutlet var boxview: SCNView!
    override func viewDidLoad() {
		
        mainView 			= self.view as! SCNView
		mainView.scene 		= SCNScene()
		
		mainView.backgroundColor 	= NSColor.black

		setupMidiDevice()
		mainView.overlaySKScene 	= loadingscreen
		loadingscreen?.scaleMode 	= .aspectFit
		
		mainView.isPlaying			= false
		mainView.autoresizesSubviews = true
//		mainView.showsStatistics 	= true
		
//		Anal.shared.track = true
		Anal.shared.addsubview(mainView)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			smanager.coverflow()

			DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
				stagemc.loadstage()
				updatekeycode(User.current.instrument)
				lebelInst.text 	= User.current.instrument.name()
				menuOverlay?.scaleMode = .aspectFit
			}
		}
    }
	
    //    MARK: - window shit
    override func viewDidAppear() {
		super.viewDidAppear()
		super.view.window?.contentAspectRatio = NSSize(width: 1.6, height: 1)
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
		print("this happened")
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
