//
//  MIDIEncodingDetector.swift
//  noice
//
//  Created by fernando on 10/1/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//


import Foundation

final class MIDIEncodingDetector {
	
	/// Pre-created CoreFoundation reference for ISO Latin 10 (Romanian)
	static let isoLatin10: String.Encoding = {
		let cfEnc = CFStringEncoding(CFStringEncodings.isoLatin10.rawValue)
		let nsEnc = CFStringConvertEncodingToNSStringEncoding(cfEnc)
		return String.Encoding(rawValue: nsEnc)
	}()

	/// Detects a single unified encoding across a track's string payloads
	static func detectBestEncoding(for payloads: [[UInt8]]) -> String.Encoding {
		let allBytes = Array(payloads.joined())
		if allBytes.isEmpty { return .utf8 }
		
		// 1. Pure ASCII Check
		if allBytes.allSatisfy({ $0 < 0x80 }) {
			return .ascii
		}
		
		// 2. Strict UTF-8 Check
		if isValidUTF8(allBytes) {
			return .utf8
		}
		
		// 3. Fallback Hierarchy for Legacy 8-bit Encodings
		// Default to CP1252 for Western/Spanish/English, but allow ISO Latin 10/2 for Eastern Europe
		let candidateEncodings: [String.Encoding] = [
			.windowsCP1252, // Standard Western European (Cubase / Logic / Reaper default)
			isoLatin10,     // ISO-8859-16 (Romanian)
			.isoLatin2,     // ISO-8859-2 (Central European)
			.isoLatin1      // Standard Latin-1
		]
		
		for encoding in candidateEncodings {
			if let _ = String(bytes: allBytes, encoding: encoding) {
				return encoding
			}
		}
		
		return .ascii
	}
	
	private static func isValidUTF8(_ bytes: [UInt8]) -> Bool {
		var index = 0
		while index < bytes.count {
			let byte = bytes[index]
			if byte < 0x80 {
				index += 1
			} else if (byte & 0xE0) == 0xC0 {
				if index + 1 >= bytes.count || (bytes[index + 1] & 0xC0) != 0x80 { return false }
				index += 2
			} else if (byte & 0xF0) == 0xE0 {
				if index + 2 >= bytes.count || (bytes[index + 1] & 0xC0) != 0x80 || (bytes[index + 2] & 0xC0) != 0x80 { return false }
				index += 3
			} else if (byte & 0xF8) == 0xF0 {
				if index + 3 >= bytes.count || (bytes[index + 1] & 0xC0) != 0x80 || (bytes[index + 2] & 0xC0) != 0x80 || (bytes[index + 3] & 0xC0) != 0x80 { return false }
				index += 4
			} else {
				return false
			}
		}
		return true
	}
}
