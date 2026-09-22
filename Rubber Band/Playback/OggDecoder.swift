//
//  OggDecoder.swift
//  noice
//
//  Created by fernando on 9/13/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//


import AVFoundation
import LibVorbis


final class OggDecoder:AudioDecoder {
	private var vf = OggVorbis_File()
	private var isFileOpen = false
	private let sampleRate: Double
	private let channels: AVAudioChannelCount
	let format: AVAudioFormat
	var length: Double
	var cmtime = CMTime(seconds: 0, preferredTimescale: 44100)
	
	init?(url: URL) {
		guard FileManager.default.fileExists(atPath: url.path) else {
			print("File does not exist at \(url.path)")
			return nil
		}
		
		let status = ov_fopen(url.path, &vf)
		guard status == 0 else {
			print("ov_fopen failed with error code: \(status)")
			return nil
		}
		
		guard let vi = ov_info(&vf, -1) else {
			ov_clear(&vf)
			return nil
		}
		
		self.isFileOpen = true
		self.sampleRate = Double(vi.pointee.rate)
		self.channels = AVAudioChannelCount(vi.pointee.channels)
		
		guard let fmt = AVAudioFormat(standardFormatWithSampleRate: self.sampleRate, channels: self.channels) else {
			ov_clear(&vf)
			return nil
		}
		self.format = fmt
		
		guard let infoPtr = ov_info(&vf, -1) else {
			fatalError("Unable to read Vorbis header info")
		}

		// 2. Dereference the pointer to access struct properties
		let info = infoPtr.pointee
		let sampleRate = info.rate        // e.g., 44100 (Int32 or Clong)
//		let channels = info.channels      // e.g., 2

		// 3. Get total PCM frames across the stream
		let totalPCMFrameCount = ov_pcm_total(&vf, -1)

		// 4. Calculate total duration in seconds
		self.length =  Double(totalPCMFrameCount) / Double(sampleRate)
	
		// 10,584,000 / 44100 = 240.0 seconds (4 minutes)
	}
	
	deinit {
		if isFileOpen {
			ov_clear(&vf)
		}
	}
	
	/// Reads the next slice of audio (e.g. 1.0 second chunk) from the open Vorbis file handle.
	func readNextChunk(duration: TimeInterval) -> AVAudioPCMBuffer? {
		let targetFrames = AVAudioFrameCount(duration * format.sampleRate) // e.g. 11025 frames
		
		// Allocate buffer with a bit of extra frame capacity headroom
		let bufferCapacity = targetFrames + 4096
		guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferCapacity) else {
			return nil
		}
		
		var framesRead: Int = 0
		let channels = Int(format.channelCount)
		
		while framesRead < Int(targetFrames) {
			var pcmChannels: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>?
			var currentSection: Int32 = 0
			
			// Request only up to remaining target frames or 4096 block limit
			let framesToRequest = min(4096, Int(targetFrames) - framesRead)
			if framesToRequest <= 0 { break }
			
			let readResult = ov_read_float(&vf, &pcmChannels, Int32(framesToRequest), &currentSection)
			
			if readResult <= 0 {
				// EOF or error
				break
			}
			let samplesPerChannel = Int(readResult)
			
			// Prevent writing past buffer capacity
			let framesToCopy = min(samplesPerChannel, Int(bufferCapacity) - framesRead)
			if framesToCopy <= 0 { break }
			
			if let pcmChannels = pcmChannels {
				for ch in 0..<channels {
					if let srcChannel = pcmChannels[ch],
					   let destChannel = pcmBuffer.floatChannelData?[ch] {
						let destPtr = destChannel.advanced(by: framesRead)
						destPtr.initialize(from: srcChannel, count: framesToCopy)
					}
				}
			}
			
			framesRead += framesToCopy
		}
		
		guard framesRead > 0 else { return nil }
		
		// Safely clamped: framesRead is guaranteed <= bufferCapacity
		pcmBuffer.frameLength = AVAudioFrameCount(framesRead)
		
		return pcmBuffer
	}
}


extension OggDecoder {
	/// Seeks the file handle directly to a specific time in seconds using LibVorbis
	func seek(toSeconds seconds: Double) -> Bool {
		guard isFileOpen else { return false }
		// ov_time_seek takes time in seconds (Double)
		let result = ov_time_seek(&vf, seconds)
		cmtime = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(self.format.sampleRate))
		if result != 0 {
			print("ov_time_seek failed with error code: \(result)")
			return false
		}
		return true
	}
	
<<<<<<< HEAD
	func readNextSampleBuffer(presentationTime: CMTime) -> CMSampleBuffer? {
//		print("OGG presentationTime:", presentationTime.seconds)
=======
	func readNextSampleBuffer() -> CMSampleBuffer? {
>>>>>>> vocal_change
		// 1. Read PCM chunk from libvorbis
		guard let pcmBuffer = self.readNextChunk(duration: 0.25) else {
			return nil
		}

		// 2. Ensure frameLength is non-zero
		guard pcmBuffer.frameLength > 0 else {
			return nil
		}
		
		// 3. Convert to CMSampleBuffer with presentation timestamp
<<<<<<< HEAD
		guard let sampleBuffer = pcmBuffer.toCMSampleBuffer(presentationTime: presentationTime) else {
=======
		guard let sampleBuffer = pcmBuffer.toCMSampleBuffer(presentationTime: cmtime) else {
>>>>>>> vocal_change
			print("[OggDecoder] Failed to convert AVAudioPCMBuffer to CMSampleBuffer")
			return nil
		}
		cmtime = CMTimeAdd(sampleBuffer.duration, cmtime)
		return sampleBuffer
	}
}

