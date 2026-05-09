import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore.shared
    private let library = VideoLibraryStore.shared
    private lazy var wallpaperController = WallpaperController(settings: settings, library: library)
    private var menuBarController: MenuBarController?
    private var cancellables = Set<AnyCancellable>()
    private var libraryWindow: NSWindow?
    private var pausedForSystemSleep = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController(
            settings: settings,
            library: library,
            openLibrary: { [weak self] in self?.presentLibraryWindow() },
            randomWallpaper: { [weak self] in self?.selectRandomWallpaper() }
        )

        bindState()
        registerNotifications()
        wallpaperController.start()

        if library.videos.isEmpty {
            presentLibraryWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        wallpaperController.closeAllWindows()
    }

    private func bindState() {
        settings.$currentVideoID
            .dropFirst()
            .sink { [weak self] _ in
                self?.wallpaperController.applyCurrentVideo()
            }
            .store(in: &cancellables)

        settings.$aspectMode
            .dropFirst()
            .sink { [weak self] _ in
                self?.wallpaperController.updateAspectMode()
            }
            .store(in: &cancellables)

        settings.$isPaused
            .dropFirst()
            .sink { [weak self] isPaused in
                if isPaused {
                    self?.wallpaperController.pausePlayback()
                } else {
                    self?.wallpaperController.resumePlayback()
                }
            }
            .store(in: &cancellables)

        library.$videos
            .dropFirst()
            .sink { [weak self] videos in
                guard let self else { return }
                if let currentVideoID = self.settings.currentVideoID,
                   !videos.contains(where: { $0.id == currentVideoID }) {
                    self.settings.setCurrentVideo(videos.first?.id)
                }
            }
            .store(in: &cancellables)
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    private func presentLibraryWindow() {
        if let libraryWindow {
            libraryWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = LibraryView()
        let hostingView = NSHostingView(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LiveWallpaper"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        libraryWindow = window
    }

    private func selectRandomWallpaper() {
        guard let random = library.randomVideo(excluding: settings.currentVideoID) else { return }
        settings.setCurrentVideo(random.id)
        settings.setPaused(false)
    }

    @objc private func screenConfigurationChanged() {
        wallpaperController.handleScreenConfigurationChanged()
    }

    @objc private func workspaceWillSleep() {
        pausedForSystemSleep = !settings.isPaused
        wallpaperController.pausePlayback()
    }

    @objc private func workspaceDidWake() {
        guard pausedForSystemSleep else { return }
        pausedForSystemSleep = false
        wallpaperController.resumePlayback()
    }
}
