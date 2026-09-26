//
//  LoadingScreen.swift
//  noice
//
//  Created by fernando on 4/18/23.
//  Copyright © 2023 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit



fileprivate enum LightColor: String {
	case crimson, // not a light
		 crimson_lit, //crimson is to dark
		 cyan,
		 deep,// not a light
		 dim, // not a light
		 dust,
		 green, // not a light
		 jade,
		 mint,
		 navy, // not a light
		 navy_lit,
		 nblack, // not a light
		 neutral, // not a light
		 orange,
		 pink,
		 pink_deep,
		 sienna,
		 sorbet,
		 white,
		 yellow
	
	/// Selects 1 color suitable to be light colors
	/// - Returns: LightColor
	static func light() -> LightColor {
		return [
			.crimson_lit,
			.cyan,
			.dust,
			.jade,
			.mint,
			.navy_lit,
			.orange,
			.sienna,
			.sorbet,
			.white,
			.yellow,
			.pink,
			.pink_deep
		].randomElement()!
	}
	
	private func nsc(_ lightcolor: LightColor) -> NSColor {
		return lightcolor.nscolor()
	}
	
	func nscolor() -> NSColor{
		return NSColor(named: self.rawValue) ?? .white
	}
	
	/// selects a random color from an array of LightColor
	/// - Parameter colors: array of light colors
	/// - Returns: NSColor
	///
	/// Use colors as a set of adequate colors for a given color
	/// This doesn't allow to mix in LightColors with onther NSColors
	private func random(_ colors: [LightColor]) -> NSColor {
		return colors.randomElement()!.nscolor()
	}
	
	private func random(_ nscolors: [NSColor]) -> NSColor {
		return nscolors.randomElement()!
	}
	
	private func randomlight(_ nscolors: [LightColor]) -> LightColor {
		return nscolors.randomElement()!
	}
	
	
	/// Chooses a random Color for given LightColor
	/// - Returns: NSColor
	func ambient() -> LightColor {
		switch  self {
		case .crimson_lit:
			return randomlight([.dim, .deep, .sienna, .nblack])
		case.cyan:
			return randomlight([.crimson, .cyan, .deep, .dim, .green, .jade, .navy, .nblack, .neutral, .orange, .pink, .sienna, .sorbet])
		case .dust:
			return randomlight([.crimson, .cyan, .dim, .dim, .jade, .mint, .nblack, .neutral, .sienna, .yellow, .pink,])
		case .jade:
			return randomlight([.dim, .green, .nblack, .sienna])
		case .mint:
			return randomlight([.crimson, .deep, .dust, .nblack, .neutral, .orange, .sienna, .sorbet, .pink])
		case .navy_lit:
			return randomlight([.crimson, .green, .nblack, .dim])
		case .orange:
			return randomlight([.crimson, .deep, .navy, .nblack, .neutral, .sorbet, .pink])
		case .sienna: // too much like orange
			return randomlight([.sienna, .green])
		case .sorbet:
			return randomlight([.deep, .green, .navy, .nblack, .neutral])
		case .white:
			return randomlight([.green, .nblack, .neutral, .orange, .sienna, .sorbet, .pink])
		case .yellow:
			return randomlight([.crimson, .cyan, .deep, .dust, .green, .jade, .navy, .nblack, .neutral, .sienna])
		case .pink:
			return randomlight([.crimson, .deep, .green, .navy, .nblack, .sienna])
		case .pink_deep:
			return randomlight([.dim, .deep, .nblack])
		default:
			return .nblack
		}
	}
}

//extension NSColor {
//	static func light(_ lightcolor: LightColor) -> NSColor {
//		return NSColor(named: lightcolor.rawValue) ?? .n_yellow
//	}
//}

class LoadingScreen {
	let scene = SKScene(fileNamed: "LoadingScreen.sks")
	let loadcount: SKLabelNode
	let logo: SKSpriteNode //i might not need to reference this?
	let splash: SKSpriteNode
	let version: SKLabelNode
	let light : SKLightNode
	let loading: SKLabelNode
	/// temp label for color values. delete in future
	let col: SKLabelNode
	private let randomx = GKRandomDistribution(lowestValue: -720, highestValue: 720)
	private let randomy = GKRandomDistribution(lowestValue: -450, highestValue: 450)

	private let scaleindex = GKRandomDistribution(lowestValue: 0, highestValue: 4)
	
	private let scales: [CGFloat] = [0.5, 0.625, 0.75, 0.875, 1]
	
	private let logoatlas = SKTextureAtlas(named: "logo")
	private let mono: SKSpriteNode

	init() {
		self.loadcount = scene?.childNode(withName: "loadcount") as! SKLabelNode
		self.logo = scene?.childNode(withName: "logo") as! SKSpriteNode
		self.splash = scene?.childNode(withName: "splash") as! SKSpriteNode
		self.version = scene?.childNode(withName: "version") as! SKLabelNode
		self.light = scene?.childNode(withName: "light") as! SKLightNode
		self.col = scene?.childNode(withName: "color") as! SKLabelNode
		self.loading = scene?.childNode(withName: "loading") as! SKLabelNode
		self.mono = scene?.childNode(withName: "logo2") as! SKSpriteNode
		scene?.scaleMode = .aspectFit
		scene?.isPaused = false
		mono.texture = logoatlas.textureNamed("1")
		loading.text = NSLocalizedString("Loaded Songs…", comment: "loading message")
		getversion()
		randomlight()
		randomlightposition()
		randomsplashposition()
		lightup()
	}
	
	deinit {
		print("does no longer exist")
	}
	
	/// this fucking works!
	let dimlight = SKAction.customAction(withDuration: 4) {
		node, time in
		if let nnode = node as? SKLightNode {
			nnode.falloff = time / 4 * 0.75 + 0.5
		} else {
			print("not good node")
		}
	}
	
	
	let action = SKAction.customAction(withDuration: 1) {
		node, time in
		node.position.x = time
	}
	
	func lightup() {
		
		let upordown = SKAction.moveBy(x: 0, y: CGFloat(randomx.nextInt()), duration: 6)
		upordown.timingMode = .easeOut
		
		
		let backandforth = SKAction.moveBy(x: 20, y: 0, duration: 1)
		backandforth.timingMode = .easeInEaseOut
		
		light.run(upordown)
		light.run(SKAction.group([backandforth, backandforth.reversed(), backandforth]))
		dimlight.timingMode = .easeIn
		light.run(dimlight, withKey: "hell")
	}
	
	func reload() {
		getversion()
		randomlight()
		randomlightposition()
		randomsplashposition()
		lightup()
	}
	
	func fadeout() {
		
		var rollimgs = [SKTexture]()
		for i in 1...logoatlas.textureNames.count {
			rollimgs.append(logoatlas.textureNamed(i.description))
//			print(name)
		}
		
		let roll = SKAction.animate(with: rollimgs, timePerFrame: 0.05)
		roll.duration = 1.75
		mono.run(roll)

		loading.text = NSLocalizedString("Rock On!", comment: "encouragment")
		loadcount.run(SKAction.fadeOut(withDuration: 0.5))
		version.run(SKAction.fadeOut(withDuration: 0.25)){
			updatekeycode(User.current.instrument)
			mainView.overlaySKScene?.run(SKAction.fadeOut(withDuration: 1.5)) {
				menuOverlay!.alpha = 0
				mainView.overlaySKScene?.removeAllActions()
				mainView.overlaySKScene	= menuOverlay
				mainView.overlaySKScene?.isPaused = false
				mainView.overlaySKScene?.scaleMode = .aspectFit
				mainView.overlaySKScene?.run(SKAction.fadeIn(withDuration: 0.5))
			}
		}
	}
}

private extension LoadingScreen {
	
	
	func getversion() {
		if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
			self.version.text = NSLocalizedString("version ", comment: "app version") + version
		}
	}
	
	func randomlight() {
		let particle = light.childNode(withName: "bokeh") as! SKEmitterNode
		let color = LightColor.light()
		light.lightColor = color.nscolor()
		let ambient = color.ambient()
		light.ambientColor = ambient.nscolor()
		particle.particleColorSequence = SKKeyframeSequence(keyframeValues: [color.nscolor(), ambient.nscolor()], times: [0,2])
		
//		col.text = color.rawValue + ": " + ambient.rawValue
	}
	
	func randomlightposition(){
//		scene height = 1440 X 900
		light.position.x = CGFloat( randomx.nextInt())
		light.position.y = CGFloat( randomy.nextInt())
	}
	
	func randomsplashposition(){
//		at scale 1 max and min = screen bounds, 720, 450
//		at scale 0.5 minmx = 0
		let scale = scales[scaleindex.nextInt()]

		splash.setScale(scale)
		
		let factor = (scale - 0.5) * 2
		splash.position.x = CGFloat(randomx.nextInt()) * factor
		splash.position.y = CGFloat(randomy.nextInt()) * factor
	}
}
