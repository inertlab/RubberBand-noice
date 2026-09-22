import Foundation
import AudioToolbox



/// MIDI note evets catergorized into note, lyric and meta
///
/// time: and end: are in seconds, length: is in beats
/// beats: is required for tail score calculations, visuals are all in seconds
/// var duration: returns length in seconds
enum NoteEvent {
	case note(note: UInt8, time: Float64, end: Float64, length: Float32)
	case lyric(text: String)
	case meta(type: String, time: Float64)
	
	var duration: Float64? {
		switch self {
		case .note(_, let time, let end, _): return end - time
		default: return nil
		}
	}
	
	var time: Float64 {
		switch self {
		case .note(_, let time, _, _), .meta(_, let time): return time
		case .lyric: return 0
		}
	}
	
	var end: Float64? {
		switch self {
		case .note(_, _, let end, _): return end
		default: return nil
		}
	}
	
	var note: UInt8? {
		switch self {
		case .note(let note, _,_,_): return note
		default: return 0
		}
	}
}

typealias NoteEvents = Array<NoteEvent>


/// retrieves MIDI events
///
/// Gets instantiated at the begining of every song
/// notes: are all the notes for the User selected instrument
/// lyrics:, beats: and tempos: are required for any song
final class FZMIDI {
	private(set) var sequence: MusicSequence?
	var lyrics: NoteEvents?
	var notes: NoteEvents?
	var beats: NoteEvents?
	var tempos: [Float64]?

	init?(url: URL) {
		guard NewMusicSequence(&sequence) == noErr, let sequence = sequence else { return nil }
		
		let status = MusicSequenceFileLoad(sequence, url as CFURL, .midiType, .smf_PreserveTracks)
		if status != noErr {
			print("Failed to load MIDI file: \(status)")
			return nil
		}
		
		tempos = gettempos()
		lyrics = gettrackevents(name: .vocals)
		notes = gettrackevents(name: User.current.instrument.track())
		beats = gettrackevents(name: .beat)
//		print(lyrics)
	}
	
	deinit {
		if let sequence = sequence {
			DisposeMusicSequence(sequence)
		}
	}
	
	var trackCount: Int {
		guard let sequence = sequence else { return 0 }
		var count: UInt32 = 0
		MusicSequenceGetTrackCount(sequence, &count)
		return Int(count)
	}
	
	func gettrackevents(name: TrackName) -> NoteEvents? {
		if let trackindex = findindex(name: name) {
			return parseEvents(forTrackIndex: trackindex)
		}
		print("didn't find any events in track ", name)
		return nil
	}
	
	private func findindex(name: TrackName) -> Int? {
		for index in 0...trackCount{
			if let events = parseEvents(forTrackIndex: index, eventcount: 4){
				for e in events {
					if case .meta(let type, _) = e {
						if type == name.rawValue {return index}
					}
				}
			}
		}
		return nil
	}

	
	/// Parses events for a given track index (0-indexed)
	private func parseEvents(forTrackIndex index: Int, eventcount: Int = .max) -> [NoteEvent]? {
		guard let sequence = sequence else { return nil}
		
		var track: MusicTrack?
		guard MusicSequenceGetIndTrack(sequence, UInt32(index), &track) == noErr,
			  let track = track else { return nil}
		
		var iterator: MusicEventIterator?
		guard NewMusicEventIterator(track, &iterator) == noErr, let iterator = iterator else { return nil}
		defer { DisposeMusicEventIterator(iterator) }
		
		var events: [NoteEvent] = []
		var hasCurrentEvent: DarwinBoolean = false
		MusicEventIteratorHasCurrentEvent(iterator, &hasCurrentEvent)
		
		while hasCurrentEvent.boolValue && events.count < eventcount {
			var timestamp: MusicTimeStamp = 0
			var type: MusicEventType = 0
			var dataPointer: UnsafeRawPointer?
			var dataSize: UInt32 = 0
			
			MusicEventIteratorGetEventInfo(iterator, &timestamp, &type, &dataPointer, &dataSize)
			
			if let event = parseEventPayload(type: type, timestamp: timestamp, pointer: dataPointer, size: dataSize) {
				events.append(event)
			}
			
			MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
			if hasCurrentEvent.boolValue {
				MusicEventIteratorNextEvent(iterator)
			}
		}
		return events
	}
	
	private func parseEventPayload(type: MusicEventType, timestamp: MusicTimeStamp, pointer: UnsafeRawPointer?, size: UInt32) -> NoteEvent? {
		guard let pointer = pointer else { return nil }
		
		var seconds: MusicTimeStamp = 0
		MusicSequenceGetSecondsForBeats(sequence!, timestamp, &seconds)
		
		switch type {
		case kMusicEventType_MIDINoteMessage:
			let note = pointer.assumingMemoryBound(to: MIDINoteMessage.self).pointee
			var endtime: MusicTimeStamp = 0
			
			MusicSequenceGetSecondsForBeats(sequence!, timestamp + Double(note.duration), &endtime)
			return NoteEvent.note(note: note.note, time: seconds, end: endtime, length: note.duration)
		case kMusicEventType_Meta:
			let metaPointer = pointer.assumingMemoryBound(to: MIDIMetaEvent.self)
			let meta = metaPointer.pointee
			let length = Int(meta.dataLength)
			// Extract variable length data safely via memory offset
			let dataOffset = MemoryLayout<MIDIMetaEvent>.offset(of: \MIDIMetaEvent.data)!
			let payloadPointer = pointer.advanced(by: dataOffset)
			let bytes = Array(UnsafeRawBufferPointer(start: payloadPointer, count: length))
			
			let text = String(bytes: bytes, encoding: .ascii)
				?? String(bytes: bytes, encoding: .utf8) // this does in fact fail with Juanes
				?? String(bytes: bytes, encoding: .windowsCP1252)
				?? ""
						
			if meta.metaEventType == 5 {
				return NoteEvent.lyric(text: text)
			} else {
				return NoteEvent.meta(type: text, time: seconds)
			}
		default:
			return nil
		}
	}
	
	private func gettempos() -> [Float64] {
		guard let sequence = sequence else { return [] }
		
		var tempoTrack: MusicTrack?
		
		guard MusicSequenceGetTempoTrack(sequence, &tempoTrack) == noErr,
			  let track = tempoTrack else { return [] }
			  
		var iterator: MusicEventIterator?
		guard NewMusicEventIterator(track, &iterator) == noErr, let iterator = iterator else { return [] }
		defer { DisposeMusicEventIterator(iterator) }
		
		var tempos = [Float64]()
		
		var hasCurrentEvent: DarwinBoolean = false
		MusicEventIteratorHasCurrentEvent(iterator, &hasCurrentEvent)
		
		while hasCurrentEvent.boolValue {
			var timestamp: MusicTimeStamp = 0
			var type: MusicEventType = 0
			var dataPointer: UnsafeRawPointer?
			var dataSize: UInt32 = 0
			
			MusicEventIteratorGetEventInfo(iterator, &timestamp, &type, &dataPointer, &dataSize)
			
			// ExtendedTempoEvent matches here on the Tempo Track
			if type == kMusicEventType_ExtendedTempo, let pointer = dataPointer {
				let tempo = pointer.assumingMemoryBound(to: ExtendedTempoEvent.self).pointee
				tempos.append(tempo.bpm)
			}
			
			MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
			if hasCurrentEvent.boolValue {
				MusicEventIteratorNextEvent(iterator)
			}
		}
		return tempos
	}
	
	func getmusiclength() -> (beats: MusicTimeStamp, seconds: MusicTimeStamp)  {
		guard let sequence = sequence else { return (0, 0) }
		
		var trackCount: UInt32 = 0
		MusicSequenceGetTrackCount(sequence, &trackCount)
		
		var length: MusicTimeStamp = 0.0
		
		for i in 0..<trackCount {
			var track: MusicTrack?
			if MusicSequenceGetIndTrack(sequence, i, &track) == noErr, let track = track {
				var trackLength: MusicTimeStamp = 0.0
				var propertySize = UInt32(MemoryLayout<MusicTimeStamp>.size)
				
				// Query the track length property
				let status = MusicTrackGetProperty(
					track,
					kSequenceTrackProperty_TrackLength,
					&trackLength,
					&propertySize
				)
				
				if status == noErr {
					length = max(length, trackLength)
				}
			}
		}
		
		var seconds: MusicTimeStamp = 0
		MusicSequenceGetSecondsForBeats(sequence, length, &seconds)
		
		return (length, seconds)
	}
	
}
