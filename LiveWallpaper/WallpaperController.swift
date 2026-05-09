import AppKit
import AVFoundation

@MainActor
final class WallpaperController {
    private struct WallpaperEntry {
        let screenID: UInt32
        let window: WallpaperWindow
        let playerView: WallpaperPlayerView
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
    }

    private let settings: SettingsStore
    private let library: VideoLibraryStore
    private var entries: [UInt32: WallpaperEntry] = [:]

    init(settings: SettingsStore, library: VideoLibraryStore) {
        self.settings = settings
        self.library = library
    }

    func start() {
        applyCurrentVideo()
    }

    func applyCurrentVideo() {
        guard let video = library.video(with: settings.currentVideoID),
              FileManager.default.fileExists(atPath: video.fileURL.path) else {
            closeAllWindows()
            return
        }

        rebuildWindowsIfNeeded()
        configurePlayers(with: video.fileURL)
    }

    func handleScreenConfigurationChanged() {
        guard library.video(with: settings.currentVideoID) != nil else {
            closeAllWindows()
            return
        }

        rebuildWindowsIfNeeded()
        applyCurrentVideo()
    }

    func updateAspectMode() {
        entries.values.forEach { $0.playerView.setAspectMode(settings.aspectMode) }
    }

    func pausePlayback() {
        entries.values.forEach { $0.player?.pause() }
    }

    func resumePlayback() {
        guard !settings.isPaused else { return }

        if entries.isEmpty {
            applyCurrentVideo()
        }

        entries.values.forEach { $0.player?.play() }
    }

    func closeAllWindows() {
        entries.values.forEach { entry in
            entry.player?.pause()
            entry.playerView.setPlayer(nil)
            entry.window.orderOut(nil)
            entry.window.close()
        }
        entries.removeAll()
    }

    private func rebuildWindowsIfNeeded() {
        let screens = NSScreen.screens
        let currentScreenIDs = Set(screens.map(screenID(for:)))

        for (id, entry) in entries where !currentScreenIDs.contains(id) {
            entry.player?.pause()
            entry.playerView.setPlayer(nil)
            entry.window.close()
            entries[id] = nil
        }

        for screen in screens {
            let id = screenID(for: screen)
            if let existing = entries[id] {
                existing.window.setFrame(screen.frame, display: true)
                existing.playerView.frame = NSRect(origin: .zero, size: screen.frame.size)
                continue
            }

            let window = WallpaperWindow(screen: screen)
            let playerView = WallpaperPlayerView(frame: NSRect(origin: .zero, size: screen.frame.size))
            playerView.setAspectMode(settings.aspectMode)
            window.contentView = playerView
            window.orderFrontRegardless()

            entries[id] = WallpaperEntry(
                screenID: id,
                window: window,
                playerView: playerView,
                player: nil,
                looper: nil
            )
        }
    }

    private func configurePlayers(with videoURL: URL) {
        for id in Array(entries.keys) {
            guard var entry = entries[id] else { continue }

            let item = AVPlayerItem(url: videoURL)
            let player = AVQueuePlayer()
            player.isMuted = true
            player.actionAtItemEnd = .none

            let looper = AVPlayerLooper(player: player, templateItem: item)
            entry.playerView.setPlayer(player)
            entry.playerView.setAspectMode(settings.aspectMode)
            entry.player = player
            entry.looper = looper
            entries[id] = entry

            if !settings.isPaused {
                player.play()
            }
        }
    }

    private func screenID(for screen: NSScreen) -> UInt32 {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? NSNumber)?.uint32Value ?? UInt32(abs(screen.hash))
    }
}
