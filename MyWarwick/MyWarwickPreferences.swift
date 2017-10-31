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
    
    var chosenBackgroundId: Int? {
        get {
            return userDefaults.integer(forKey: "ChosenBackgroundId")
        }
        
        set(bgId) {
            userDefaults.set(bgId, forKey: "ChosenBackgroundId")
            userDefaults.synchronize()
        }
    }
    
    var chosenHighContrast: Bool? {
        get {
            return userDefaults.bool(forKey: "ChosenHighContrast")
        }
        
        set(isHighContrast) {
            userDefaults.set(isHighContrast, forKey: "ChosenHighContrast")
            userDefaults.synchronize()
        }
    }

    var timetableToken: String? {
        get {
            return userDefaults.string(forKey: "TimetableToken")
        }

        set(token) {
            userDefaults.set(token, forKey: "TimetableToken")
            userDefaults.synchronize()

            if token != nil {
                Global.backgroundQueue.async {
                    let dataController = DataController()
                    dataController.load {
                        EventFetcher(dataController: dataController, preferences: self).updateEvents() { (success) in
                        }
                    }
                }
            }
        }
    }

    var timetableNotificationsEnabled: Bool {
        get {
            return !userDefaults.bool(forKey: "TimetableNotificationsDisabled")
        }

        set(enabled) {
            if (enabled != timetableNotificationsEnabled) {
                userDefaults.set(!enabled, forKey: "TimetableNotificationsDisabled")
                userDefaults.synchronize()

                Global.backgroundQueue.async {
                    let dataController = DataController()
                    dataController.load {
                        NotificationScheduler(dataController: dataController, preferences: self).rescheduleAllNotifications()
                    }
                }
            }
        }
    }

    var timetableNotificationTiming: Int {
        get {
            if let timing = userDefaults.object(forKey: "TimetableNotificationTiming") as! Int? {
                return timing
            }

            return 15
        }

        set(timing) {
            if (timing != timetableNotificationTiming) {
                userDefaults.set(timing, forKey: "TimetableNotificationTiming")
                userDefaults.synchronize()

                Global.backgroundQueue.async {
                    let dataController = DataController()
                    dataController.load {
                        NotificationScheduler(dataController: dataController, preferences: self).rescheduleAllNotifications()
                    }
                }
            }
        }
    }
}
