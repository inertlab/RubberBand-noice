//
//  FZMIK2.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/8/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//


import Foundation
import MIKMIDI
import SceneKit



class MusicSheet {
	
	static let shared = MusicSheet()
	
	var seq = MIKMIDISequence()
	var difficulty = InstConfig()
	
	private init() {}
	
	func setSeq (url: URL, _ difficulty: InstConfig) {
	  	self.seq = try! MIKMIDISequence(fileAt: url, convertMIDIChannelsToTracks: false)
		self.difficulty = User.current.diff.config()
	}
	
	func getTrackByName (partname: String = "PART DRUMS") -> MIKMIDITrack? {
		var track:MIKMIDITrack?
		
		loop: for t in seq.tracks{
			for e in t.events(of: MIKMIDIMetaTrackSequenceNameEvent.self, fromTimeStamp: 0, toTimeStamp: 10) {
				let nevent = e as! MIKMIDIMetaTrackSequenceNameEvent
				if nevent.string == partname.uppercased() {
					track = t
					break loop
				}
			}
		}
		return track
	}
	
	/// creates gems out of midi track and places them on highway
	///
	/// - Parameter tc: TimeCode onject to keep track of timing. TimeCode requires FZMik
	func laytrack(tc: TimeCode) -> Int {
		
		let gemmaker = GemMaker()
		
		self.layBeat(tc: tc)
		starpower.resetvars() // reset vars from previous track
		
		/// sorted drum notes from midi sequence
		var drumnotes = getDrumNotes()
		
		drumnotes = tc.convertmtstosec(notes: drumnotes)
		
		for (beat,note) in drumnotes {
			
			let gem 			= gemmaker.makegem(controller: note)
			gem.position.x 		= CGFloat(note.metrics.pos.rawValue)
			gem.position.z 		= CGFloat(beat * pace.fps_d)
			gem.categoryBitMask = note.metrics.bit
			
			if note == .plus { // 120 = star activator
				gem.geometry?.firstMaterial = gems.m_cymbals_g
				starpower.activators.addChildNode(gem)
				continue
			}
			hwy.notes.addChildNode(gem)
		}
		
		// add notes to disapearing set when starpower is on
		for st in starpower.activators.childNodes {
			for gem in hwy.notes.childNodes {
				if st.position.z == gem.position.z {
					starpower.tohide.append(gem)
				}
			}
		}
		
		var gemlist = [SCNNode]()
		for range in starpower.timelist {
			for gem in hwy.notes.childNodes {
				switch gem.position.z {
				case range.0...range.1:
					if gem.categoryBitMask == GemBit.orange{
						// kick gem is a clone, make a copy of it's geometry to change color
						gem.geometry? = gem.geometry?.copy() as! SCNGeometry
					}
					if GemBit.cymbals.contains(gem.categoryBitMask){
						gem.geometry?.firstMaterial = gems.m_cymbals_g
					}else{
						gem.geometry?.firstMaterial = gems.m_white
					}
					
					gemlist.append(gem)
				default:
					break;
				}
			}
			starpower.powergems.append(gemlist)
		}
		print("star power = ", starpower.powergems.count)
		
		//		startparticle()
		return drumnotes.count
	} // end of laytrack
	
	/// retrieves drum note information with discoflips etc
	///
	/// - Returns: a tuple array with MusicTimeStamp (beat) and the ControlInput (like .yellow_c) sorted by musicstamp, small to big
	func getDrumNotes () -> [(Double, Button)] {
		/// an array of Tupples [(MusicTimeStamp, Note)]
		var drumnotes = [(Double, Button)]()
		
		/// the track from the midi sequence
		let drumtrack = getTrackByName()
		
		//		temporaty note holders for comparison
		var tom110:		[MIKMIDINoteEvent] = []
		var tom111:		[MIKMIDINoteEvent] = []
		var tom112:		[MIKMIDINoteEvent] = []
		var cymbal98:	[MIKMIDINoteEvent] = []
		var cymbal99:	[MIKMIDINoteEvent] = []
		var cymbal100:	[MIKMIDINoteEvent] = []
		
		var discoFlipMe = [(Bool, MusicTimeStamp, MusicTimeStamp)]()
		
		guard let textevents 	= drumtrack?.events(of: MIKMIDIMetaTextEvent.self, fromTimeStamp: 0, toTimeStamp: (drumtrack?.events.last?.timeStamp)!) else { return [] }
		
		var fliptuple 	= (false, 0.0, 0.0)
		
		for e in textevents{
			let etext 		= e as! MIKMIDIMetaTextEvent
			
			if etext.string == "[mix 3 drums0d]" {
				fliptuple.0 = true
				fliptuple.1 = e.timeStamp
			}
			
			if etext.string == "[mix 3 drums0]" && fliptuple.0 {
				fliptuple.2 = e.timeStamp
			}
			
			if fliptuple.0 && fliptuple.2 > fliptuple.1 {
				discoFlipMe.append(fliptuple)
				fliptuple = (false, 0.0, 0.0)
			}
		}
		
		for n in drumtrack!.notes{
			if n.note == 116 {
				let starpow = (CGFloat(n.timeStamp) * pace.fps, CGFloat(n.endTimeStamp) * pace.fps)
				starpower.timelist.append(starpow)
				continue
			}
			
			if let cinput = difficulty[n.note] {
				switch cinput{
				case .yellow:
					tom110.append(n)
				case .blue:
					tom111.append(n)
				case .green:
					tom112.append(n)
				case .yellow_c:
					cymbal98.append(n)
				case .blue_c:
					cymbal99.append(n)
				case .green_c:
					cymbal100.append(n)
				case .plus:
					// in future add start time to a different note for activator tail
					drumnotes.append((n.endTimeStamp, cinput))
				default:
					drumnotes.append((n.timeStamp, cinput))
					break
				}
			}
		}
		
		swapCymbaltoTom(toms: tom110, cymbals: &cymbal98	, dnotes: &drumnotes)
		swapCymbaltoTom(toms: tom111, cymbals: &cymbal99	, dnotes: &drumnotes)
		swapCymbaltoTom(toms: tom112, cymbals: &cymbal100	, dnotes: &drumnotes)
		
		for (f, start, end) in discoFlipMe {
			if f {
				for ( i, dn) in drumnotes.enumerated() {
					switch dn.0 {
					case start...end:
						if dn.1 == .red 		{drumnotes[i].1 = .yellow_c	}
						if dn.1 == .yellow_c 	{drumnotes[i].1 = .red		}
					default:
						break
					}
				}
			}
		}
		
		let sortednotes = drumnotes.sorted(by: { $0.0 < $1.0 })
		return sortednotes
	}
	func averagetempo() -> Double {
		let bpmlist 	= seq.tempoEvents()
		var bpms:Double	= 0
		for t in bpmlist {
			bpms += t.bpm
		}
		bpms = round(bpms / Double(bpmlist.count))
		pace.setFPS(miditempo: bpms)
		//		self.setOverallTempo(bpms)
		return bpms
	}
	
	func getvocals() -> MIKMIDITrack {
		return getTrackByName(partname: "part vocals")!
	}
}

private extension MusicSheet {
	
	/// Swaps cymbals to toms for Pro Drums
	///
	/// - Parameters:
	///   - toms: Arry of tom markers
	///   - cymbals: Array of cymbal notes
	///   - dnotes: array of collected notes
	func swapCymbaltoTom (toms: Array<MIKMIDINoteEvent>, cymbals: inout Array<MIKMIDINoteEvent>, dnotes: inout [(Double, Button)]){
		// removes the tom corresponding to cymbals
		for c in toms{
			for (i, t) in cymbals.enumerated().reversed() {
				switch t.timeStamp{
				case c.timeStamp...c.endTimeStamp:
					dnotes.append((t.timeStamp, difficulty[c.note]!))
					cymbals.remove(at: i)
				default:
					break
				}
			}
		}
		//	add remainding results to drumnotes
		for r in cymbals{
			dnotes.append((r.timeStamp, difficulty[r.note]!))
		}
	}
	
	/// makes and layers beat marks on the track
	///
	/// - Note: at the end of the track beats tend to dip
	func layBeat (tc: TimeCode) {
		let beats = getTrackByName(partname: "beat")
		if beats == nil {
			layBeat(sanstrack: tc)
		} else {
			layBeat(withtrack: tc)
		}
	}
	
	func layBeat (withtrack tc: TimeCode) {
		let beats 		= getTrackByName(partname: "beat")
		if beats == nil {return} // what happens if there is no beat track?
		let fatline 	= drumScene.rootNode.childNode(withName: "fatline"	, recursively: false)!
		let thinline 	= drumScene.rootNode.childNode(withName: "thinline"	, recursively: false)!
		
		for beat in beats!.notes {
			var line: SCNNode
			let time = tc.beattosec(beat: beat.timeStamp)
			if beat.noteLetter == "C" {
				line = fatline.clone()
			} else {
				line = thinline.clone()
			}
			line.position.z = CGFloat(time) * pace.fps
			hwy.beatlines.addChildNode(line)
		}
	}
	
	func layBeat (sanstrack tc: TimeCode) {
		let fatline 	= drumScene.rootNode.childNode(withName: "fatline"	, recursively: false)!
		//		let thinline 	= drumScene.rootNode.childNode(withName: "thinline"	, recursively: false)!
		//		let beats		= SCNNode()
		for beat in 0...Int(seq.length) {
			let z 	= CGFloat(tc.beattosec(beat: Double(beat))) * pace.fps
			let fl 	= fatline.clone()
			//			let tl 	= thinline.clone()
			fl.position.z 	= z
			//			fl.name			= "fat"
			//			tl.position.z 	= z - (pace.fps * 0.5)
			//			tl.name			= "thin"
			hwy.beatlines.addChildNode(fl)
			//			hwy.beatlines.addChildNode(tl)
		}
	}
	
	func lyricist(tc: TimeCode) -> [(Double, String)] {
		let lyrictrack 	=  getTrackByName(partname: "part vocals")
		var phrases 	= [(Double, String)]()
		var phrase 		= (0.0, "")
		var text 	 	= ""
		var time 		= 0.0
		
		for e in lyrictrack!.events{
			if e.eventType == .metaLyricText {
				let t = e as! MIKMIDIMetaLyricEvent
				if t.string != nil {
					let st = t.string!
					switch st.last{
					case "-":
						text += st.dropLast()
					case "+":
						continue
					default:
						text += (st + " ")
					}
				}
				continue
			}
			
			if e.eventType ==  .midiNoteMessage {
				let note = e as! MIKMIDINoteEvent
				if note.note == 105 || note.note == 106 {
					phrase = (time, text)
					phrases.append(phrase)
					time = tc.beattosec(beat: note.timeStamp)
					text = ""
				}
			}
		}
		return (phrases)
	}
}


