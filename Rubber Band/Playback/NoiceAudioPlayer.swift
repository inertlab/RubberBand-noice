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
	
	nonisolated let synchronizer = AVSampleBufferRenderSynchronizer()

	private var decoders: [Jukebox.Track: AudioDecoder] = [:]
	private var renderers: [Jukebox.Track: AVSampleBufferAudioRenderer] = [:]
	private(set) var isplaying = false
	private var watchers = [Any]()
	
	func setup(trackurl: [Jukebox.Track: URL], start: Double = 0) -> Double {

		var maxLength = 0.0
		let startTime = CMTime(seconds: start, preferredTimescale: 44100)
		
		
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
			synchronizer.setRate(1.0, time: startTime)
		}

		isplaying = true
		return maxLength
	}
	
	/// starts streaming loop
	/// - Parameter start: doesn't do anything
	func stream(_ start: Double = 0.0) async {
		guard isplaying else { return }

		while isplaying {
			if Task.isCancelled { break }
			for (key, renderer) in renderers {
				if Task.isCancelled { break }
				guard let decoder = decoders[key] else { continue }

				while renderer.isReadyForMoreMediaData && isplaying {
<<<<<<< HEAD
					guard let currentPresentationTime = buffers[key] else { break }

					guard let sampleBuffer = decoder.readNextSampleBuffer(
						presentationTime: currentPresentationTime
					) else {
=======

					guard let sampleBuffer = decoder.readNextSampleBuffer() else {
>>>>>>> vocal_change
						break
					}
					
					renderer.enqueue(sampleBuffer)
<<<<<<< HEAD
					
					// Advance clock by buffer duration
					let duration = CMSampleBufferGetDuration(sampleBuffer)
					let chunkDuration = duration.isValid && duration.seconds > 0
						? duration
						: CMTime(value: CMTimeValue(CMSampleBufferGetNumSamples(sampleBuffer)), timescale: CMTimeScale(decoder.format.sampleRate))
//					print("STREAM:", CMSampleBufferGetDuration(sampleBuffer).seconds)
					
					buffers[key] = CMTimeAdd(currentPresentationTime, chunkDuration)
//					print("UPDATED BUFFER:", key, buffers[key]?.seconds ?? -1)
=======
//					print("UPDATED BUFFER:", (decoder as! OggDecoder).cmtime.seconds)
>>>>>>> vocal_change
				}
				
			}
			try? await Task.sleep(nanoseconds: 20_000_000)
		}
	}
	
	func clearAll() {
		isplaying = false
		
<<<<<<< HEAD
=======
		synchronizer.setRate(0, time: .zero)
		lookaway()
>>>>>>> vocal_change
		for (_, renderer) in renderers {
			renderer.stopRequestingMediaData()
			renderer.flush()
			synchronizer.removeRenderer(renderer, at: .invalid, completionHandler: nil)
		}
		watchers.removeAll()
		renderers.removeAll()
		decoders.removeAll()
<<<<<<< HEAD
		buffers.removeAll()
//		synchronizer.setRate(1, time: .zero)
		synchronizer = AVSampleBufferRenderSynchronizer()
		print("cleared all")
=======
		
//		synchronizer = AVSampleBufferRenderSynchronizer()
>>>>>>> vocal_change
	}
	
	func setvolume(_ vol: Float) {
		self.volume = vol
	}
	
<<<<<<< HEAD
=======
	func observe(_ length: Double)  {

		let observer = synchronizer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 60), queue: .main) { _ in
			stagemc.track.scorekeeper.time.text = dateformat.string(from: length - self.synchronizer.currentTime().seconds)
		}
		
		let seconds = synchronizer.addBoundaryTimeObserver(forTimes: [length + 1] as [NSValue], queue: .main){
			stagemc.machine.enter(ScoreState.self)
		}
		let times = stagemc.vocalcoach.gettimes() as [NSValue]
		let lyrics = synchronizer.addBoundaryTimeObserver(forTimes: times, queue: .main) {
			stagemc.vocalcoach.tracklyrics(songtime: self.synchronizer.currentTime().seconds)
			}

		watchers = [observer, seconds, lyrics]
		
//		print("FIRED FROM:", vocalwatch)
	}
	
	func lookaway(){
		for watcher in watchers {
			synchronizer.removeTimeObserver(watcher)
		}
	}
>>>>>>> vocal_change
}


final class NoiceAudioPlayer {
	var length = 0.0
	var trackmanager = TrackManager()
	private var fadeTask: Task<Void, Never>?
	var streamTask: Task<Void, Never>?
	var observers = [NSObject]()
	
	func play(trackurls: [Jukebox.Track: URL], startTime: Double = 0.0) {
		self.streamTask = Task(priority: .userInitiated) {
			self.length = await self.trackmanager.setup(trackurl: trackurls, start: startTime)
<<<<<<< HEAD
			await self.trackmanager.stream(startTime)
			await self.trackmanager.setvolume(1)
=======
			await self.trackmanager.stream()
>>>>>>> vocal_change
		}
	}
	
	func stop(){
		streamTask?.cancel()
		setvolume(0) // not really necessary?
		Task(priority: .userInitiated) {
			await trackmanager.clearAll()
		}
	}
	
	func setvolume(_ vol: Float ) {
		Task{
			await trackmanager.setvolume(vol)
		}
	}
	
	func fade(from: Float = 0, to: Float, duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
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
	
	func observe() {
		Task{
			await trackmanager.observe(length)
		}
	}
}
