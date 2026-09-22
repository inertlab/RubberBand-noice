//
//  GameView.swift
//  Rubber Band
//
//  Created by Fernando on 2/8/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SceneKit
import SpriteKit
import AVFoundation


class GameView: SCNView {
	
	//MARK: - Mouse Tracking
	var trackingarea: NSTrackingArea?
	override func updateTrackingAreas() {
		if trackingarea != nil {
			self.removeTrackingArea(trackingarea!)
		}
		let options : NSTrackingArea.Options = [
			.mouseEnteredAndExited,
			.mouseMoved,
			.activeInKeyWindow
		]
	   	trackingarea = NSTrackingArea(
			rect: self.bounds,
			options: options,
			owner: self,
			userInfo: nil
		)
		self.addTrackingArea(trackingarea!)
	}
	
	var mouseTimer = Timer()
	
	override func mouseMoved(with event: NSEvent) {
		mainView.window?.titleVisibility = .visible
		mainView.window?.titlebarAppearsTransparent =  false
		mouseTimer.invalidate()
		mouseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
		   NSCursor.setHiddenUntilMouseMoves(true)
			mainView.window?.titleVisibility = .hidden
		   mainView.window?.titlebarAppearsTransparent =  true
	   }
	}
	
	override func mouseEntered(with event: NSEvent) {
		mainView.window?.titleVisibility = .visible
		mainView.window?.titlebarAppearsTransparent =  false
	}
	
	override func mouseExited(with event: NSEvent) {
		mainView.window?.titleVisibility = .hidden
		mainView.window?.titlebarAppearsTransparent =  true
	}
	
	// MARK: - Key Handles
	
	override func keyDown (with event: NSEvent) {

		if event.isARepeat {return}

		if let key = keycode[event.keyCode] {
			stagemc.currentact.handleevent(key)
		}
	}
	
	override func addCursorRect(_ rect: NSRect, cursor object: NSCursor) {
		object.set()
	}
	
	override func keyUp(with event: NSEvent) {
		if let key = keycode[event.keyCode] {
			if key == .strum { return }
			switch stagemc.onstage {
			case .guitar, .piano:
				// what was i doing here?
				(stagemc.currentact as! KeyUp).handlekeyup(key)
			default:
				return
			}
		}
	}
	
}

