//
//  iniCleanser.swift
//  noice
//
//  Created by fernando on 9/15/26.
//  Copyright © 2026 Artecolote. All rights reserved.
//

import Foundation


extension String {
	/// Loads song metadata, auto-detects legacy Windows-1252/8-bit encodings,
	/// and silently overwrites the file on disk with clean UTF-8.
	/// - Parameter url: file URL
	/// - Returns: returns String UTF-8 encoded
	static func loadcleanini(at url: URL) -> String? {

		guard let data = try? Data(contentsOf: url) else {
			print("errror readin :", url)
			return nil
		}
		
		// 1. If it's already valid UTF-8 (or pure ASCII), return it as-is.
		// No disk write required.
		if let text = String(data: data, encoding: .utf8) {
			return text
		}
		
		// 2. If UTF-8 failed, it's a legacy 8-bit/Windows file containing high-byte characters.
		// Decode as Windows-1252...
		if let cleansedText = String(data: data, encoding: .windowsCP1252) {
			// Overwrite the file on disk as clean UTF-8 asynchronously
			DispatchQueue.global(qos: .utility).async {
				do {
					try cleansedText.write(to: url, atomically: true, encoding: .utf8)
				} catch {
					print("Failed to auto-heal text file at \(url.path): \(error)")
				}
			}
			return cleansedText
		}
		
		// 3. Fail-safe for other legacy 8-bit encodings (e.g. ISO-8859-1)
		if let cleansedText = String(data: data, encoding: .isoLatin1) {
			DispatchQueue.global(qos: .utility).async {
				try? cleansedText.write(to: url, atomically: true, encoding: .utf8)
			}
			return cleansedText
		}
		
		return nil
	}
}
