//
//  ChartIcons.swift
//  RubberBand
//
//  Created by Fernando Zamora on 8/2/18.
//  Copyright © 2018 Artecolote. All rights reserved.
//

import Foundation
import SpriteKit


let iconAtlas = SKTextureAtlas(named: "icon")


/// remaps song icon to preferred icon on file
let IconFile = [
//	"blank"		: "blank"		,
//	"ass"		: "ass"			,
//	"bh"		: "bh"			,
//	"bhdlc"		: "bhdlc"		,
//	"ctpk"		: "ctpk"		,
//	"ctpk2"		: "ctpk2"		,
	"gdrb"		: "gdrbalt"		, // changed - too faint
	"gdrbalt"	: "gdrbalt"		, // changed - too faint
	"gdrbdlc"	: "gdrbalt"		, // changed - too faint
	"gdrbold"	: "gdrbalt"		, // changed - too faint
//	"gh1"		: "gh1"			,
//	"gh2"		: "gh2"			,
//	"gh2dlc"	: "gh2dlc"		,
//	"gh3"		: "gh3"			,
//	"gh3dlc"	: "gh3dlc"		,
//	"gh5"		: "gh5"			,
//	"gh5dlc"	: "gh5dlc"		,
//	"gh80s"		: "gh80s"		,
//	"gh80sdlc"	: "gh80sdlc"	,
//	"gha"		: "gha"			,
//	"ghm"		: "ghm"			,
//	"ghmdlc"	: "ghmdlc"		,
//	"ghot"		: "ghot"		,
//	"ghsh"		: "ghsh"		,
//	"ghvh"		: "ghvh"		,
//	"ghwor"		: "ghwor"		,
//	"ghwordlc"	: "ghwordlc"	,
//	"ghwt"		: "ghwt"		,
//	"ghwtdlc"	: "ghwtdlc"		,
//	"lrb"		: "lrb"			,
	"lrbdlc"	: "lrb"			, // changed - too low ress
//	"mtpk"		: "mtpk"		,
//	"ph1"		: "ph1"			,
	"ph2"		: "ph1"			, // changed - ugly
	"ph3"		: "ph1"			, // changed - ugly
	"ph4"		: "ph1"			, // changed - ugly
//	"phm"		: "phm"			,
//	"rb1"		: "rb1"			,
//	"rb1dlc"	: "rb1dlc"		,
//	"rb2"		: "rb2"			,
//	"rb2dlc"	: "rb2dlc"		,
//	"rb3"		: "rb3"			,
//	"rb3dlc"	: "rb3dlc"		,
//	"rbacdc"	: "rbacdc"		,
//	"rbb"		: "rbb"			,
//	"rbbdlc"	: "rbbdlc"		,
//	"rbdlc"		: "rbdlc"		,
//	"rbn"		: "rbn"			,
	"rbtb"		: "tbrb"		, // changed - repetitive
	"rbtbdlc"	: "tbrbdlc"		, // changed - repetitive
//	"rbtpk"		: "rbtpk"		,
//	"tbrb"		: "tbrb"		,
//	"tbrbdlc"	: "tbrbdlc"		,
	"rb4"		: "rb3"			  // changed - don't have an icon yet
]
