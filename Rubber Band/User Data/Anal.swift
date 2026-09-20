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


/// tracks anaylitcs with Google - disable in viewcontroller for debug
class Anal {
	static let shared = Anal()
	private init() {}
	var track = false
	
	let view = WKWebView()
	
	func addsubview(_ parentview: SCNView)  {
		if !track {return}

		parentview.addSubview(view)
		
		if let url = URL(string: "https://inertlab.com/noice/session") {
			let request = URLRequest(url: url)
			view.load(request)
		}
	}
	
	func songevent(_ song: Song) {
		if !track {return}
//		"evented" is a function defined in the html file, i could also just send gtag() script directly
//		evented(instrument, artist, title)
		event(script: "evented(\"\(User.current.instrument.name())\", \"\(song.artist!)\", \"\(song.title!)\")")
	}
	
	/// Evaulates event inside webview
	/// - Parameter script: javascript in string format
	func event(script: String) {
		view.evaluateJavaScript(script, completionHandler: { (result, error) in
			if error != nil {
				print(error ?? "website error")
			}
		})
		print(script)
	}
}
