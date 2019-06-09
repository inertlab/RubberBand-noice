//
//  Tempo.swift
//  RubberBand
//
//  Created by Fernando Zamora on 7/5/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SceneKit


/// This controls the speed of everything
///
/// Needs to be set everytime a song is loaded, the default speed is 8
/// User preference needs to be implemented in the future
class PaceMaker {
	/// controls the speed and distance between notes
	var fps:	CGFloat
	/// double version of fps to avoid casting in computations
	var fps_d:	Double 		= 8
	/// speed of the highway texture
	var asphalt:CGFloat
	var hitwindow:CGFloat	= 2
	var tempo:Double		= 120
	init() {
		self.fps 		= CGFloat(fps_d)
		self.asphalt	= fps / 8 		// 8 is derived from the size of the texture
		self.hitwindow 	= fps * 0.2
	}
	
	/// Updates the speeds for individual songs with average tempo
	///
	/// - Parameter miditempo: the average tempo from the midid track
	func setFPS(miditempo: Double) {
		tempo		= miditempo
//		fps_d		= round(miditempo / 100 * 12)
		fps_d		= 16
		fps 		= CGFloat(fps_d)
		asphalt		= fps / 32
		self.hitwindow 	= fps * 0.1
		print("average tempo = \(miditempo)\nHit window = \(hitwindow) \nfps = \(fps)")
	}
}

let pace = PaceMaker()
