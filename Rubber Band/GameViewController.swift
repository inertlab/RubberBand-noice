//
//  GameViewController.swift
//  Rubber Band
//
//  Created by Fernando on 2/8/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SceneKit
import SpriteKit
import MIKMIDI
import AVFoundation
import WebKit



var mainView 		= SCNView()

let drumScene 		= SCNScene(named: "art.scnassets/scns/highway.scn")!
var box = SCNNode()

let home	 = NSHomeDirectory()

class GameViewController: NSViewController, WKUIDelegate {

    @IBOutlet var boxview: SCNView!
    override func viewDidLoad() {
        mainView 			= self.view as! SCNView
		mainView.delegate 	= self
		mainView.scene 		= SCNScene()

		mainView.backgroundColor = NSColor.black

		setupMidiDevice()
		User.current.printinfo()
		mainView.overlaySKScene = loadingscreen
		
		mainView.isPlaying			= true
		mainView.showsStatistics 	= true
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Change `2.0` to the desired number of seconds.
			smanager.coverflow()
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
				
				presentmainmenu()
				
				menuOverlay?.isPaused = false
				
				if smanager.columns.count > 0 {
					let column = smanager.columns[coverindex.0]
					animatecover(column: column)
				}
				
				mainView.prepare(drumScene, shouldAbortBlock: nil)
				drumScene.background.contentsTransform.m11 = 0.85 // fit width
				box = startparticle()
			}
		}
    }
	
    //    MARK: window shit
    override func viewDidAppear() {
		super.viewDidAppear()
		super.view.window?.contentAspectRatio = NSSize(width: 1.5, height: 1)
    }

}

