//
//  PlaybackState.swift
//  noice
//
//  Created by fernando on 9/18/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//

import AVFoundation

@MainActor
final class OggAudioPlayer {
	private let engine = AVAudioEngine()
	private let playerNode = AVAudioPlayerNode()
	private var streamTask: Task<Void, Never>?
	
	init() {
		engine.attach(playerNode)
	}
	
	func play(fileURL: URL) {
		streamTask?.cancel()
		playerNode.stop()
		engine.stop()
		
		guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return }
		let decoder = OggVorbisDecoder()
		
		streamTask = Task {
			var isAudioSetup = false
			
			for await channelBuffers in decoder.pcmStream(from: fileHandle) {
				if Task.isCancelled { break }
				guard !channelBuffers.isEmpty else { continue }
				
				if !isAudioSetup {
					let sampleRate = Double(decoder.vorbisInfo.rate)
					let channels = UInt32(decoder.vorbisInfo.channels)
					
					print("Decoder Sample Rate: \(sampleRate) Hz, Channels: \(channels)")
					
					guard sampleRate > 0 && channels > 0,
						  let format = AVAudioFormat(
							commonFormat: .pcmFormatFloat32,
							sampleRate: sampleRate,
							channels: channels,
							interleaved: false
						  ) else { return }
					
					// 1. Force mainMixerNode initialization to prepare engine output graph
					let mixer = engine.mainMixerNode
					
					// 2. Connect playerNode to mixer using the source file's format
					engine.connect(playerNode, to: mixer, format: format)
					
					// 3. Prepare & start engine
					engine.prepare()
					do {
						try engine.start()
						playerNode.play()
						isAudioSetup = true
					} catch {
						print("Engine start error: \(error)")
						return
					}
				}
				
				scheduleBuffer(channelBuffers, decoder: decoder)
			}
		}
	}
	
	private func scheduleBuffer(_ channelBuffers: [[Float]], decoder: OggVorbisDecoder) {
		let sampleRate = Double(decoder.vorbisInfo.rate)
		let channels = UInt32(decoder.vorbisInfo.channels)
		
		// Exact frame count per channel
		let frameCount = AVAudioFrameCount(channelBuffers[0].count)
		
		guard frameCount > 0,
			  let format = AVAudioFormat(
				commonFormat: .pcmFormatFloat32,
				sampleRate: sampleRate,
				channels: channels,
				interleaved: false
			  ),
			  let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
			  let floatChannelData = pcmBuffer.floatChannelData else { return }
		
		pcmBuffer.frameLength = frameCount
		
		// Copy channel data directly to buffer pointers
		for ch in 0..<Int(channels) {
			let channelPointer = floatChannelData[ch]
			channelBuffers[ch].withUnsafeBufferPointer { ptr in
				if let baseAddress = ptr.baseAddress {
					memcpy(channelPointer, baseAddress, Int(frameCount) * MemoryLayout<Float>.size)
				}
			}
		}
		
		playerNode.scheduleBuffer(pcmBuffer)
	}
}
