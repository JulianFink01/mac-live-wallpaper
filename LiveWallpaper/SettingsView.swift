import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Start at Login", isOn: Binding(
                    get: { settings.wantsStartAtLogin },
                    set: { settings.setStartAtLogin($0) }
                ))
                .disabled(!settings.isLoginItemAvailable)

                Spacer()

                Button {
                    SMAppService.openSystemSettingsLoginItems()
                } label: {
                    Label("Login Items", systemImage: "gear")
                }
            }

            Text("LiveWallpaper can start automatically after the user logs in. A normal third-party macOS app cannot replace or animate the real pre-login macOS Login Screen wallpaper using public APIs.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(settings.loginItemStatusText)
                .font(.footnote)
                .foregroundStyle(settings.isLoginItemAvailable ? Color.secondary : Color.orange)
                .fixedSize(horizontal: false, vertical: true)

            if !settings.isLoginItemAvailable {
                Text("Current app path: \(settings.appBundlePath)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            if settings.usesLaunchAgentFallback {
                Text("Fallback plist: \(LaunchAgentLoginItem.plistURL.path)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            if let loginItemError = settings.loginItemError {
                Text(loginItemError)
                    .font(.footnote)
                    .foregroundStyle(settings.isLoginItemAvailable ? Color.red : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let libraryError = VideoLibraryStore.shared.errorMessage {
                Text(libraryError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}
