import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let settings: SettingsStore
    private let library: VideoLibraryStore
    private let openLibrary: () -> Void
    private let randomWallpaper: () -> Void
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: SettingsStore,
        library: VideoLibraryStore,
        openLibrary: @escaping () -> Void,
        randomWallpaper: @escaping () -> Void
    ) {
        self.settings = settings
        self.library = library
        self.openLibrary = openLibrary
        self.randomWallpaper = randomWallpaper
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(named: "MenuBarIcon") ?? NSImage(systemSymbolName: "play.rectangle.on.rectangle", accessibilityDescription: "LiveWallpaper")
            button.image?.isTemplate = true
            button.imagePosition = .imageOnly
            button.title = ""
            button.toolTip = "LiveWallpaper"
        }

        rebuildMenu()

        settings.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildMenu()
                }
            }
            .store(in: &cancellables)

        library.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildMenu()
                }
            }
            .store(in: &cancellables)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Open Library", action: #selector(openLibraryAction), keyEquivalent: "o"))
        menu.addItem(.separator())

        let pauseTitle = settings.isPaused ? "Resume Wallpaper" : "Pause Wallpaper"
        menu.addItem(NSMenuItem(title: pauseTitle, action: #selector(togglePauseAction), keyEquivalent: "p"))

        let randomItem = NSMenuItem(title: "Random Wallpaper", action: #selector(randomWallpaperAction), keyEquivalent: "r")
        randomItem.isEnabled = !library.videos.isEmpty
        menu.addItem(randomItem)

        let loginTitle = settings.wantsStartAtLogin ? "Disable Start at Login" : "Start at Login"
        let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleStartAtLoginAction), keyEquivalent: "")
        loginItem.state = settings.wantsStartAtLogin ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func openLibraryAction() {
        openLibrary()
    }

    @objc private func togglePauseAction() {
        settings.setPaused(!settings.isPaused)
        rebuildMenu()
    }

    @objc private func randomWallpaperAction() {
        randomWallpaper()
    }

    @objc private func toggleStartAtLoginAction() {
        settings.setStartAtLogin(!settings.wantsStartAtLogin)
        rebuildMenu()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
