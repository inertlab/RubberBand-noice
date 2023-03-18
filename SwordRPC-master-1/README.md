# SwordRPC - A Discord Rich Presence Library for Swift

[![Swift Version](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat-square)](https://swift.org) 

## Changes in this fork
- Added a `disconnect()` function
  - There seems to be an issue with re`connect()`ing after a `disconnect()`
  - Workaround is to just create a new `SwordRPC` object
- Changed timestamps to use integer seconds
  - The Discord API expects timestamps to be integer, and will behave strangely if passed a non-integer value
- Presence update requests to the API are made when the presence is changed, instead of every 15 seconds
  - Presence updates on startup are now much faster
  - The Discord API handles the 15 second update frequency limit for us
- Updated some deprecated functions for compatibility with Swift 5
- Fixed a crash that would occur upon connecting to the Discord API
- The `.details`  and `.state` properties of `RichPresence` are now `String?` instead of `String`.
  - This is because the JSON Encoder generates  `"details": ""` for an empty `String`, which appears to break the Discord API. Using an optional `String`, the key-value pair is not encoded at all.
- `connect()` returns a `Bool` indicating whether or not the connection was successful

## Requirements
1. macOS, Linux
2. Swift 5.0

## Adding SwordRPC
This fork uses Swift Package Manager.  

In your Xcode project, go to Swift Packages in your Project Settings and add the package with URL `https://github.com/PKBeam/SwordRPC.git`.
