import Combine
import Foundation
import ServiceManagement

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var currentVideoID: UUID? {
        didSet {
            if let currentVideoID {
                defaults.set(currentVideoID.uuidString, forKey: Keys.currentVideoID)
            } else {
                defaults.removeObject(forKey: Keys.currentVideoID)
            }
        }
    }

    @Published var isPaused: Bool {
        didSet {
            defaults.set(isPaused, forKey: Keys.isPaused)
        }
    }

    @Published var aspectMode: AspectMode {
        didSet {
            defaults.set(aspectMode.rawValue, forKey: Keys.aspectMode)
        }
    }

    @Published var wantsStartAtLogin: Bool {
        didSet {
            defaults.set(wantsStartAtLogin, forKey: Keys.wantsStartAtLogin)
        }
    }

    @Published var loginItemError: String?

    private let defaults: UserDefaults

    private enum Keys {
        static let currentVideoID = "currentVideoID"
        static let isPaused = "isPaused"
        static let aspectMode = "aspectMode"
        static let wantsStartAtLogin = "wantsStartAtLogin"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let idString = defaults.string(forKey: Keys.currentVideoID) {
            currentVideoID = UUID(uuidString: idString)
        } else {
            currentVideoID = nil
        }

        isPaused = defaults.object(forKey: Keys.isPaused) as? Bool ?? false

        if let rawAspectMode = defaults.string(forKey: Keys.aspectMode),
           let storedAspectMode = AspectMode(rawValue: rawAspectMode) {
            aspectMode = storedAspectMode
        } else {
            aspectMode = .fill
        }

        let storedLoginPreference = defaults.object(forKey: Keys.wantsStartAtLogin) as? Bool
        wantsStartAtLogin = storedLoginPreference ?? (SMAppService.mainApp.status == .enabled)
    }

    func setCurrentVideo(_ id: UUID?) {
        currentVideoID = id
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    func setAspectMode(_ mode: AspectMode) {
        aspectMode = mode
    }

    func setStartAtLogin(_ enabled: Bool) {
        loginItemError = nil

        do {
            if enabled {
                switch SMAppService.mainApp.status {
                case .enabled:
                    wantsStartAtLogin = true
                case .requiresApproval:
                    wantsStartAtLogin = true
                    SMAppService.openSystemSettingsLoginItems()
                case .notRegistered:
                    try SMAppService.mainApp.register()
                    wantsStartAtLogin = true
                case .notFound:
                    wantsStartAtLogin = false
                    loginItemError = "Login item registration is unavailable for this app bundle."
                @unknown default:
                    try SMAppService.mainApp.register()
                    wantsStartAtLogin = true
                }
            } else {
                if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                    try SMAppService.mainApp.unregister()
                }
                wantsStartAtLogin = false
            }
        } catch {
            loginItemError = error.localizedDescription
            wantsStartAtLogin = SMAppService.mainApp.status == .enabled
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    func refreshStartAtLoginStatus() {
        wantsStartAtLogin = SMAppService.mainApp.status == .enabled || (wantsStartAtLogin && SMAppService.mainApp.status == .requiresApproval)
    }
}
