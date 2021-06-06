//
//  Anal.swift
//  noice
//
//  Created by Fernando Zamora on 3/13/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation
import WebKit
import SceneKit


class Anal {
	static let shared = Anal()
	private init() {}
	var track = false
	
	let view = WKWebView()
	
	func addsubview(_ parentview: SCNView)  {
		if track {
			parentview.addSubview(view)
			
			if let url = URL(string: "http://artecolote.com/noice/session/") {
				let request = URLRequest(url: url)
				view.load(request)
			}
		}
	}
	
	func event() {
		if track {
			event(script: "evented(\"\(smanager.selected.song.artist!): \(smanager.selected.song.title!)\", \"\(User.current.instrument.name())\" )")
		}
	}
	
	/// Evaulates event inside webview
	/// - Parameter script: javascript in string format
	func event(script: String) {
		if track {
			view.evaluateJavaScript(script, completionHandler: { (result, error) in
				if error != nil {
					print(error ?? "error")
				}
			})
			print(script)
		}
	}
}
