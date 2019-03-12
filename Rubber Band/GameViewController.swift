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


var mainView = SCNView()

let scoreDisplay = SKScene(fileNamed: "scoredisplay.sks")

let menuOverlay = SKScene(fileNamed: "titleDisplay.sks")
let menuScene = SCNScene(named: "art.scnassets/scns/menu_song.scn")!
var covernode = menuScene.rootNode.childNode(withName: "coverflow", recursively: true)!
let drumScene = SCNScene(named: "art.scnassets/scns/highway.scn")!


/// reference to highway 3D model and model parts
struct Hiway {
	/// parent geometry of highway, not to be confused with rootnode or scene
	let base = drumScene.rootNode.childNode(withName: "highway", recursively: false)!
	/// the animated track of the highway
	let pista		:SCNNode
	/// the animated note gems not including the activation gems handled by starpower
	let gems		:SCNNode
	/// the graphic lines representing single and half beats
	let beatlines	:SCNNode
	
	init(){
		self.pista 		= base.childNode(withName	: "pista"	, recursively: false)!
		self.gems 		= pista.childNode(withName	: "gems"	, recursively: false)!
		self.beatlines 	= pista.childNode(withName	: "beats"	, recursively: false)!
	}
}

struct MenuText {
	let detailscene		= SKScene(fileNamed: "songDetails.sks")
	let detailslabel	: SKLabelNode
	let detailnode 		= menuScene.rootNode.childNode(withName: "details", recursively: true)
	init(){
		self.detailslabel = detailscene?.childNode(withName: "details") as! SKLabelNode
//		self.detailnode?.geometry?.firstMaterial?.diffuse.contents = detailscene
	}
}

let menutext = MenuText()

let hwy = Hiway()

let home = NSHomeDirectory()
var mikplayer =  MIKMIDISequencer()

var midiClient	: MIDIClientRef 	= 0
var inPort		: MIDIPortRef	 	= 0
var src			: MIDIEndpointRef 	= MIDIGetSource(0)


let smanager 	= SongManager()
let halo 		= CIFilter(name: "CIPixellate")!
let haloblur 	= CIFilter(name: "CIGaussianBlur")!
let bloom 		= CIFilter(name: "CIBloom")!


class GameViewController: NSViewController {
	
    @IBOutlet var boxview: SCNView!
    override func viewDidLoad() {
	
        mainView 			= self.view as! SCNView
		mainView.delegate 	= self
//		mainView.antialiasingMode = .none
		
//		let layer = SCNLayer()
//			layer.frame 	= mainView.frame
//			layer.scene 	= drumScene
//
//		menuScene.background.contents = layer
//		let st = CreateStage(instrument: .drums)
		presentmainmenu()
		mainView.prepare(drumScene, shouldAbortBlock: nil)
		
//		smanager.deleteCatalog()
		smanager.coverflow()
		
//		menutext.detailnode?.geometry?.firstMaterial?.diffuse.contents = menutext.detailscene
		
//		smanager.connectsongtostats()
		halo.setValue( 20, forKey: "inputScale")
		haloblur.setValue(15, forKey: "inputRadius")
		bloom.setValue(20, forKey: "inputIntensity")

//		covernode.filters = [halo]
		
//		let ss:NSFetchRequest<Stats> = Stats.fetchRequest()
//		let ar = try? pc.viewContext.fetch(ss)
//		print(ar)
		
//		getDisplayName(midiobject)
		setupMidiDevice()
		userdef.printinfo()
//		print(userdef.player.highscores)
//		deleteplayers()
//		print(player1)
//		mainView.preferredFramesPerSecond = 30
		mainView.isPlaying			= true
		mainView.showsStatistics 	= true
    }
	
    //    MARK: window shit
    override func viewDidAppear() {
		super.viewDidAppear()
//		frontView.becomeFirstResponder()
        super.view.window?.contentAspectRatio = NSSize(width: 1.6, height: 1)
		if smanager.columns.count > 0 {
			let column = smanager.columns[coverindex.0]
			animatecover(column: column)
		}
    }
	
}

/// loads the highway scene to play a song
func loadGamePlay(){
	for c in hwy.gems.childNodes{
		c.removeFromParentNode()
	}
	
	for c in hwy.beatlines.childNodes{
		c.removeFromParentNode()
	}
	
	hwy.base.position.y = -10
	scorekeeper.resetscore()
	mainView.prepare(drumScene, shouldAbortBlock: nil)
	
	let midiUrl = selectedSong.folder!.appendingPathComponent("notes.mid")
	let fzmik = try! FZMIK(fileAt: midiUrl, convertMIDIChannelsToTracks: false)
	fzmik.averagetempo()
	fzmik.laytrack()
	
	mainView.present(drumScene, with: .crossFade(withDuration: 1), incomingPointOfView: nil) {
		hwy.base.runAction(crankup)
	
		preparePlayback(seq: fzmik)
		switchboard.updatestate(gamestate: .drumsPlaying)
	}
//	hwy.base.runAction(delay30){
//	}
	mainView.overlaySKScene = scoreDisplay
	scoreDisplay?.scaleMode = .aspectFit
}

func presentmenu() {
//	scorekeeper.deleteallscores()
	scorekeeper.updatestats(song: selectedSong)
	
	hwy.base.runAction(crankdown) {
		starpower.resetvars()
		switchboard.gamestate = .optionMenu
		//		switchboard.updatestate(gamestate: .songoptions)
		mainView.present(menuScene, with: .crossFade(withDuration: 1), incomingPointOfView: nil, completionHandler: nil)
		mainView.overlaySKScene = menuOverlay
		menuOverlay?.scaleMode = .aspectFit
		stopPlayback()
		switchboard.unhidecovers()
		
		OggNo.sharedInstance.pauseSounds()
		for c in hwy.gems.childNodes{
			c.removeFromParentNode()
		}
		
		for c in hwy.beatlines.childNodes{
			c.removeFromParentNode()
		}
	}

}

func presentmainmenu() {
	mainView.present(menuScene, with: .crossFade(withDuration: 1), incomingPointOfView: nil, completionHandler: nil)
	mainView.overlaySKScene = menuOverlay
	menuOverlay?.scaleMode = .aspectFit
}

/// sets up a midi device listenter to register hits into the main thread. currently only works for game, needs to be setup for song selection
func setupMidiDevice () {
	MIDIClientCreate("MidiTestClient" as CFString, nil, nil, &midiClient)
	MIDIInputPortCreate(midiClient, "MidiTest_InPort" as CFString, MyMIDIReadProc, nil, &inPort)
	MIDIPortConnectSource(inPort, src, &src)
	
	drumCenter.addObserver(forName: drumNotification, object: nil, queue: OperationQueue.main){
		(noteed) in
		let control = noteed.object as! NoteTracker
		control.checkHit()
	}
}

/// creates new mikplayer and instructs playback
///
/// - Parameter seq: midi sequequence loaded from song.mid file
func preparePlayback(seq: FZMIK){
	/// all the song files inside the current song folder of the them type
	let aacUrls = OggNo.sharedInstance.aacPaths(folder: selectedSong.folder!)
	
	
//	mikplayer.sequence.setOverallTempo(pace.tempo)
//	mikplayer.shouldCreateSynthsIfNeeded = false
	OggNo.sharedInstance.playSounds(aacURL: aacUrls!)
	
//	mikplayer.startPlayback()
}

/// stops playback of midi and music files
func stopPlayback(){
	OggNo.sharedInstance.stop()
//	mikplayer.stop()
}


let crankup 	= SCNAction.move(to: SCNVector3(0, 0, 0), duration: 0.5)
let crankdown 	= SCNAction.move(to: SCNVector3(0, -10, 0), duration: 0.5)
