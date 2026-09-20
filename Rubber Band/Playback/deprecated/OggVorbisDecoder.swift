//
//  OggVorbisDecoder.swift
//  noice
//
//  Created by fernando on 9/18/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//


import Foundation
import LibVorbis


final class OggVorbisDecoder {
	private var syncState = ogg_sync_state()
	private var streamState = ogg_stream_state()
	var vorbisInfo = vorbis_info()
	private var vorbisComment = vorbis_comment()
	private var dspState = vorbis_dsp_state()
	private var vorbisBlock = vorbis_block()
	
	private var streamInitialized = false
	private var dspInitialized = false

	init() {
		ogg_sync_init(&syncState)
		vorbis_info_init(&vorbisInfo)
		vorbis_comment_init(&vorbisComment)
	}

	deinit {
		if dspInitialized {
			vorbis_block_clear(&vorbisBlock)
			vorbis_dsp_clear(&dspState)
		}
		if streamInitialized {
			ogg_stream_clear(&streamState)
		}
		vorbis_comment_clear(&vorbisComment)
		vorbis_info_clear(&vorbisInfo)
		ogg_sync_clear(&syncState)
	}

	// Change return type to AsyncStream<[[Float]]>
	func pcmStream(from fileHandle: FileHandle, bufferSize: Int = 4096) -> AsyncStream<[[Float]]> {
		AsyncStream { continuation in
			let task = Task {
				var packet = ogg_packet()
				var page = ogg_page()
				
				while !Task.isCancelled {
					let packetResult = ogg_stream_packetout(&self.streamState, &packet)
					
					if packetResult == 1 {
						// processPacket now passes [[Float]] directly to continuation.yield
						self.processPacket(&packet) { pcmChunk in
							continuation.yield(pcmChunk)
						}
						continue
					}
					
					let pageResult = ogg_sync_pageout(&self.syncState, &page)
					
					if pageResult == 1 {
						if !self.streamInitialized {
							let serial = ogg_page_serialno(&page)
							ogg_stream_init(&self.streamState, serial)
							self.streamInitialized = true
						}
						ogg_stream_pagein(&self.streamState, &page)
						continue
					}
					
					guard let rawBuffer = ogg_sync_buffer(&self.syncState, bufferSize) else {
						continuation.finish()
						return
					}
					
					do {
						guard let chunk = try fileHandle.read(upToCount: bufferSize), !chunk.isEmpty else {
							continuation.finish()
							return
						}
						
						chunk.withUnsafeBytes { ptr in
							if let baseAddress = ptr.baseAddress {
								memcpy(rawBuffer, baseAddress, chunk.count)
							}
						}
						ogg_sync_wrote(&self.syncState, chunk.count)
						
					} catch {
						continuation.finish()
						return
					}
				}
				continuation.finish()
			}
			
			continuation.onTermination = { _ in task.cancel() }
		}
	}
	private func processPacket(_ packet: UnsafeMutablePointer<ogg_packet>, emitPCM: ([[Float]]) -> Void) {
		if !dspInitialized {
			let headerResult = vorbis_synthesis_headerin(&vorbisInfo, &vorbisComment, packet)
			if headerResult == 0 && vorbisInfo.rate > 0 && vorbisInfo.channels > 0 {
				if vorbis_synthesis_init(&dspState, &vorbisInfo) == 0 {
					vorbis_block_init(&dspState, &vorbisBlock)
					dspInitialized = true
				}
			}
			return
		}

		if vorbis_synthesis(&vorbisBlock, packet) == 0 {
			vorbis_synthesis_blockin(&dspState, &vorbisBlock)
			
			var pcmPtr: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>?
			
			while true {
				let sampleCount = vorbis_synthesis_pcmout(&dspState, &pcmPtr)
				guard sampleCount > 0, let pcm = pcmPtr else { break }
				
				let channels = Int(vorbisInfo.channels)
				let samples = Int(sampleCount)
				
				// 2D Array: outer index = channel, inner index = sample
				var channelBuffers = [[Float]](repeating: [Float](repeating: 0, count: samples), count: channels)
				
				for ch in 0..<channels {
					if let channelData = pcm[ch] {
						channelBuffers[ch] = Array(UnsafeBufferPointer(start: channelData, count: samples))
					}
				}
				
				// EMIT 2D ARRAY [[Float]]
				emitPCM(channelBuffers)
				vorbis_synthesis_read(&dspState, sampleCount)
			}
		}
	}}

extension OggVorbisDecoder {
	
	/// Seeks the OGG stream to the requested timestamp in seconds.
	func seek(to targetSeconds: Double, fileHandle: FileHandle, fileSize: UInt64) throws {
		guard vorbisInfo.rate > 0 else { return }
		
		let sampleRate = Double(vorbisInfo.rate)
		let targetSample = Int64(targetSeconds * sampleRate)
		
		// 1. Reset OGG bitstream and sync layer states
		ogg_sync_reset(&syncState)
		if streamInitialized {
			ogg_stream_reset(&streamState)
		}
		
		// 2. Estimate byte position (Rough jump)
		// Note: For exact seeking, an index or bisection search on granulepos across pages is used.
		try? fileHandle.seek(toOffset: 0)
		let targetByteOffset = UInt64(Double(fileSize) * (targetSeconds / estimatedDurationSeconds(fileSize: fileSize)))
		try fileHandle.seek(toOffset: min(targetByteOffset, fileSize))
		
		// 3. Scan forward to find the next valid page boundary
		var page = ogg_page()
		var synced = false
		let bufferSize = 4096
		
		while !synced {
			let result = ogg_sync_pageseek(&syncState, &page)
			if result > 0 {
				// Found page boundary; verify granulepos alignment
				let pageGranule = ogg_page_granulepos(&page)
				if pageGranule >= 0 {
					synced = true
					ogg_stream_pagein(&streamState, &page)
				}
			} else if result == 0 {
				// Need more bytes from disk to align page boundary
				guard let rawBuffer = ogg_sync_buffer(&syncState, bufferSize),
					  let chunk = try fileHandle.read(upToCount: bufferSize),
					  !chunk.isEmpty else { break }
				
				chunk.withUnsafeBytes { ptr in
					if let baseAddress = ptr.baseAddress {
						memcpy(rawBuffer, baseAddress, chunk.count)
					}
				}
				ogg_sync_wrote(&syncState, chunk.count)
			} else {
				// Skipped bad bytes (-result bytes skipped to sync)
				continue
			}
		}
		
		// 4. Reset Vorbis DSP decoder context (clears internal synthesis history)
		if dspInitialized {
			vorbis_synthesis_restart(&dspState)
		}
	}
	
	private func estimatedDurationSeconds(fileSize: UInt64) -> Double {
		// Fallback or header-derived duration estimation
		return 180.0 // Replace with actual total duration from OGG trailer page granulepos
	}
}


