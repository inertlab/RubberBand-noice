//
//  extensions.swift
//  extensions
//
//  Created by Fernando on 11/14/21.
//  Copyright © 2021 Artecolote. All rights reserved.
//

import Foundation


extension Int32 {
	private static var format: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .decimal
		return nf
	}()
	
	var dec: String {
		return Int32.format.string(from: NSNumber(value: self)) ?? ""
	}
}

extension Int16 {
	private static var format: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .decimal
		return nf
	}()
	
	var dec: String {
		return Int16.format.string(from: NSNumber(value: self)) ?? ""
	}
}
