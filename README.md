# Haptrix Sync

Update your App's Haptics without re-compiling your App.

This package allows you to change your Haptic file and send it to your App directly from the Haptrix App

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
    - [Syncing from Haptrix to your App](#syncing-from-haptrix-to-your-app)
    - [Playing a pattern](#playing-a-pattern)
    - [Debug Release Builds](#debug-release-builds)
- [Advanced Usage](#advanced-usage)
    - [Using a publisher](#Using-a-publisher)
- [Credits](#credits)
- [License](#license)


## Features

- [x] No need to re-build your app to test your latest Haptic 
- [x] Trigger the Haptic from your App, it will play your latest Haptic 
- [x] Faster Development time

## Requirements

- iOS 13.0+
- Xcode 11.0

## Installation

### Swift Package Manager
The Swift Package Manager is a dependency manager integrated with the Swift build system. To learn how to use the Swift Package Manager for your project, please read the [official documentation](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md).  
To add HaptrixSync as a dependency, you have to add it to the `dependencies` of your `Package.swift` file and refer to that dependency in your `target`.

```swift
// swift-tools-version:5.0
import PackageDescription
let package = Package(
    name: "<Your Product Name>",
    dependencies: [
    .package(url: "https://github.com/nthState/HaptrixSync.git", "main")
    ],
    targets: [
        .target(
    name: "<Your Target Name>",
    dependencies: ["HaptrixSync"]),
    ]
)
```

### Update your Info.plist

You will need to add the following lines to your `Info.plist`, this tells your app that it can connect to the Haptrix macOS App.
The `NSLocalNetworkUsageDescription` is required key to ask the user for permission to connec to the Haptrix App.

```xml
<key>NSBonjourServices</key>
<array>
  <string>_haptrix._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>Network usage is required for macOS/iOS communication</string>
```

### Import the framework

Add the following line to your code where you play your pattern

```swift
import HaptrixSync
```

## Usage

### Syncing from Haptrix to your App

Ensure your App and Haptrix macOS App are running & connected.

Make a change to your *.AHAP file in Haptrix macOS and press `Run on device` - the *.AHAP file is sent to your App, so that the 
next time you play your Haptic, the very latest Haptic will play.

*Question*: How does `HaptrixSync` know what file to update? We use the `fileName` of the *.AHAP file.

### Playing a Pattern

Playing a pattern is simple, the method signature is almost identical to `CHHapticEngine` `playPattern` method.
Supply the `syncUpdates: true` and the App will connect to the Haptrix macOS App.

```swift

let engine = CHHapticEngine()

engine.playPattern(from: url, syncUpdates: true)
```

*Note*: By default, the `playPattern` method will connect on the first play of any pattern, however, if you wish to prepare
you need to call:

```swift

let engine = CHHapticEngine()

engine.prepareSyncing()
```


### Debug Release Builds

This package is designed so that it helps you develop your App, to that end, I suggest you don't ship this package in your `release` builds.

You can try something like:

```swift
#if DEBUG
engine.playPattern(from: url, syncUpdates: true) // HaptrixSync Player
#else
engine.playPattern(from: url) // Standard engine player
#endif
```

A better solution would be to remove the dependency on `release` builds.


## Advanced Usage

### Using a publisher

If you want to use a `combine` `publisher` to know when your Haptic file has finished playing, I've got you covered.

```swift

let engine = CHHapticEngine()

var cancellables = Set<AnyCancellable>()

engine
  .playPattern(from: url, syncUpdates: true)
  .sink { result in
    switch result {
    case .failure(let error):
      os_log("Error: %@", log: .haptics, type: .error, "\(error)")
    case .finished:
      os_log("Finished", log: .haptics, type: .debug)
    }
  } receiveValue: { value in
    os_log("Pattern played: %@", log: .haptics, type: .debug, named)
  }
  .store(in: &cancellables)

```

## Credits

HaptrixSync is written and maintained by [Chris Davis](http://www.nthState.com).  
Twitter: [@nthState](https://twitter.com/nthState).


## License

HaptrixSync is released under the MIT License.  
See [LICENSE](https://github.com/nthState/HaptrixSync/blob/master/LICENSE) for details.
