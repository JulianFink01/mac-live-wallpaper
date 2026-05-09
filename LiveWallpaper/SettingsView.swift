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

            if let loginItemError = settings.loginItemError {
                Text(loginItemError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let libraryError = VideoLibraryStore.shared.errorMessage {
                Text(libraryError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}
