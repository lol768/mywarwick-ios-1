import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var eventTimetableUpdateTimer: DispatchSourceTimer?
    
    func startEventTimetableUpdateTimer() {
        let timeTableEventUpdateQ = DispatchQueue(label: "timeTableEventUpdateQ")
        eventTimetableUpdateTimer?.cancel()
        eventTimetableUpdateTimer = DispatchSource.makeTimerSource(queue: timeTableEventUpdateQ)
        eventTimetableUpdateTimer?.scheduleRepeating(deadline: .now(), interval: .seconds(60), leeway: .seconds(1))
        eventTimetableUpdateTimer?.setEventHandler { [weak self] in
            self?.updateTimetableEvents()
        }
        eventTimetableUpdateTimer?.resume()
    }
    
    func stopEventTimetableUpdateTimer() {
        eventTimetableUpdateTimer?.cancel()
        eventTimetableUpdateTimer = nil
    }
    
    func isIPhoneX() -> Bool {
        if #available(iOS 11.0, *) {
            if UIApplication.shared.keyWindow?.safeAreaInsets != UIEdgeInsets.zero {
                return true
            }
        }
        return false
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })

        NotificationCenter.default.post(name: Notification.Name(rawValue: "DidRegisterForRemoteNotifications"), object: self, userInfo: [
                "deviceToken": token
        ])
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        if isIPhoneX() {
            return UIInterfaceOrientationMask.portrait
        }
        return UIInterfaceOrientationMask.all
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor(red: 91 / 255, green: 48 / 255, blue: 105 / 255, alpha: 1 / 4)
        appearance.currentPageIndicatorTintColor = UIColor(red: 91 / 255, green: 48 / 255, blue: 105 / 255, alpha: 1)
        
        if launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] != nil {
            Global.didLaunchFromRemoteNotification = true
        }

        UIApplication.shared.setMinimumBackgroundFetchInterval(12 * 60 * 60)
        return true
    }

    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if (application.applicationState == .inactive || application.applicationState == .background) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "DidReceiveRemoteNotification"), object: self, userInfo: nil)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // stop periodical timetable update
        stopEventTimetableUpdateTimer()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        startEventTimetableUpdateTimer()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let dataController = DataController()
        dataController.load {
            EventFetcher(dataController: dataController, preferences: MyWarwickPreferences(userDefaults: UserDefaults.standard)).updateEvents() { (success) in
                completionHandler(success ? .newData : .failed)
            }
        }

    }
    
    func updateTimetableEvents() {
        Global.backgroundQueue.async {
            let dataController = DataController()
            dataController.load {
                EventFetcher(dataController: dataController, preferences: MyWarwickPreferences(userDefaults: UserDefaults.standard)).updateEvents() { (success) in
                }
            }
        }
    }
}

