//
//  nOggPlayer.swift
//  noice
//
//  Created by fernando on 9/13/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//

import Foundation

/// High level player for TrackJockey
final class NoiceAudioPlayer {
	var length = 0.0
	var dj = TrackJockey()
	private var fadeTask: Task<Void, Never>?
	var streamTask: Task<Void, Never>?
	
	func play(trackurls: [Jukebox.Track: URL], startTime: Double = 0.0) {
		self.streamTask = Task(priority: .userInitiated) {
			self.length = await self.dj.setup(trackurl: trackurls, start: startTime)
			await self.dj.stream()
		}
	}
	
	func stop(){
		streamTask?.cancel()
		setvolume(0) // not really necessary?
		Task(priority: .userInitiated) {
			await dj.clearAll()
		}
	}
	
	func setvolume(_ vol: Float ) {
		Task{
			await dj.setvolume(vol)
		}
	}
	
	func setvolume(_ vol: Float , track: Jukebox.Track) {
		Task{
			await dj.setvolume(vol, track: track)
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

					await dj.setvolume(currentVol)
					
					try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
				}
				
				completion?()
			}
		}
	
	func fadetrack(track: Jukebox.Track, from: Float = 0, to: Float, duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
			fadeTask?.cancel()
			
			fadeTask = Task {
				let steps = 10
				let stepDuration = duration / Double(steps)
				let stepAmount = (to - from) / Float(steps)
				
				for i in 0...steps {
					if Task.isCancelled { return }
					
					let currentVol = from + (Float(i) * stepAmount)

					await dj.setvolume(currentVol, track: track)
					
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
			await dj.observe(length)
		}
	}
}
