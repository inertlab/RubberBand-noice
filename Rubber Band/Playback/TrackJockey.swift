//
//  TrackJockey.swift
//  noice
//
//  Created by fernando on 9/25/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//


import AVFoundation
import LibVorbis

actor TrackJockey {
	private(set) var volume: Float = 1.0 {
		didSet {
			for (track, rend) in renderers {
				if track == .crowd {continue}
				rend.volume = volume
			}
		}
	}
	
	nonisolated let synchronizer = AVSampleBufferRenderSynchronizer()

	private var decoders: [Jukebox.Track: AudioDecoder] = [:]
	private var renderers: [Jukebox.Track: AVSampleBufferAudioRenderer] = [:]
	private(set) var isplaying = false
	private var watchers = [Any]()
	private var pausedtime = 0.0

//	MARK: Setup
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
			if track == .crowd {renderer.volume = 0}
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

					guard let sampleBuffer = decoder.readNextSampleBuffer() else {
						break
					}
					
					renderer.enqueue(sampleBuffer)
//					print("UPDATED BUFFER:", (decoder as! OggDecoder).cmtime.seconds)
				}
			}
			try? await Task.sleep(nanoseconds: 200_000_000)
		}
	}

//MARK: Cleanup
	func clearAll() {
		isplaying = false
		
		synchronizer.setRate(0, time: .zero)
		lookaway()
		for (_, renderer) in renderers {
			renderer.stopRequestingMediaData()
			renderer.flush()
			synchronizer.removeRenderer(renderer, at: .invalid, completionHandler: nil)
		}
		watchers.removeAll()
		renderers.removeAll()
		decoders.removeAll()
		
//		synchronizer = AVSampleBufferRenderSynchronizer()
	}
	
//MARK: Fucntions
	func resume() async{
		isplaying = true // not necessary but it's nice to stop the streaming while loop
		for ren in renderers {
			ren.value.flush()
		}
		for decoder in decoders {
			decoder.value.seek(toSeconds: pausedtime - 2)
		}
		synchronizer.rate = 1
		await stream()
	}
	
	func pause() {
		isplaying = false
		pausedtime = synchronizer.currentTime().seconds
		synchronizer.setRate(0, time: CMTime(seconds: pausedtime - 2, preferredTimescale: 44100))
	}
	
	func setvolume(_ vol: Float) {
		self.volume = vol
	}
	
	func setvolume(_ vol: Float, track: Jukebox.Track) {
		if let renderer = renderers[track] {
			renderer.volume = vol
		}
	}
	
	func observe(_ length: Double)  {

		let observer = synchronizer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 60), queue: .main) { _ in
			stagemc.track.scorekeeper.time.text = dateformat.string(from: length - self.synchronizer.currentTime().seconds)
		}
		
		let seconds = synchronizer.addBoundaryTimeObserver(forTimes: [length + 0.5] as [NSValue], queue: .main){
			stagemc.machine.enter(ScoreState.self)
		}
		let times = stagemc.vocalcoach.gettimes() as [NSValue]
		let lyrics = synchronizer.addBoundaryTimeObserver(forTimes: times, queue: .main) {
			stagemc.vocalcoach.tracklyrics(songtime: self.synchronizer.currentTime().seconds)
			}

		watchers = [observer, seconds, lyrics]
	}
	
	func lookaway(){
		for watcher in watchers {
			synchronizer.removeTimeObserver(watcher)
		}
	}
}
