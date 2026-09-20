//
//  AVA.swift
//  noice
//
//  Created by fernando zamora on 9/13/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//

import AVFoundation
import CoreMedia

extension AVAudioPCMBuffer {

	func toCMSampleBuffer(presentationTime: CMTime) -> CMSampleBuffer? {

		guard frameLength > 0 else { return nil }

		let sampleRate = format.sampleRate
		let channelCount = Int(format.channelCount)
		let frameCount = Int(frameLength)

		// Create an interleaved Float32 format for Core Media.
		guard let interleavedFormat = AVAudioFormat(
			commonFormat: .pcmFormatFloat32,
			sampleRate: sampleRate,
			channels: format.channelCount,
			interleaved: true
		) else {
			return nil
		}

		let formatDescription = interleavedFormat.formatDescription

		// Interleaved Float32: LRLRLRLR...
		let totalSampleCount = frameCount * channelCount
		let totalByteSize = totalSampleCount * MemoryLayout<Float32>.size

		guard let floatData = floatChannelData else {
			return nil
		}

		let interleavedData = UnsafeMutablePointer<Float32>.allocate(capacity: totalSampleCount)
		defer {
			interleavedData.deallocate()
		}

		for frame in 0..<frameCount {
			for channel in 0..<channelCount {
				interleavedData[(frame * channelCount) + channel] = floatData[channel][frame]
			}
		}

		var blockBuffer: CMBlockBuffer?

		var status = CMBlockBufferCreateWithMemoryBlock(
			allocator: kCFAllocatorDefault,
			memoryBlock: nil,
			blockLength: totalByteSize,
			blockAllocator: kCFAllocatorDefault,
			customBlockSource: nil,
			offsetToData: 0,
			dataLength: totalByteSize,
			flags: 0,
			blockBufferOut: &blockBuffer
		)

		guard status == noErr, let block = blockBuffer else {
			return nil
		}

		status = CMBlockBufferReplaceDataBytes(
			with: interleavedData,
			blockBuffer: block,
			offsetIntoDestination: 0,
			dataLength: totalByteSize
		)

		guard status == noErr else {
			return nil
		}

		let duration = CMTime(
			value: CMTimeValue(frameCount),
			timescale: CMTimeScale(sampleRate)
		)

		var timingInfo = CMSampleTimingInfo(
			duration: duration,
			presentationTimeStamp: presentationTime,
			decodeTimeStamp: .invalid
		)

		var sampleBuffer: CMSampleBuffer?

		status = CMSampleBufferCreate(
			allocator: kCFAllocatorDefault,
			dataBuffer: block,
			dataReady: true,
			makeDataReadyCallback: nil,
			refcon: nil,
			formatDescription: formatDescription,
			sampleCount: frameCount,
			sampleTimingEntryCount: 1,
			sampleTimingArray: &timingInfo,
			sampleSizeEntryCount: 0,
			sampleSizeArray: nil,
			sampleBufferOut: &sampleBuffer
		)

		guard status == noErr else {
			return nil
		}

		return sampleBuffer
	}
}

extension CMSampleBuffer {
	/// Converts a linear PCM CMSampleBuffer into an AVAudioPCMBuffer
	func toAVAudioPCMBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
		guard let blockBuffer = CMSampleBufferGetDataBuffer(self) else { return nil }
		let numSamples = CMSampleBufferGetNumSamples(self)
		guard numSamples > 0,
			  let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
			return nil
		}
		
		pcmBuffer.frameLength = AVAudioFrameCount(numSamples)
		
		let status = CMBlockBufferCopyDataBytes(
			blockBuffer,
			atOffset: 0,
			dataLength: CMBlockBufferGetDataLength(blockBuffer),
			destination: pcmBuffer.mutableAudioBufferList.pointee.mBuffers.mData!
		)
		
		return status == noErr ? pcmBuffer : nil
	}
}
