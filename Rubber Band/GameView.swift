//
//  GameView.swift
//  Rubber Band
//
//  Created by Fernando on 2/8/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SceneKit
import MIKMIDI
import SpriteKit
import AVFoundation

fileprivate var beat: TimeInterval = 0

var totaltime 	= 0.0
//var asphalt 	= hwy.base.childNode(withName: "asphalt", recursively: false)

let frustum = menuScene.rootNode.childNode(withName: "frustum", recursively: false)

class Menu: NSMenuItem {

}

class GameView: SCNView {
	
	var trackingarea: NSTrackingArea?
	override func updateTrackingAreas() {
		 if trackingarea != nil {
				   self.removeTrackingArea(trackingarea!)
			   }
		let options : NSTrackingArea.Options =
				   [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
			   trackingarea = NSTrackingArea(rect: self.bounds, options: options,
											 owner: self, userInfo: nil)
			   self.addTrackingArea(trackingarea!)
	}
	
	override func mouseEntered(with event: NSEvent) {
		mainView.window?.titlebarAppearsTransparent =  false
	}
	
	override func mouseExited(with event: NSEvent) {
		mainView.window?.titlebarAppearsTransparent =  true
	}
	
//	override func mouseMoved(with event: NSEvent) {
//		print("mouse moved")
//		mainView.window?.titlebarAppearsTransparent =  false
//	}
	override func keyDown (with event: NSEvent) {

		if event.isARepeat {return}

		if let key = keycode[event.keyCode] {
			stagemc.currentact.handleevent(key)
		}
	}

	override func keyUp(with event: NSEvent) {
		
		if let key = keycode[event.keyCode] {
			if key == .strum {return }
			switch stagemc.onstage {
			case .guitar, .piano:
				(stagemc.currentact as! KeyUp).handlekeyup(key)
			default:
				return
			}
		}
	}
}

//let format = DateComponentsFormatter()
var format:DateComponentsFormatter{
	let form = DateComponentsFormatter()
	form.allowedUnits = [.minute, .second]
	return form
}

extension GameViewController: SCNSceneRendererDelegate {

}
