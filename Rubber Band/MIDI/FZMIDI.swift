import Foundation
import AudioToolbox



/// MIDI note evets catergorized into note, lyric and meta
///
/// time: and end: are in seconds, length: is in beats
/// beats: is required for tail score calculations, visuals are all in seconds
/// var duration: returns length in seconds
enum NoteEvent {
	case note(note: UInt8, time: Float64, end: Float64, length: Float32)
	case lyric(text: String, time: Float64)
	case meta(type: String, time: Float64)
	
	var duration: Float64? {
		switch self {
		case .note(_, let time, let end, _): return end - time
		default: return nil
		}
	}
	
	var time: Float64 {
		switch self {
		case .note(_, let time, _, _), .meta(_, let time), .lyric(_, let time): return time
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
	
	var meta: String {
		switch self {
		case .meta(let meta, _): return meta
		default: return "nada"
		}
	}
}

typealias NoteEvents = Array<NoteEvent>
typealias Tempo = (tempo: Float64, time: Float64)

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
	var tempos: [Tempo]?
	var signature = (num: UInt8(4), denom: 4)
	private var encoding = String.Encoding.utf8
	
	var trackCount: Int {
		guard let sequence = sequence else { return 0 }
		var count: UInt32 = 0
		MusicSequenceGetTrackCount(sequence, &count)
		return Int(count)
	}

	init?() {
		guard let url = smanager.selected.song.folder?.appendingPathComponent("notes.mid") else {return nil}

		guard NewMusicSequence(&sequence) == noErr, let sequence = sequence else { return nil }
		
		let status = MusicSequenceFileLoad(sequence, url as CFURL, .midiType, .smf_PreserveTracks)
		if status != noErr {
			print("Failed to load MIDI file: \(status)")
			return nil
		}
	}
	
	deinit {
		if let sequence = sequence {
			DisposeMusicSequence(sequence)
		}
	}
	
	func config() {
		encoding = parseencoding()
		lyrics = gettrackevents(name: .vocals)
		tempos = gettempos()
		notes = gettrackevents(name: User.current.instrument.track())
		beats = gettrackevents(name: .beat)
	}
	
	func events() -> NoteEvents? {
		if let events = gettrackevents(name: .events) {
			return events
		}
		return nil
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
	
	private func parseencoding() -> String.Encoding {
		guard let sequence = sequence else { return .utf8 }
			
		var track: MusicTrack?
		guard let index = findindex(name: .vocals) else {return .utf8}
		guard MusicSequenceGetIndTrack(sequence, UInt32(index), &track) == noErr,
			  let track = track else { return .utf8 }
		
		// -------------------------------------------------------------
		// PASS 1: Pre-scan raw byte payloads to lock in ONE encoding
		// -------------------------------------------------------------
		var rawTextPayloads: [[UInt8]] = []
		
		
		var iterator: MusicEventIterator?
		guard NewMusicEventIterator(track, &iterator) == noErr, let iterator = iterator else { return .utf8}
		defer { DisposeMusicEventIterator(iterator) }
		
		var hasCurrentEvent: DarwinBoolean = false
		MusicEventIteratorHasCurrentEvent(iterator, &hasCurrentEvent)
		
		while hasCurrentEvent.boolValue {
			var timestamp: MusicTimeStamp = 0
			var type: MusicEventType = 0
			var dataPointer: UnsafeRawPointer?
			var dataSize: UInt32 = 0
			
			MusicEventIteratorGetEventInfo(iterator, &timestamp, &type, &dataPointer, &dataSize)
			
			if type == kMusicEventType_Meta, let pointer = dataPointer {
				let meta = pointer.assumingMemoryBound(to: MIDIMetaEvent.self).pointee
				// Focus on Text (0x01), Track Name (0x03), and Lyric (0x05)
				if meta.metaEventType == 5 {
					let length = Int(meta.dataLength)
					let dataOffset = MemoryLayout<MIDIMetaEvent>.offset(of: \MIDIMetaEvent.data)!
					let payloadPointer = pointer.advanced(by: dataOffset)
					let bytes = Array(UnsafeRawBufferPointer(start: payloadPointer, count: length))
						.filter { $0 != 0 }
					
					if !bytes.isEmpty {
						rawTextPayloads.append(bytes)
					}
				}
			}
			
			MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
			if hasCurrentEvent.boolValue {
				MusicEventIteratorNextEvent(iterator)
			}
		}
		
		return MIDIEncodingDetector.detectBestEncoding(for: rawTextPayloads)
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
			
			let text = String(bytes: bytes, encoding: encoding)
				?? ""
						
			if meta.metaEventType == 5 {
				return NoteEvent.lyric(text: text, time: seconds)
			} else {
				return NoteEvent.meta(type: text, time: seconds)
			}
		default:
			return nil
		}
	}
	
	/// Used to determin Average Tempo and set the animation speed of track
	/// - Returns: Array of Tempos - (tempo: Float64, time: Float64)
	/// - Note: time is in Seconds
	private func gettempos() -> [Tempo] {
		guard let sequence = sequence else { return [] }
		
		var tempoTrack: MusicTrack?
		
		guard MusicSequenceGetTempoTrack(sequence, &tempoTrack) == noErr,
			  let track = tempoTrack else { return [] }
			  
		var iterator: MusicEventIterator?
		guard NewMusicEventIterator(track, &iterator) == noErr, let iterator = iterator else { return [] }
		defer { DisposeMusicEventIterator(iterator) }
		
		var tempos = [Tempo]()
		
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
				tempos.append((tempo: tempo.bpm, time: timestamp))
			}
			
			if type == kMusicEventType_Meta, let data = dataPointer {
//				print("found meta type: ", type)
				let metaEvent = data.assumingMemoryBound(to: MIDIMetaEvent.self).pointee
				
				// 0x58 is the Meta Event type for Time Signature
				if metaEvent.metaEventType == 88 {
						
						// 1. Point to the start of the payload byte array in raw memory
						// Layout: metaEventType (1 byte) + unused (1 byte) + dataLength (4 bytes) + data...
						// The data payload starts at offset 6 from eventData:
//						let dataLength = Int(metaEvent.dataLength) // Should be 4
						
						// Advanced raw pointer directly to the payload start
						let payloadPtr = data.advanced(by: MemoryLayout<MIDIMetaEvent>.offset(of: \MIDIMetaEvent.data)!)
							.assumingMemoryBound(to: UInt8.self)
						
						// 2. Read the 4 payload bytes directly from memory
						let numerator = payloadPtr[0]
						let denominatorExponent = payloadPtr[1]
						let denominator = 1 << denominatorExponent // 2^dd (e.g. 1 << 2 = 4)
//						let clocksPerClick = payloadPtr[2]
//						let thirtySecondNotes = payloadPtr[3]
					signature = (num: numerator, denom: denominator)
//						print("Time Signature: \(numerator)/\(denominator)")
					}
			}
			
			MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
			if hasCurrentEvent.boolValue {
				MusicEventIteratorNextEvent(iterator)
			}
		}
		
		return tempos
	}
	
	/// The total length of midi in both Beats and Seconds
	/// - Returns: Tuple with beats and seconds
	/// - Use beats when no Beats track is included, beats are required for score tracking
	/// - Seconds is used for song length when [end] meta event is not present
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
	
	/// Gets all beats in the longest track in Seconds
	/// - Returns: an Array of seconds corresponding to each beat
	/// - Used when no "Beats" track is inlcuded in the midi file
	/// - Use in combination with Time Signature for layout
	func getbeats() -> [MusicTimeStamp]  {
		guard let sequence = sequence else { return [0] }
		
		var beats = [MusicTimeStamp]()
		let length = getmusiclength()
		
		for beat in 1...Int(length.beats) {
			
			var seconds: MusicTimeStamp = 0
			MusicSequenceGetSecondsForBeats(sequence, MusicTimeStamp(beat), &seconds)
			beats.append(seconds)
		}
		return beats
	}
	
}
