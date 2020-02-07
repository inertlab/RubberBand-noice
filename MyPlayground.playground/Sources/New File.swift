//
//  MIDIFrobs.swift
//  MusicSequence
//
//  Created by Gene De Lisa on 8/16/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import Foundation

import MediaPlayer
import AudioToolbox
//import AVFoundation

struct FZevents {
	var eventType:		MusicEventType
	var eventTimeStamp:	MusicTimeStamp
	var event:			Any
	//    var line:String = "\n"
}

/**
Loads a standard MIDIfile into a MusicSequence and displays the events to stdout.
*/
public class FZMIDI {
	
	public var currentMusicSequence:MusicSequence?
	
	init() {
		NewMusicSequence(&currentMusicSequence)
		print("init finished")
	}
	
	public init(withMIDIFile: CFURL) {
		NewMusicSequence(&currentMusicSequence)
		loadMIDIFile(filepath: withMIDIFile)
	}
	
	func displayStatus(status:OSStatus) {
		print("Bad status: \(status)")
		let nserror = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
		print("\(nserror.localizedDescription)")
		
		switch status {
		// ugly
		case OSStatus(kAudioToolboxErr_InvalidSequenceType):
			print("Invalid sequence type")
			
		case OSStatus(kAudioToolboxErr_TrackIndexError):
			print("Track index error")
			
		case OSStatus(kAudioToolboxErr_TrackNotFound):
			print("Track not found")
			
		case OSStatus(kAudioToolboxErr_EndOfTrack):
			print("End of track")
			
		case OSStatus(kAudioToolboxErr_StartOfTrack):
			print("start of track")
			
		case OSStatus(kAudioToolboxErr_IllegalTrackDestination):
			print("Illegal destination")
			
		case OSStatus(kAudioToolboxErr_NoSequence):
			print("No Sequence")
			
		case OSStatus(kAudioToolboxErr_InvalidEventType):
			print("Invalid Event Type")
			
		case OSStatus(kAudioToolboxErr_InvalidPlayerState):
			print("Invalid Player State")
			
		case OSStatus(kAudioToolboxErr_CannotDoInCurrentContext):
			print("Cannot do in current context")
			
		default:
			print("Something or other went wrong")
		}
	}
	
	func loadMIDIFile(filepath: CFURL) {
		let status = MusicSequenceFileLoad(currentMusicSequence!,
										   filepath,
										   .midiType,
										   .smf_PreserveTracks)
		if status != OSStatus(noErr) {
			print("\(#line) bad status \(status)")
			displayStatus(status: status)
			print("loading file")
		}
		// debugging using C(ore) A(udio) show.
	}
	
	public func getNumberOfTracks(musicSequence:MusicSequence) -> Int {
		var trackCount:UInt32 = 0
		let status = MusicSequenceGetTrackCount(musicSequence, &trackCount)
		if status != OSStatus(noErr) {
			displayStatus(status: status)
			//            print("getting track count")
		}
		return Int(trackCount)
	}
	
	func getNumberOfTracks() -> Int {
		return getNumberOfTracks(musicSequence: currentMusicSequence!)
	}
	
	func getTrackByIndex(musicSequence:MusicSequence, n:UInt32) -> MusicTrack {
		var track:MusicTrack?
		let status = MusicSequenceGetIndTrack(musicSequence, n, &track)
		if status != OSStatus(noErr) {
			displayStatus(status: status)
		}
		return track!
	}
	
	public func getTrackByIndex(n:Int) -> MusicTrack {
		var track:MusicTrack?
		let status = MusicSequenceGetIndTrack(currentMusicSequence!, UInt32(n), &track)
		if status != OSStatus(noErr) {
			displayStatus(status: status)
		}
		return track!
	}
	
	
	
	public func getDrumTrack() -> (Bool,MusicTrack) {
		
		var gotdrums = false
		var track:MusicTrack?
		
		let trackcount = getNumberOfTracks()
		
		print(trackcount)
		for t in 1..<trackcount {
			let status = MusicSequenceGetIndTrack(currentMusicSequence!, UInt32(t), &track)
			if status != OSStatus(noErr) {
				//				print("babd")
				displayStatus(status: status)
			}
			
			if findDrumTrack(track: track!){
				gotdrums = true
				break
			}
			
		}
		return (gotdrums, track!)
	}
	
	//MARK: display
	
	func display(musicSequence:MusicSequence)  {
		var status = OSStatus(noErr)
		
		var trackCount:UInt32 = 1
		status = MusicSequenceGetTrackCount(musicSequence, &trackCount)
		
		if status != OSStatus(noErr) {
			displayStatus(status: status)
			
			print("in display: getting track count")
		}
		print("There are \(trackCount) tracks")
		
		var track:MusicTrack?
		
		for i in 0...trackCount{
			status = MusicSequenceGetIndTrack(musicSequence, i, &track)
			
			if status != OSStatus(noErr) {
				displayStatus(status: status)
				
			}
			print("\n\nTrack \(i)")
			
			// getting track properties is ugly
			
			var trackLength:MusicTimeStamp = -1
			var prop:UInt32 = UInt32(kSequenceTrackProperty_TrackLength)
			// the size is filled in by the function
			var size:UInt32 = 0
			status = MusicTrackGetProperty(track!, prop, &trackLength, &size)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			print("track length \(trackLength)")
			
			var loopInfo:MusicTrackLoopInfo = MusicTrackLoopInfo(loopDuration: 0,numberOfLoops: 0)
			prop = UInt32(kSequenceTrackProperty_LoopInfo)
			status = MusicTrackGetProperty(track!, prop, &loopInfo, &size)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			print("loop info \(loopInfo.loopDuration)")
			
			iterate(track: track!)
		}
	}
	
	
	func display()  {
		display(musicSequence: currentMusicSequence!)
	}
	
	func getNumberOfEvents(track:MusicTrack) -> Int {
		var iterator:MusicEventIterator?
		var status = OSStatus(noErr)
		var numberOfEvents = 0
		status = NewMusicEventIterator(track, &iterator)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		var hasCurrentEvent:DarwinBoolean = false
		status = MusicEventIteratorHasCurrentEvent(iterator!, &hasCurrentEvent)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		var eventType:MusicEventType = 0
		var eventTimeStamp:MusicTimeStamp = -1
		var eventData: UnsafeRawPointer?
		var eventDataSize:UInt32 = 0
		
		while (hasCurrentEvent.boolValue) {
			status = MusicEventIteratorGetEventInfo(iterator!, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
			if status != OSStatus(noErr) {
				displayStatus(status: status)
			}
			numberOfEvents += 1
		}
		return numberOfEvents
	}
	
	func getMIDINoteMessages(trackN:Int) -> [MIDINoteMessage] {
		let track = self.getTrackByIndex(n: trackN)
		return getMIDINoteMessages(track: track)
	}
	
	func getMIDINoteMessages(track:MusicTrack) -> [MIDINoteMessage] {
		var iterator:MusicEventIterator?
		var status = OSStatus(noErr)
		var numberOfEvents = 0
		status = NewMusicEventIterator(track, &iterator)
		if status != OSStatus(noErr) {
			displayStatus(status: status)
			print("bad status \(status)")
		}
		var hasCurrentEvent:DarwinBoolean = false
		status = MusicEventIteratorHasCurrentEvent(iterator!, &hasCurrentEvent)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		var eventType:MusicEventType = 0
		var eventTimeStamp:MusicTimeStamp = -1
		var eventData: UnsafeRawPointer?
		var eventDataSize:UInt32 = 0
		var results:[MIDINoteMessage] = []
		while hasCurrentEvent.boolValue {
			status = MusicEventIteratorGetEventInfo(iterator!, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			if Int(eventType) == kMusicEventType_MIDINoteMessage {
				let data = eventData?.assumingMemoryBound(to: MIDINoteMessage.self)
				let note = data?.pointee
				results.append(note!)
			}
			numberOfEvents += 1
			status = MusicEventIteratorHasNextEvent(iterator!, &hasCurrentEvent)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			status = MusicEventIteratorNextEvent(iterator!)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
		}
		return results
	}
	
	func getTempoBeats() -> [(Double , String)] {
		
		let results = [(Double, String)]() //results get stored here
		var track:MusicTrack?
		MusicSequenceGetTempoTrack(currentMusicSequence!, &track)
		//			let track = getTrackByIndex(n: 0)
		//			print(track)
		//			var notetuple = (0.0, "")
		//			var tstamp = 0.0
		//			var tempnotes:[String: Double] = [:]
		
		var iterator:		MusicEventIterator?
		var status = 		OSStatus(noErr)
		status = 		NewMusicEventIterator(track!, &iterator)
		var numberOfEvents = 0
		if status != OSStatus(noErr) {
			displayStatus(status: status)
			print("bad status \(status)")
		}
		var hasCurrentEvent:DarwinBoolean = false
		status = MusicEventIteratorHasCurrentEvent(iterator!, &hasCurrentEvent)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		var eventType:		MusicEventType 		= 0
		var eventTimeStamp:	MusicTimeStamp 		= -1
		var eventDataSize:	UInt32 				= 0
		var eventData: 		UnsafeRawPointer?
		
		// loop trhough events
		while hasCurrentEvent.boolValue {
			
			//				print(stat)
			status = MusicEventIteratorGetEventInfo(iterator!, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			
			//				print(eventType)
			if Int(eventType) == kMusicEventType_ExtendedTempo {
				_ = eventData?.assumingMemoryBound(to: MIDIMetaEvent.self)
				//				let data2 = eventData?.assumingMemoryBound(to: MIDIMetaEvent.self)
				
				//					let event = data?.pointee
				//					let datarray = asArrayDeep(data: (data?.pointee.data)!)
				
				
				//					let str = String(bytes: datarray, encoding: String.Encoding.macOSRoman)
				
				
				//					print(data?.pointee)
			}
			numberOfEvents += 1
			status = MusicEventIteratorHasNextEvent(iterator!, &hasCurrentEvent)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			status = MusicEventIteratorNextEvent(iterator!)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
		}
		
		return results
	}
	
	func getDrumNotes() -> [(Double , String)] {
		
		let gotdrums = getDrumTrack()
		var results = [(Double, String)]() //results get stored here
		
		if gotdrums.0 {
			let track = getTrackByIndex(n: 1)
			
			var notetuple = (0.0, "")
			var tstamp = 0.0
			var tempnotes:[String: Double] = [:]
			
			var iterator:MusicEventIterator?
			var status = OSStatus(noErr)
			var numberOfEvents = 0
			status = NewMusicEventIterator(track, &iterator)
			if status != OSStatus(noErr) {
				displayStatus(status: status)
				print("bad status \(status)")
			}
			var hasCurrentEvent:DarwinBoolean = false
			status = MusicEventIteratorHasCurrentEvent(iterator!, &hasCurrentEvent)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			var eventType:MusicEventType = 0
			var eventTimeStamp:MusicTimeStamp = -1
			var eventData: UnsafeRawPointer?
			var eventDataSize:UInt32 = 0
			
			//		loop trhough events
			while hasCurrentEvent.boolValue {
				status = MusicEventIteratorGetEventInfo(iterator!, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
				if status != OSStatus(noErr) {
					print("bad status \(status)")
				}
				
				if Int(eventType) == kMusicEventType_MIDINoteMessage {
					let data = eventData?.assumingMemoryBound(to: MIDINoteMessage.self)
					let note = data?.pointee.note.description
					//				if timestamp has changed add tuples to results else add to dictionary
					tempnotes[note!] = eventTimeStamp
					switch note! {
					case "110":
						tempnotes["98"] = nil
					case "111":
						tempnotes["99"] = nil
					case "112":
						tempnotes["100"] = nil
					default:
						break;
					}
					if eventTimeStamp != tstamp {
						for (note, ts)  in tempnotes {
							notetuple = (ts, note)
							//						load results to tuple array
							results.append(notetuple)
						}
						tempnotes.removeAll()
						tstamp = eventTimeStamp
					}
				}
				numberOfEvents += 1
				status = MusicEventIteratorHasNextEvent(iterator!, &hasCurrentEvent)
				if status != OSStatus(noErr) {
					print("bad status \(status)")
				}
				status = MusicEventIteratorNextEvent(iterator!)
				if status != OSStatus(noErr) {
					print("bad status \(status)")
				}
			}
		}
		return results
	}
	
	
	public func getEvents(trackN:Int) -> [Any] {
		let track = self.getTrackByIndex(n: trackN)
		return getEvents(track:track)
	}
	
	public func getEvents(track:MusicTrack) -> [Any] {
		var iterator:MusicEventIterator?
		var status = OSStatus(noErr)
		status = NewMusicEventIterator(track, &iterator)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		
		var hasCurrentEvent:DarwinBoolean = false
		status = MusicEventIteratorHasCurrentEvent(iterator!, &hasCurrentEvent)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		
		var eventType		:MusicEventType = 0
		var eventTimeStamp	:MusicTimeStamp = -1
		var eventData		:UnsafeRawPointer?
		var eventDataSize	:UInt32 = 0
		var results			:[Any] = []
		while hasCurrentEvent.boolValue {
			status = MusicEventIteratorGetEventInfo(iterator!, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			
			switch eventType {
			case kMusicEventType_MIDINoteMessage:
				let data = eventData?.assumingMemoryBound(to: MIDINoteMessage.self)
				let note = data!.pointee
				
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: note)
				results.append(te)
				
				// results.append(note)
				break
				
			case kMusicEventType_ExtendedNote:
				let data = eventData?.assumingMemoryBound(to: ExtendedNoteOnEvent.self)
				let event = data!.pointee
				//                results.append(event)
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
				results.append(te)
				break
				
			case kMusicEventType_ExtendedTempo:
				let data = eventData?.assumingMemoryBound(to: ExtendedTempoEvent.self)
				let event = data!.pointee
				//                results.append(event)
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
				results.append(te)
				break
				
			case kMusicEventType_User:
				let data = eventData?.assumingMemoryBound(to: MusicEventUserData.self)
				let event = data!.pointee.data
				//                results.append(event)
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
				results.append(te)
				break
				
			case kMusicEventType_Meta:
				let data = eventData?.assumingMemoryBound(to: MIDIMetaEvent.self)
				let event = data!.pointee
				//                results.append(event)
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
				results.append(te)
				break
				
			case kMusicEventType_MIDIChannelMessage :
				let data = eventData?.assumingMemoryBound(to: MIDIChannelMessage.self)
				let cm = data!.pointee
				//                results.append(cm)
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: cm)
				results.append(te)
				break
				
			case kMusicEventType_MIDIRawData :
				let data = eventData?.assumingMemoryBound(to: MIDIRawData.self)
				let raw = data!.pointee
				//                results.append(raw)
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: raw)
				results.append(te)
				break
				
			case kMusicEventType_Parameter :
				let data = eventData?.assumingMemoryBound(to: ParameterEvent.self)
				let param = data!.pointee
				//                results.append(param)
				let te = FZevents(eventType: eventType, eventTimeStamp: eventTimeStamp, event: param)
				results.append(te)
				break
				
			default:
				print("something or other \(eventType)")
			}
			
			status = MusicEventIteratorHasNextEvent(iterator!, &hasCurrentEvent)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			status = MusicEventIteratorNextEvent(iterator!)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}            }
		return results
	}
	
	
	func findDrumTrack(track:MusicTrack) -> Bool {
		var isitdrums 	= false
		var iterator	: MusicEventIterator?
		var status 		= OSStatus(noErr)
		status 			= NewMusicEventIterator(track, &iterator)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		
		var eventType		:MusicEventType = 0
		var eventTimeStamp	:MusicTimeStamp = -1
		var eventData		:UnsafeRawPointer? = nil
		var eventDataSize	:UInt32 = 0
		
		status = MusicEventIteratorGetEventInfo(iterator!, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		
		switch eventType {
			
		case kMusicEventType_Meta:
			let data = eventData?.assumingMemoryBound(to: MIDIPacket.self)
			//				let data2 = eventData?.assumingMemoryBound(to: MIDIMetaEvent.self)
			
			let event = data?.pointee
			let datarray = asArrayDeep(data: event!.data)
			let str = datarray.string
			
//			let str = String(bytes: datarray!, encoding: String.Encoding.ascii)
			print(datarray)
			let split = str.components(separatedBy: "DRUMS")
			if split.count == 2{
				isitdrums = true
				print("found drums")
			}
			
			
		default:
			print("Not Drums")
		}
		
		status = MusicEventIteratorNextEvent(iterator!)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		
		return isitdrums
	}
	
	
	/**
	Itereates over a MusicTrack and prints the MIDI events it contains.
	
	:param: track:MusicTrack the track to iterate
	*/
	func iterate(track:MusicTrack) {
		var    iterator:MusicEventIterator?
		var status = OSStatus(noErr)
		status = NewMusicEventIterator(track, &iterator)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		
		var hasCurrentEvent:DarwinBoolean = false
		status = MusicEventIteratorHasCurrentEvent(iterator!, &hasCurrentEvent)
		if status != OSStatus(noErr) {
			print("bad status \(status)")
		}
		
		var eventType:MusicEventType = 0
		var eventTimeStamp:MusicTimeStamp = -1
		var eventData: UnsafeRawPointer? = nil
		var eventDataSize:UInt32 = 0
		
		while hasCurrentEvent.boolValue {
			status = MusicEventIteratorGetEventInfo(iterator!, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			
			switch eventType {
				
			case kMusicEventType_MIDINoteMessage:
				// let data = UnsafePointer<MIDINoteMessage>(eventData)
				let data = eventData?.assumingMemoryBound(to: MIDINoteMessage.self)
				let note = data?.pointee
				print("Note message \(String(describing: note!.note)), vel \(note!.velocity) dur \(note!.duration) at time \(eventTimeStamp)")
				break
				
			case kMusicEventType_ExtendedNote:
				let data = eventData?.assumingMemoryBound(to: ExtendedNoteOnEvent.self)
				_ = data?.pointee
				print("ext note message")
				break
				
			case kMusicEventType_ExtendedTempo:
				let data = eventData?.assumingMemoryBound(to: ExtendedTempoEvent.self)
				let event = data?.pointee
				print("ext tempo message")
				NSLog("ExtendedTempoEvent, bpm %f", event!.bpm)
				break
				
			case kMusicEventType_User:
				let data = eventData?.assumingMemoryBound(to: MusicEventUserData.self)
				_ = data?.pointee
				print("user message")
				break
				
			case kMusicEventType_Meta:
				let data = eventData?.assumingMemoryBound(to: MIDIMetaEvent.self)
				let event = data?.pointee
				print("meta message \(event!)")
				break
				
			case kMusicEventType_MIDIChannelMessage :
				let data = eventData?.assumingMemoryBound(to: MIDIChannelMessage.self)
				let cm = data?.pointee
				NSLog("channel event status %X", cm!.status)
				NSLog("channel event d1 %X", cm!.data1)
				NSLog("channel event d2 %X", cm!.data2)
				if (cm!.status == (0xC0 & 0xF0)) {
					print("preset is \(cm!.data1)")
				}
				break
				
			case kMusicEventType_MIDIRawData :
				let data = eventData?.assumingMemoryBound(to: MIDIRawData.self)
				let raw = data?.pointee
				NSLog("MIDIRawData i.e. SysEx, length %lu", raw!.length)
				break
				
			case kMusicEventType_Parameter :
				let data = eventData?.assumingMemoryBound(to: ParameterEvent.self)
				let param = data?.pointee
				NSLog("ParameterEvent, parameterid %lu", param!.parameterID)
				break
				
			default:
				print("something or other \(eventType)")
			}
			
			status = MusicEventIteratorHasNextEvent(iterator!, &hasCurrentEvent)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			
			status = MusicEventIteratorNextEvent(iterator!)
			if status != OSStatus(noErr) {
				print("bad status \(status)")
			}
			
		}
	}
	
}


extension MIDIPacket {
	public var asArray: [UInt8] {
		let mirror = Mirror(reflecting: self.data)
		let length = Int(self.length)
		
		var result = [UInt8]()
		result.reserveCapacity(length)
		
		for (n, child) in mirror.children.enumerated() {
			if n == length {
				break
			}
			result.append(child.value as! UInt8)
		}
		return result
	}
	
}

func asArrayDeep(data: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) -> [UInt8] {
	let mirror = Mirror(reflecting: (data))
	//	let length = Mirror.Children.count
	let length = Int(Mirror(reflecting: data).children.count)
	var result = [UInt8]()
	result.reserveCapacity(length)
	
	for (n, child) in mirror.children.enumerated() {
		if n == length {
			break
		}
		result.append(child.value as! UInt8)
	}
	return result
}



extension Collection where Element == UInt8 {
	var string: String {
		return String(bytes: self, encoding: .utf8) ?? ""
	}
}
