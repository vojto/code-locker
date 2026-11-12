import Foundation
import ServiceManagement

/*
 * Makes the app start when you log in to your Mac. Used once by CodeLockerApp.
 * The app has to be running to lock codes away again when the schedule closes.
 * Only asks once, so turning it off in System Settings > Login Items sticks.
 */

enum LoginItem {
    static func registerOnce() {
        guard !UserDefaults.standard.bool(forKey: DefaultsKey.hasRegisteredLoginItem) else { return }

        try? SMAppService.mainApp.register()
        UserDefaults.standard.set(true, forKey: DefaultsKey.hasRegisteredLoginItem)
    }
}
