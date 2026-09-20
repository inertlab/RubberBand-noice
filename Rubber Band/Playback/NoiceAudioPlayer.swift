//
//  nOggPlayer.swift
//  noice
//
//  Created by fernando on 9/13/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//


import AVFoundation
import LibVorbis

actor TrackManager {
	private(set) var volume: Float = 1.0 {
		didSet {
			for (_, rend) in renderers { rend.volume = volume }
		}
	}
	
	var synchronizer = AVSampleBufferRenderSynchronizer()

	private var decoders: [Jukebox.Track: AudioDecoder] = [:]
	private var buffers: [Jukebox.Track: CMTime] = [:]
	private var renderers: [Jukebox.Track: AVSampleBufferAudioRenderer] = [:]
	private(set) var isplaying = false
	
	
	
	func setup(trackurl: [Jukebox.Track: URL], start: Double = 0) -> Double {

		var maxLength = 0.0
		let startTime = CMTime(seconds: start, preferredTimescale: 44100)
		synchronizer.setRate(1.0, time: startTime)
		
		for (track, url) in trackurl {
			// Instantiate OGG or M4A decoder based on extension
			let ext = url.pathExtension.lowercased()
			let decoder: AudioDecoder?

			if ext == "ogg" {
				decoder = OggDecoder(url: url)
			} else {
				decoder = NativeDecoder(url: url)
			}
			
			guard let validDecoder = decoder else { continue }
			if start > 0 {
				_ = validDecoder.seek(toSeconds: start)
			}
			
			decoders[track] = validDecoder
			if validDecoder.length > maxLength {
				maxLength = validDecoder.length
			}
			
			let renderer = AVSampleBufferAudioRenderer()
			renderer.volume = self.volume
			renderers[track] = renderer
			
			synchronizer.addRenderer(renderer)
			buffers[track] = startTime
		}

		isplaying = true
		return maxLength
	}
	
	func stream(_ start: Double = 0.0) async {
		guard isplaying else { return }

		while isplaying {
			if Task.isCancelled { break }
			for (key, renderer) in renderers {
				if Task.isCancelled { break }
				guard let decoder = decoders[key],
					  let currentPresentationTime = buffers[key] else { continue }
				
				while renderer.isReadyForMoreMediaData && isplaying {
					// Fetch CMSampleBuffer directly from either decoder
					guard let sampleBuffer = decoder.readNextSampleBuffer(presentationTime: currentPresentationTime) else {
						break
					}
					
					renderer.enqueue(sampleBuffer)
					
					// Advance clock by buffer duration
					let duration = CMSampleBufferGetDuration(sampleBuffer)
					let chunkDuration = duration.isValid && duration.seconds > 0
						? duration
						: CMTime(value: CMTimeValue(CMSampleBufferGetNumSamples(sampleBuffer)), timescale: CMTimeScale(decoder.format.sampleRate))
					
					buffers[key] = CMTimeAdd(currentPresentationTime, chunkDuration)
				}
				
			}
			try? await Task.sleep(nanoseconds: 20_000_000)
		}
	}
	
	func clearAll() {
		isplaying = false

		for (_, renderer) in renderers {
			renderer.stopRequestingMediaData()
			renderer.flush()
			synchronizer.removeRenderer(renderer, at: .invalid, completionHandler: nil)
		}
		
		renderers.removeAll()
		decoders.removeAll()
		buffers.removeAll()
		synchronizer = AVSampleBufferRenderSynchronizer()
		print("cleared all")
	}
	
	func setvolume(_ vol: Float) {
		self.volume = vol
	}
}


final class NoiceAudioPlayer {
	var length = 0.0
	var trackmanager = TrackManager()
	private var fadeTask: Task<Void, Never>?
	var streamTask: Task<Void, Never>?

	
	func play(trackurls: [Jukebox.Track: URL], startTime: Double = 0.0) {
		self.streamTask = Task(priority: .userInitiated) {
			self.length = await self.trackmanager.setup(trackurl: trackurls, start: startTime)
			await self.trackmanager.stream(startTime)
			await self.trackmanager.setvolume(0.5)
		}
	}
	
	func stop(){
		streamTask?.cancel()
		Task(priority: .userInitiated) {
			await trackmanager.clearAll()
		}
	}
	
	func setvolume(_ vol: Float ) {
		Task{
			await trackmanager.setvolume(vol)
		}
	}
	
	func fade(from: Float = 0, to: Float, duration: TimeInterval = 2.0, completion: (() -> Void)? = nil) {
			fadeTask?.cancel()
			
			fadeTask = Task {
				let steps = 10
				let stepDuration = duration / Double(steps)
				let stepAmount = (to - from) / Float(steps)
				
				for i in 0...steps {
					if Task.isCancelled { return }
					
					let currentVol = from + (Float(i) * stepAmount)

					await trackmanager.setvolume(currentVol)
					
					try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
				}
				
				completion?()
			}
		}
	func fadeoutpreview(duration: TimeInterval = 2.0) {
		let currentPrevol = Jukebox.shared.prevol()
		fade(from: currentPrevol, to: 0.0, duration: duration) { [weak self] in
			self?.stop()
		}
	}
}
