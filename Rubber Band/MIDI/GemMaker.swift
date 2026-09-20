//
//  Note.swift
//  Rubber Band
//
//  Created by Fernando on 2/8/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SceneKit


//let gems = Gems()
// this needs to be more flexlible too
let gemmaker = GemMaker()


/// asset manager for Gems
///
/// Initially empty and populated depending on the instrument loaded.
/// Use genric names for notes to traverse between instruments
///
/// Should this expand to a full theme or just jems? the frets should probably be part of the same theme?
class GemMaker {
	enum IType {
		case strings, drums
	}
	/// if this takes a file then gemmaker needs to take a file too.
	/// remove this SOON!
//	let gems = Gems()
	/// File refrence to scene with the Gem assets, structure TBD
	let scene: SCNScene
	/// all the glowing materials if any, may be duplicated per instrument?
	///
	/// This might not be needed
	///
	/// Should all gems glow in their own color or white? leave it up to theme?
	var matsGlowing = [Button: SCNMaterial]()
	/// All the materials per instrument. Do I need this?
	var mats = [Button: SCNMaterial]()
	/// The geometry for each gem
	/// repopulate with every intstrument
	///
	/// Shoud the Gems be duplicated inside the scn files are cloned in-code and reassigned materials?
	var gemSet = [Button: SCNNode]()
	
	var drumtail:SCNNode?
	var stringtail:SCNNode?
	let beat:(fat: SCNNode, thin: SCNNode)
	let genericglow = SCNMaterial()
	
	/// Notes used by drums
	///
	/// Used to generate the gemSet
	/// - Required: Red gem for drums, Green for string
	///
	/// if second gem is missing from file, the first gem will be reused for all sequential gems
	let drumSet:[Button] = [.red, .yellow, .blue, .green, .yellow_c, .blue_c, .green_c, .orange]
	let stringnotes:[Button] = [.green, .red, .yellow, .blue, .orange]
	
	
	/// Initiate instance with a default file for gems
	/// - Parameter scnname: The name of the scn file
	///
	/// How should this be reloaded? singleton or fixed per instrument?
	init(scnname: String = "art.scnassets/scns/Gems.scn") {
		self.scene = SCNScene(named: scnname) ?? SCNScene()
		beat.fat = scene.rootNode.childNode(withName: "beat-fat", recursively: false)!
		beat.thin = scene.rootNode.childNode(withName: "beat-thin", recursively: false)!
		genericglow.diffuse.contents = NSColor.white
		genericglow.selfIllumination.contents = NSColor.white
	}
	
	func loadgems(type: IType) {
		gemSet.removeAll()
		matsGlowing.removeAll()
		
		switch type {
//			MARK: Build Drum Gems
		case .drums:
			var notes:[Button] = [.orange]
			let tomnotes:[Button] = [.red, .green, .blue, .yellow]
			let drumnode = scene.rootNode.childNode(withName: "drums", recursively: false)
			
			drumtail = drumnode?.childNode(withName: "tail", recursively: false)
			
			if let tom = drumnode?.childNode(withName: "toms", recursively: false) {
//				if "toms" is found, then use it for all toms
				for tn in tomnotes {
					gemSet[tn] = clonegem(instrument: tom)
					gemSet[tn]?.geometry?.firstMaterial = tom.geometry?.material(named: tn.string)
					matsGlowing[tn] = tom.geometry?.material(named: "glow")
				}
			} else {
//				there are multiple toms
				notes += tomnotes
			}
			
			let cymbalnotes:[Button] = [.yellow_c, .blue_c, .green_c]
			if let cymbal = scene.rootNode.childNode(withName: "cymbals", recursively: false) {
//				if "cymbals" is found, use it for all cymbals
				for cn in cymbalnotes {
					gemSet[cn] = clonegem(instrument: cymbal)
					gemSet[cn]?.geometry?.firstMaterial = cymbal.geometry?.material(named: cn.string)
					matsGlowing[cn] = cymbal.geometry?.material(named: "glow")
				}
			} else {
				notes += [.green_c, .blue_c, .yellow_c]
			}
			
			for n in notes {
//				fill the remainding notes not found before, this may be empty
				if let gem = drumnode?.childNode(withName: n.string, recursively: false) {
					gemSet[n] = gem
					matsGlowing[n] = gem.geometry?.material(named: "glow") ?? genericglow.copy() as! SCNMaterial
				}
			}
			
			for g in gemSet {
				g.value.position.x = g.key.metric.posD
			}
			
			break
			
//			MARK: Build string gems
		case .strings:
			if let strnode = scene.rootNode.childNode(withName: "strings", recursively: false) {
				stringtail = strnode.childNode(withName: "tail", recursively: false)
				if let gem = strnode.childNode(withName: "gems", recursively: false) {
//					gems is found, all notes derrive from this
					for n in stringnotes {
						gemSet[n] = clonegem(instrument: gem)
						gemSet[n]?.position.x = n.metric.posS
						matsGlowing[n] = genericglow
					}
					
					if gem.geometry?.firstMaterial!.name == "color" {
						print("color found")
//						if material is by color, assign the nscolor from the Button
						for g in gemSet {
							g.value.geometry?.firstMaterial = gem.geometry?.firstMaterial?.copy() as? SCNMaterial
							g.value.geometry?.firstMaterial?.diffuse.contents = g.key.metric.color
						}
					} else {
						for g in gemSet {
							g.value.geometry?.firstMaterial = g.value.geometry?.material(named: g.key.string)
						}
					}
				}
			}
			break
		}
	}
	
	/// Changes Gem material to it's glow
	/// - Parameter btn: The note representing the color
	/// - Returns: scene material. If the glow material doesn't exist in the material dictionary it will return a generic white
	func addglow(btn:Button) -> SCNMaterial {
		return matsGlowing[btn] ?? genericglow
	}
	
	func makegem(button:Button) -> SCNNode {
//		if let gem = gemSet[button] {
//			return gem.copy() as! SCNNode
//		}
		if button == .plus {
			return clonegem(instrument: gemSet[.green_c]!)
		}
		if let gem = gemSet[button] {
			return clonegem(instrument: gem)
		}
//		return gemSet[button] ?? SCNNode()
		
		return SCNNode()
	}

	/// Makes a tailnode and sets the color for a tail component
	/// - Parameter btn: Button corresponding to note
	/// - Returns: a tail node with the name set to the rawvalue of Button to get it's original color again
	func givemetail (btn: Button) -> SCNNode {
		
		let node = clonegem(instrument: stringtail!)
		node.geometry?.firstMaterial = stringtail?.geometry?.firstMaterial?.copy() as? SCNMaterial
		// at scale of 1 material scale = 0.18 and off -0.125  	max off = 0.82
		// at scale of 2 material scale = 0.36 and off -0.32  	max off = 0.64
		// calc: scale * 0.18
		node.geometry?.firstMaterial?.multiply.contents = btn.metric.color
		node.position.x = btn.metric.posS
		node.name = String(btn.rawValue)
		
		return node
	}
	
	enum Beat {
		case fat, thin
	}
}

private extension GemMaker {

	/// Copies node and geometry
	/// - Returns: returns copy of the node
	func clonegem (instrument:SCNNode) -> SCNNode {
		let node = instrument.clone()
			node.geometry = instrument.geometry?.copy() as? SCNGeometry
		return node
	}
}
