# LiveWallpaper

LiveWallpaper is a native macOS menu-bar app that plays a local video as a desktop live wallpaper after the user has logged in.

The app is intentionally built with public Apple APIs only:

- Swift and SwiftUI for the app and library UI
- AppKit for the desktop wallpaper windows
- AVFoundation for playback, looping and thumbnails
- ServiceManagement / `SMAppService.mainApp` for Start at Login
- macOS 13.0 or newer

## What Works in v0.1

- Import `.mp4`, `.mov` and `.m4v` files through an `NSOpenPanel`
- Copy imported videos into `~/Library/Application Support/LiveWallpaper/Videos/`
- Store the video library in `~/Library/Application Support/LiveWallpaper/library.json`
- Generate thumbnails in `~/Library/Application Support/LiveWallpaper/Thumbnails/`
- Set the selected video as the current live wallpaper
- Play the video in a loop using `AVQueuePlayer` and `AVPlayerLooper`
- Create one borderless `NSWindow` per `NSScreen`
- Ignore mouse events so desktop clicks are not blocked by the wallpaper window
- Show the wallpaper window on all Spaces
- Pause and resume playback
- Pause on system sleep and resume after wake when the user had not paused manually
- Persist current video, pause state, aspect mode and Start at Login preference
- Menu-bar controls for Open Library, Pause/Resume, Random Wallpaper, Start at Login and Quit
- Bundled app icon and visible menu-bar item

## Important macOS Limitations

### Login Screen

A normal third-party macOS app cannot cleanly animate or replace the real macOS Login Screen wallpaper before the user logs in. LiveWallpaper implements automatic launch after user login with `SMAppService.mainApp`; it does not try to run before login.

### Desktop Window Level

macOS does not expose a perfect public API for "replace the Finder desktop background but stay below desktop icons". LiveWallpaper uses a public window-level compromise:

```swift
let desktopLevel = CGWindowLevelForKey(.desktopWindow)
level = NSWindow.Level(rawValue: Int(desktopLevel + 1))
```

The window is above the static desktop background and below normal app windows. Depending on macOS/Finder behavior, desktop icon layering can vary. The app avoids private APIs on purpose.

## System Requirements

- macOS 13 Ventura or newer
- Xcode 15 or newer recommended
- Local video files in `.mp4`, `.mov` or `.m4v` format

## Build in Xcode

1. Open `LiveWallpaper.xcodeproj`.
2. Select the `LiveWallpaper` scheme.
3. Choose `My Mac` as the run destination.
4. Build and run.

The app is configured as an `LSUIElement` menu-bar app, so it appears in the menu bar rather than the Dock. On first launch, if the library is empty, the Library window opens automatically.

For a durable local build that you can keep using, see [LOCAL_BUILD.md](LOCAL_BUILD.md).

## Build from Terminal

```sh
xcodebuild -project LiveWallpaper.xcodeproj -scheme LiveWallpaper -configuration Debug build
```

For a local Release app with generated icons and ad-hoc signing:

```sh
chmod +x Scripts/build-local.sh
Scripts/build-local.sh
```

The resulting app is written to `build/Release/LiveWallpaper.app`. Move it to `/Applications` before enabling Start at Login so macOS stores a stable Login Item path.

## App Data Locations

LiveWallpaper stores user data outside the app bundle:

```text
~/Library/Application Support/LiveWallpaper/
├── Videos/
├── Thumbnails/
└── library.json
```

Settings such as the current video ID, pause state, aspect mode and Start at Login preference are stored in `UserDefaults`.

## App Icon

The icon assets are generated deterministically by:

```sh
swift -module-cache-path ./build/SwiftModuleCache Tools/generate_app_icon.swift
```

Xcode compiles `LiveWallpaper/Assets.xcassets` into `AppIcon.icns` and `Assets.car`.

## Architecture

```text
LiveWallpaperApp.swift       SwiftUI app entry point
AppDelegate.swift            App lifecycle, sleep/wake, screens, menu wiring
MenuBarController.swift      NSStatusItem menu
WallpaperController.swift    Per-screen wallpaper windows and playback
WallpaperWindow.swift        Borderless non-interactive desktop-level window
WallpaperPlayerView.swift    NSView backed by AVPlayerLayer
VideoLibraryStore.swift      Import, JSON persistence, thumbnail generation
WallpaperVideo.swift         Codable video metadata model
SettingsStore.swift          UserDefaults and SMAppService state
LibraryView.swift            SwiftUI video library UI
SettingsView.swift           SwiftUI settings UI
AspectMode.swift             Fill/Fit playback mode
```

`WallpaperController` already models wallpaper output per screen, even though v0.1 intentionally uses the same selected video on every monitor. This keeps the code ready for later per-monitor assignments.

## Distribution Notes

For public distribution without Gatekeeper friction, sign the app with a Developer ID Application certificate and notarize it with Apple.

Without an Apple Developer account, you can build and run locally with ad-hoc or local signing, but other users will see Gatekeeper warnings when opening the app.

This project is not structured for Mac App Store distribution. It does not add sandbox-specific architecture or App Store purchase/update flows.

## Known v0.1 Tradeoffs

- Same video is used on all monitors.
- No battery-aware pausing yet.
- No fullscreen-app detection yet.
- No custom app icon yet.
- Start at Login may require user approval in System Settings, depending on macOS state and signing.
- The desktop-icon layering behavior depends on public macOS window-level behavior and may not be perfect on every OS version.

## Suggested Next Steps

- Add per-monitor video selection.
- Add battery and low-power-mode pause policies.
- Add detection for fullscreen foreground apps.
- Add drag-and-drop importing.
- Add a proper app icon and signed release workflow.
- Add lightweight UI tests around import and settings persistence.
