//
//  Note.swift
//  Rubber Band
//
//  Created by Fernando on 2/8/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import SceneKit

struct Gems {
	let instruments = SCNScene(named: "art.scnassets/scns/instruments.scn")!
	var tom 		:SCNNode
	let hihat		:SCNNode
	let ride		:SCNNode
	let crash		:SCNNode
	let m_green 	:SCNMaterial
	let m_blue 		:SCNMaterial
	let m_yellow	:SCNMaterial
	let m_red 		:SCNMaterial
	let m_cymbals	:SCNMaterial
	let m_white		:SCNMaterial
	let m_orange 	= SCNMaterial()
	let kick 		= SCNNode(geometry: SCNBox(width: 4, height: 0.03, length: 0.13, chamferRadius: 0))
	let m_cymbals_g :SCNMaterial
	
	init () {
		self.tom 		= self.instruments.rootNode.childNode(withName: "tom"	, recursively: true)!
		self.hihat 		= self.instruments.rootNode.childNode(withName: "hihat"	, recursively: true)!
		self.ride 		= self.instruments.rootNode.childNode(withName: "ride"	, recursively: true)!
		self.crash 		= self.instruments.rootNode.childNode(withName: "crash"	, recursively: true)!
		self.m_green 	= self.tom.geometry!.material(named: "green")!
		self.m_blue  	= self.tom.geometry!.material(named: "blue")!
		self.m_yellow  	= self.tom.geometry!.material(named: "yellow")!
		self.m_red  	= self.tom.geometry!.firstMaterial!
		self.m_cymbals 	= self.hihat.geometry!.firstMaterial!
		self.m_white 	= self.tom.geometry!.material(named: "white")!
		self.m_orange.diffuse.contents = NSColor.rbOrange
		self.m_orange.selfIllumination.contents = NSColor.white
		self.kick.geometry?.firstMaterial = self.m_orange
		self.m_cymbals_g = self.hihat.geometry!.material(named: "glow")!
	}
}

let gems = Gems()

class GemMaker {
	
	///	makes gems by loading external file
	func makegem (controller: DrumKit) -> SCNNode {

		var node = SCNNode()
		
		switch controller{
		case .o_bass:
			node = gems.kick.clone()
		case .b_ride:
			node = clonegem(instrument: gems.ride)
		case .g_crash:
			node = clonegem(instrument: gems.crash)
		case .y_hihat:
			node = clonegem(instrument: gems.hihat)
		default:
			node = clonegem(instrument: gems.tom)
			
			switch controller.metrics.color {
			case .rbBlue:
				node.geometry?.firstMaterial = gems.m_blue
			case .rbGreen:
				node.geometry?.firstMaterial = gems.m_green
			case .rbYellow:
				node.geometry?.firstMaterial = gems.m_yellow
			default: // default is red
				break
			}
		}
		return node
	}
	
	///	makes gems by loading external file
	func makegem (controller: Button) -> SCNNode {
		
		var node = SCNNode()
		
		switch controller{
		case .orange:
			node = gems.kick.clone()
		case .blue_c:
			node = clonegem(instrument: gems.ride)
		case .green_c, .plus:
			node = clonegem(instrument: gems.crash)
		case .yellow_c:
			node = clonegem(instrument: gems.hihat)
		case .blue:
			node = clonegem(instrument: gems.tom)
			node.geometry?.firstMaterial = gems.m_blue
		case .green:
			node = clonegem(instrument: gems.tom)
			node.geometry?.firstMaterial = gems.m_green
		case .yellow:
			node = clonegem(instrument: gems.tom)
			node.geometry?.firstMaterial = gems.m_yellow
		default:
			node = clonegem(instrument: gems.tom)
		}
		
		return node
	}
	
	/// makes beat lines, fat and thin
	///
	/// - Parameter size: thickness of beat, defined in the midifile
	/// - Returns: scnnode with the beat shape
	func makebeat (size: Beat) -> SCNNode{
		let beatnode = SCNNode()
		switch size {
		case .fat:
			beatnode.geometry = SCNPlane(width: 4, height: 0.5)
		case .thin:
			beatnode.geometry = SCNPlane(width: 4, height: 0.30)
		}
		beatnode.rotation.w = 1.57
		beatnode.rotation.x = 1
		beatnode.geometry?.firstMaterial?.isDoubleSided = true
		return beatnode
	}
}

private extension GemMaker {
	func clonegem (instrument:SCNNode) -> SCNNode {
		let node 			= instrument.clone()
			node.geometry 	= instrument.geometry?.copy() as? SCNGeometry
		return node
	}
	
	/// makes gem geometry for basic
	///
	/// - Returns: box shape
	func makekick () -> SCNGeometry{
		var kick = SCNGeometry()
			kick = SCNBox(width: 4, height: 0.03, length: 0.13, chamferRadius: 0)
			kick.firstMaterial = gems.m_orange
		return kick
	}
}


/// Describes a Drumkit Controller
///	## Raw Names
/// the drumkit parts (bass, snare, etc)
/// ## Raw Values
/// Midi Notes representing each instrument in the song.mid file ("97" "98")
/// - Note: Midi Notes do not match midi notes sent from instrument
enum DrumKit: String {
	case o_bass 	= "96"	, r_snare 	= "97"
	case y_hihat 	= "98"	, b_ride 	= "99"	, g_crash 	= "100" 	// cymbals
	case y_tom 		= "110"	, b_tom 	= "111"	, g_tom 	= "112" 	// toms
	/// Drumkit Attributes
	/// # Atributtes
	/// ## pos = horizontal position on highway (based on color)
	///	## color = controller color (derrived from rb instruments)
	/// ## note = Musical notation in flats (not sharps)
	struct Metrics {
		let pos: GemPos, color: NSColor, note: MidiNote, bit: Int
	}
	/// metrics - notation, position, color, instrument name, gem shape
	var metrics: Metrics {
		switch self {
		case .o_bass:
			return Metrics(pos: .o, color: .rbOrange, note: .C6	, bit: GemBit.orange)
		case .r_snare:
			return Metrics(pos: .r, color: .rbRed 	, note: .Db6, bit: GemBit.red	)
		case .y_hihat:
			return Metrics(pos: .y, color: .rbYellow, note: .D6	, bit: GemBit.yelloc)
		case .b_ride:
			return Metrics(pos: .b, color: .rbBlue 	, note: .Eb6, bit: GemBit.bluec	)
		case .g_crash:
			return Metrics(pos: .g, color: .rbGreen , note: .E6	, bit: GemBit.greenc)
		case .y_tom:
			return Metrics(pos: .y, color: .rbYellow, note: .D7	, bit: GemBit.yellow)
		case .b_tom:
			return Metrics(pos: .b, color: .rbBlue	, note: .Eb7, bit: GemBit.blue	)
		case .g_tom:
			return Metrics(pos: .g, color: .rbGreen , note: .E7	, bit: GemBit.green	)
		}
	}
}

/// not used - reference only
enum MidiNote: String {
	case C6 = "96", Db6 = "97", D6 = "98", Eb6 = "99", E6 = "100", D7 = "110", Eb7 = "111", E7 = "112"
}

extension NSColor {
	static var rbRed:		NSColor { return NSColor(srgbRed: 1, green: 0.2, blue: 0, alpha: 1) 	}
	static var rbYellow:	NSColor { return NSColor(srgbRed: 1, green: 0.95, blue: 0, alpha: 1)	}
	static var rbBlue:		NSColor { return NSColor(srgbRed: 0, green: 0.65, blue: 9, alpha: 1)	}
	static var rbOrange:	NSColor { return NSColor(srgbRed: 1, green: 0.70, blue: 0, alpha: 1)	}
	static var rbGreen:		NSColor { return NSColor(srgbRed: 0, green: 0.69, blue: 0.3, alpha: 1)	}
}

/// gem position by color
///
/// - r: red position
/// - y: yellow position
/// - b: blue position
/// - g: green position
/// - k: kick position
enum GemPos: Double {
    case r = 1.26
    case y = 0.42
    case b = -0.42
    case g = -1.26
    case o = 0
}

struct GemBit {
	static let green 	= 1 << 0
	static let red 		= 1 << 1
	static let yellow 	= 1 << 2
	static let blue 	= 1 << 3
	static let orange 	= 1 << 4
	static let greenc	= 1 << 5
	static let yelloc	= 1 << 6
	static let bluec	= 1 << 7
	static let dead		= 1 << 8
//	static let activate	= 1 << 9
	static var activate:Int{
		return self.green | self.greenc
	}
	static let cymbals  = [GemBit.yelloc, GemBit.bluec, GemBit.greenc]
}


