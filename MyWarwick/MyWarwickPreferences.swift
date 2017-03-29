import Foundation

class MyWarwickPreferences {

    var userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var canWorkOffline: Bool {
        get {
            return userDefaults.bool(forKey: "AppCached")
        }

        set(cached) {
            userDefaults.set(cached, forKey: "AppCached")
            userDefaults.synchronize()
        }
    }

    var deviceToken: String? {
        get {
            return userDefaults.string(forKey: "DeviceToken")
        }

        set(token) {
            userDefaults.set(token, forKey: "DeviceToken")
            userDefaults.synchronize()
        }
    }

}
