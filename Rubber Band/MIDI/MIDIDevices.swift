//
//  MIDIManager.swift
//  RubberBand
//
//  Created by Fernando Zamora on 2/24/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import MIKMIDI
import CoreMIDI

var midiClient	: MIDIClientRef 	= 0
var inPort		: MIDIPortRef	 	= 0
var src			: MIDIEndpointRef 	= MIDIGetSource(0)

let drumgothit		 	= NSNotification.Name("drumhit")
let drumCenter 			= NotificationCenter()
let midiobject			= MIDIObjectRef()

func getDisplayName(_ obj: MIDIObjectRef) -> String
{
	var param: Unmanaged<CFString>?
	var name: String = "Error"
	
	let err: OSStatus = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
	if err == OSStatus(noErr)
	{
		name =  param!.takeRetainedValue() as String
	}
	
	print("thisi s it ", name)
	return name
}

func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
					readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
{
	let packetList:MIDIPacketList = pktList.pointee
//	let srcRef:MIDIEndpointRef = srcConnRefCon!.load(as: MIDIEndpointRef.self)
	
//	let packet:MIDIPacket = packetList.packet
	
//	for _ in 0...packetList.numPackets
//	{
//		print(packet.data.1)
		
//		if packet.data.0 == 144 && packet.data.2 != 0{
		if packetList.packet.data.0 == 153 && packetList.packet.data.2 != 0 {
//			print(packetList)
//			print(packetList.packet)
			if let note = roland[packetList.packet.data.1] {
				drumCenter.post(name: drumgothit, object: note, userInfo: nil)
			}
		}
		
//		packet = MIDIPacketNext(&packet).pointee
//	}
}

/// sets up a midi device listenter to register hits into the main thread. currently only works for game, needs to be setup for song selection
func setupMidiDevice () {
	MIDIClientCreate("MidiTestClient" as CFString, nil, nil, &midiClient)
	MIDIInputPortCreate(midiClient, "MidiTest_InPort" as CFString, MyMIDIReadProc, nil, &inPort)
	MIDIPortConnectSource(inPort, src, &src)
	
	drumCenter.addObserver(forName: drumgothit, object: nil, queue: OperationQueue.main){
		(note) in
//		switchboard.checkinput(note.object as! Button)
		stagemc.currentact.handleevent(note.object as! Button)
	}
}

//reference function DO NOT DELETE!!!
//func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
//					readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
//{
//	let packetList:MIDIPacketList = pktList.pointee
//	let srcRef:MIDIEndpointRef = srcConnRefCon!.load(as: MIDIEndpointRef.self)
//
//	print("MIDI Received From Source: \(getDisplayName(srcRef))")
//
//	var packet:MIDIPacket = packetList.packet
//	for _ in 1...packetList.numPackets
//	{
//		let bytes = Mirror(reflecting: packet.data).children
//		var dumpStr = ""
//
//		// bytes mirror contains all the zero values in the ridiulous packet data tuple
//		// so use the packet length to iterate.
//		var i = packet.length
//		print(packet.data)
//		for (_, attr) in bytes.enumerated()
//		{
//			dumpStr += String(format:"$%02X ", attr.value as! UInt8)
//			i -= 1
//			if (i <= 0)
//			{
//				break
//			}
//		}
//
//		print(dumpStr)
//		packet = MIDIPacketNext(&packet).pointee
//	}
//}
