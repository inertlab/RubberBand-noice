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
import AVFoundation
import WebKit



var mainView = SCNView()


class GameViewController: NSViewController, WKUIDelegate {
	
	let rpc = DiscordRP()
	
    @IBOutlet var boxview: SCNView!
    override func viewDidLoad() {
		
        mainView = self.view as! SCNView
		mainView.scene = stagemc.currentact.scn
		
		mainView.backgroundColor = NSColor.black

		setupMidiDevice()
	
		mainView.overlaySKScene = smanager.loadingscreen.scene
		
		mainView.isPlaying = false
		mainView.autoresizesSubviews = true
//		mainView.showsStatistics = true
		
		Anal.shared.track = true
		Anal.shared.addsubview(mainView)
		
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			smanager.coverflow()
			DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
				smanager.loadingscreen.fadeout()
			}
		}
    }
	
    //    MARK: - window shit
    override func viewDidAppear() {
		super.view.window?.contentAspectRatio = NSSize(width: 1.6, height: 1)
		rpc.initRPC()
    }
	

	override func viewWillAppear() {
		if	User.current.player.config?.fullscreen == true {
			mainView.window!.toggleFullScreen(.none)
		}
	}
}


