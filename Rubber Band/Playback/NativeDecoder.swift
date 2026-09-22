//
//  NativeDecoder.swift
//  noice
//
//  Created by fernando on 9/18/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//


import AVFoundation

protocol AudioDecoder {
	var length: Double { get }
	var format: AVAudioFormat { get }
	func readNextSampleBuffer() -> CMSampleBuffer?
	func seek(toSeconds seconds: Double) -> Bool
}

final class NativeDecoder: AudioDecoder {
	
	private var assetReader: AVAssetReader?
	private var trackOutput: AVAssetReaderTrackOutput?
	private let url: URL
	
	let length: Double
	let format: AVAudioFormat
	
	init?(url: URL) {

		self.url = url

		let asset = AVURLAsset(url: url)

		self.length = asset.duration.seconds

		guard let track = asset.tracks(withMediaType: .audio).first else { return nil }

		guard let formatDescription = track.formatDescriptions.first else {
			return nil
		}

		let audioFormatDescription = formatDescription as! CMAudioFormatDescription

		guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription)?.pointee else {
			return nil
		}

		let sampleRate = asbd.mSampleRate
		let channels = AVAudioChannelCount(asbd.mChannelsPerFrame)

		guard let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: true) else {
			return nil
		}

		self.format = fmt

		guard self.configureReader(startTime: 0.0) else { return nil }

	}
	
	private func configureReader(startTime: Double) -> Bool {
		let asset = AVURLAsset(url: url)
		guard let reader = try? AVAssetReader(asset: asset),
			  let track = asset.tracks(withMediaType: .audio).first else {
			return false
		}
		
		// Output standard packed float PCM directly as CMSampleBuffers
		let outputSettings: [String: Any] = [
			AVFormatIDKey: kAudioFormatLinearPCM,
			AVSampleRateKey: format.sampleRate,
			AVNumberOfChannelsKey: 2,
			AVLinearPCMBitDepthKey: 32,
			AVLinearPCMIsFloatKey: true,
			AVLinearPCMIsBigEndianKey: false,
			AVLinearPCMIsNonInterleaved: false // Interleaved packed float
		]
		
		
		let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
		output.alwaysCopiesSampleData = false
		
		if reader.canAdd(output) {
			reader.add(output)
		} else {
			return false
		}
		
		if startTime > 0 {
			let startCMTime = CMTime(seconds: startTime, preferredTimescale: CMTimeScale(format.sampleRate))
			reader.timeRange = CMTimeRange(start: startCMTime, duration: .positiveInfinity)
		}
		
		guard reader.startReading() else { return false }
		self.assetReader = reader
		self.trackOutput = output
		return true
	}
	
	/// Returns CMSampleBuffer directly from AVAssetReader hardware pipeline
<<<<<<< HEAD
	func readNextSampleBuffer(presentationTime: CMTime) -> CMSampleBuffer? {
=======
	func readNextSampleBuffer() -> CMSampleBuffer? {
>>>>>>> vocal_change

		guard let output = trackOutput,
			  let sampleBuffer = output.copyNextSampleBuffer() else {
			return nil
		}

		return sampleBuffer
	}
	
	
	
	func seek(toSeconds seconds: Double) -> Bool {
		assetReader?.cancelReading()
		return configureReader(startTime: seconds)
	}
}
// MARK: - Format-Safe Buffer Conversions

extension CMSampleBuffer {
	/// Safely converts CMSampleBuffer directly into AVAudioPCMBuffer without raw memory layout bugs
	func toAVAudioPCMBuffer() -> AVAudioPCMBuffer? {
		guard let formatDescription = CMSampleBufferGetFormatDescription(self),
			  let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee else {
			return nil
		}
		
		let numSamples = CMSampleBufferGetNumSamples(self)
		let format = AVAudioFormat(cmAudioFormatDescription: formatDescription)
		guard numSamples > 0,
			  let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
			return nil
		}
		
		pcmBuffer.frameLength = AVAudioFrameCount(numSamples)
		
		guard let blockBuffer = CMSampleBufferGetDataBuffer(self) else { return nil }
		let status = CMBlockBufferCopyDataBytes(
			blockBuffer,
			atOffset: 0,
			dataLength: CMBlockBufferGetDataLength(blockBuffer),
			destination: pcmBuffer.mutableAudioBufferList.pointee.mBuffers.mData!
		)
		
		return status == noErr ? pcmBuffer : nil
	}
}
