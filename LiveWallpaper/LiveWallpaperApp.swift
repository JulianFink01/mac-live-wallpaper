import SwiftUI

@main
struct LiveWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .frame(width: 520)
                .padding(20)
        }
    }
}
