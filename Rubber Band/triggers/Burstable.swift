//
//  Burstable.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/29/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import SceneKit

protocol Burstable {
//	func thump(node: SCNNode)
}

extension Burstable {
	var thump:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.intensity")
		animation.fromValue 	= 1
		animation.toValue 		= 0
		animation.duration 		= 0.4
		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
		return animation
	}
	
	var thumpmiss:CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "geometry.firstMaterial.diffuse.intensity")
		animation.fromValue 	= 0
		animation.toValue 		= 1
		animation.duration 		= 0.4
		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
		return animation
	}
	
	var rotate:SCNAction {
		return SCNAction.rotate(by: 0.75, around: SCNVector3(0, 1, 0), duration: 0.25)
	}
}
