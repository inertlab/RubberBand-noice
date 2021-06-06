//
//  Performing.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/30/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit


protocol Performing : class {
	var scn: SCNScene {get}
	func handleevent(_ event: Button)
}
