//
//  mikmidiway.swift
//  RubberBand
//
//  Created by Fernando Zamora on 2/15/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import MIKMIDI
import SceneKit


class FZMIK: MIKMIDISequence {
	
	func getTrackByName (partname: String = "PART DRUMS") -> MIKMIDITrack{
		var track:MIKMIDITrack?
		
		loop: for t in self.tracks{
			for e in t.events(of: MIKMIDIMetaTrackSequenceNameEvent.self, fromTimeStamp: 0, toTimeStamp: 1) {
//				print(e)
				let nevent = e as! MIKMIDIMetaTrackSequenceNameEvent
				if nevent.string == partname {
					track = t
					
					break loop
				}
			}
		}
		return track!
	}
	
	/// creates gems out of midi track and places them on highway
	func laytrack() -> Void {
		
		let timecop = TimeCode(seq: self)
		
		let gemmaker = GemMaker()

		self.layBeat(tc: timecop)
		starpower.resetvars() // reset vars from previous track
	
//		print(pace.fps)
		/// sorted drum notes from midi sequence
		var drumnotes = getDrumNotes()
		
		drumnotes = timecop.convertmtstosec(notes: drumnotes)
		
		let a_crash = DrumKit(rawValue: "100")!
		for (beat,note) in drumnotes {
			if let gemnote = DrumKit(rawValue: note){
				let gem 			= gemmaker.makegem(controller: gemnote)
					gem.position.x 	= CGFloat(gemnote.metrics.pos.rawValue)
					gem.position.z 	= CGFloat(beat * pace.fps_d)
					gem.name 		= gemnote.rawValue
					gem.categoryBitMask = gemnote.metrics.bit
//					gem.filters = [halo]
				hwy.gems.addChildNode(gem)
			} else if note == "120" { // 120 = star activator
				let a_gem 				= gemmaker.makegem(controller: a_crash)
					a_gem.position.x 	= CGFloat(a_crash.metrics.pos.rawValue)
					a_gem.position.z 	= CGFloat(beat * pace.fps_d)
					a_gem.name 			= "120"
					a_gem.categoryBitMask = GemBit.active | GemBit.greenc
					starpower.activators.addChildNode(a_gem)
			}
		}
		
		// add notes to disapearing set when starpower is on
		for st in starpower.activators.childNodes {
			for gem in hwy.gems.childNodes {
				if st.position.z == gem.position.z {
					starpower.tohide.append(gem)
				}
			}
		}
		
		var gemlist = [SCNNode]()
		for range in starpower.timelist {
			for gem in hwy.gems.childNodes {
				switch gem.position.z {
				case range.0...range.1:
					gem.geometry?.firstMaterial = gems.m_white
					gemlist.append(gem)
				default:
					break;
				}
			}
			starpower.powergems.append(gemlist)
		}
		print("star power = ",starpower.powergems.count)
	}
	
	/// retrieves drum note information with discoflips etc
	///
	/// - Returns: a tuple array with MusicTimeStamp (beat) and the midi note (like "98") sorted by musicstamp, small to big
	func getDrumNotes () -> [(Double , String)] {
		/// an array of Tupples [(MusicTimeStamp, Note)]
		var drumnotes = [(Double, String)]()
		
		/// the track from the midi sequence
		let drumtrack = getTrackByName()
		
		
//		temporaty note holders for comparison
		var cymbal0:[MIKMIDINoteEvent] = []
		var cymbal1:[MIKMIDINoteEvent] = []
		var cymbal2:[MIKMIDINoteEvent] = []
		var tom98:	[MIKMIDINoteEvent] = []
		var tom99:	[MIKMIDINoteEvent] = []
		var tom100:	[MIKMIDINoteEvent] = []
		
		var discoFlipMe = [(Bool, MusicTimeStamp, MusicTimeStamp)]()

		let textevents 	= drumtrack.events(of: MIKMIDIMetaTextEvent.self, fromTimeStamp: 0, toTimeStamp: (drumtrack.events.last?.timeStamp)!)
		
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

		for n in drumtrack.notes{
//			print(n)
			if n.note > 95 && n.note < 121 {
				switch n.note{
				case 110:
					cymbal0.append(n)
				case 111:
					cymbal1.append(n)
				case 112:
					cymbal2.append(n)
				case 98:
					tom98.append(n)
				case 99:
					tom99.append(n)
				case 100:
					tom100.append(n)
				case 116: // this is starpower
					let starpow = (CGFloat(n.timeStamp) * pace.fps, CGFloat(n.endTimeStamp) * pace.fps)
					starpower.timelist.append(starpow)
				case 120:
					// in future add start time to a different note for activator tail
					drumnotes.append((n.endTimeStamp, "120"))
				default:
					drumnotes.append((n.timeStamp, n.note.description))
					break
				}
			}
		}
		
		swapTomCymbal(cymbals: cymbal0, toms: &tom98	, dnotes: &drumnotes)
		swapTomCymbal(cymbals: cymbal1, toms: &tom99	, dnotes: &drumnotes)
		swapTomCymbal(cymbals: cymbal2, toms: &tom100	, dnotes: &drumnotes)
		
		for (f, start, end) in discoFlipMe {
			if f {
				for ( i, dn) in drumnotes.enumerated() {
					switch dn.0 {
					case start...end:
						if dn.1 == "97" {drumnotes[i].1 = "98"}
						if dn.1 == "98" {drumnotes[i].1 = "97"}
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
		let bpmlist 	= self.tempoEvents()
		var bpms:Double	= 0
		for t in bpmlist {
			bpms += t.bpm
		}
		bpms = round(bpms / Double(bpmlist.count))
		pace.setFPS(miditempo: bpms)
//		self.setOverallTempo(bpms)
		return bpms
	}
}

private extension FZMIK {
	/// swaps toms to cymbals for pro drums
	func swapTomCymbal (cymbals: Array<MIKMIDINoteEvent>, toms: inout Array<MIKMIDINoteEvent>, dnotes: inout [(Double, String)]){
		// removes the tom corresponding to cymbals
		for c in cymbals{
			for (i, t) in toms.enumerated().reversed() {
				switch t.timeStamp{
				case c.timeStamp...c.endTimeStamp:
					dnotes.append((t.timeStamp, c.note.description))
					toms.remove(at: i)
				default:
					break
				}
			}
		}
		//	add remainding results to drumnotes
		for r in toms{
			dnotes.append((r.timeStamp, r.note.description))
		}
	}
	
	/// makes and layes beat marks on the track
	///
	/// - Note: at the end of the track beats tend to dip
	func layBeat (tc: TimeCode) {
		
		let fatline 	= drumScene.rootNode.childNode(withName: "fatline"	, recursively: false)!
		let thinline 	= drumScene.rootNode.childNode(withName: "thinline"	, recursively: false)!
		var prev_beat = 0.0
		//		let beats		= SCNNode()
		for b in 1...Int(self.length) {
			let beat = tc.beattosec(beat: Double(b))
//			let halfbeat = tc.beattosec(beat: Double(b) * 0.5 )
			let halfbeat = prev_beat + ((beat - prev_beat) * 0.5)
				prev_beat = beat
			let fl 	= fatline.clone()
			let tl 	= thinline.clone()
			fl.position.z 	= CGFloat(beat) * pace.fps
			//			fl.name			= "fat"
			tl.position.z 	= CGFloat(halfbeat) * pace.fps
			//			tl.name			= "thin"
			hwy.beatlines.addChildNode(fl)
			hwy.beatlines.addChildNode(tl)
		}
		//		pistaBeats.addChildNode(beats)
		//		pistaBeats.addChildNode(thinpista)
	}
	
	func addtohidelist(gem:SCNNode) {
		
	}

}

enum Beat {
	case fat
	case thin
}

extension MIKMIDISynthesizer {
	private func linearGainToDB(gain: Float) 	-> Float { return 20.0 * log10(gain) }
	private func DBToLinearGain(db: Float) 		-> Float { return pow(10.0, db / 20.0) }
	
	var volume: Float {
		get {
			var result: Float = 0.0
			let err = AudioUnitGetParameter(instrumentUnit!, kAUSamplerParam_Gain, kAudioUnitScope_Global, 0, &result)
			if err != noErr {
				NSLog("Error getting volume of MIKMIDISynthesizer \(self): \(err)")
				return 0.0
			}
			return min(max(DBToLinearGain(db: result), 0.0), 1.0)
		}
		set {
			let valueInDB 	= linearGainToDB(gain: min(max(newValue, 0.0), 1.0))
			let err 		= AudioUnitSetParameter(instrumentUnit!, kAUSamplerParam_Gain, kAudioUnitScope_Global, 0, valueInDB, 0);
			if err != noErr { NSLog("Error setting volume of MIKMIDISynthesizer \(self): \(err)") }
		}
	}
}


