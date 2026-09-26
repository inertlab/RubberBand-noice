//
//  File.swift
//  RubberBand
//
//  Created by Fernando on 7/5/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import Foundation
import GameplayKit


@objc extension GKComponent {
	/// Custom update function
	/// - Parameter hwytime: Song current playtime converted to HWY track units
	func update (_ hwytime: CGFloat) {}
}

/// Custom component system that takes CGFloat instead of TimeInterval
class GKComponentSystemCGF: GKComponentSystem<GKComponent> {
	/// Custom update function
	/// - Parameter hwytime: Song current playtime converted to HWY track units
	func update(_ hwytime: CGFloat)  {
		for component in self.components {
			component.update(hwytime)
		}
	}
}

