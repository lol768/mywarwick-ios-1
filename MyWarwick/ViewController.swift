import UIKit
import SafariServices
import WebKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController, UITabBarDelegate, WKNavigationDelegate, WKUIDelegate, MyWarwickDelegate, WebViewDelegate, WebViewDataSource {
    func setWebSignOnURLs(signIn: String, signOut: String) {}
    
    var firstRunAfterTour = false
    
    var userNotificationController: AnyObject?

    let bgColourForNonMeView = UIColor(white: 249 / 255, alpha: 1)
    
    @IBOutlet weak var webViewContainer: UIView!
    
    func ready() {
        invoker.ready()
    }
    
    internal func setAppCached(_ cached: Bool) {
        preferences.canWorkOffline = cached

        if (cached) {
            print("App cached for offline working")
        }
    }

    internal func setUnreadNotificationCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count

        let items = tabBar.items!
        items[1].badgeValue = badgeValueForInt(count)
    }

    var lastPathChange = DispatchTime.now()

    internal func setPath(_ path: String) {
        // Keep track of when the path was last changed
        let localLastPathChange = DispatchTime.now()
        self.lastPathChange = localLastPathChange

        if let selectedTabBarItem = tabBarItemForPath(path) {
            tabBar.selectedItem = selectedTabBarItem
        }

        if path == "/" || path.hasPrefix("/edit") || path.hasPrefix("/tiles") {
            webView.backgroundColor = UIColor.clear
            renderBackground()
        } else {
            // Wait for the page to have changed - avoid visible background change on tiles view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // If the path hasn't been changed since 0.5 seconds ago
                if (localLastPathChange == self.lastPathChange) {
                    self.webView.backgroundColor = self.bgColourForNonMeView
                    self.view.backgroundColor = self.bgColourForNonMeView
                }
            }
        }

        if path.hasPrefix("/settings") {
            tabBar.isHidden = true
        } else {
            tabBar.isHidden = false
        }
    }

    var currentUser: User = AnonymousUser(authoritative: false)
    
    internal func setUser(_ user: User) {
        let items = tabBar.items!

        items[1].isEnabled = user.signedIn
        items[2].isEnabled = user.signedIn

        if (user.authoritative) {
            if (user.signedIn) {
                firstRunAfterTour = false

                if (user.usercode != currentUser.usercode) {
                    currentUser = user
                    registerForPushNotifications()
                }

                if preferences.timetableToken == nil || preferences.needsTimetableTokenRefresh {
                    invoker.invokeIfAvailable(method: "registerForTimetable")
                }
            } else {
                removeDeviceTokenFromServer()

                preferences.timetableToken = nil

                Global.backgroundQueue.async {
                    let dataController = DataController()
                    dataController.load {
                        EventFetcher(dataController: dataController, preferences: self.preferences).deleteAllEvents()
                        NotificationScheduler(dataController: dataController, preferences: self.preferences).removeAllScheduledNotifications()
                    }
                }
            }
        }
    }

    internal func loadDeviceDetails() {
        invoker.loadDeviceDetails(url: webView.url)
    }
    
    internal func launchTour() {
        let viewController = storyboard!.instantiateViewController(withIdentifier: "TourViewController")
        present(viewController, animated: false, completion: nil)
    }

    func locationDidUpdate(location: CLLocation) {
        invoker.invokeNative("didUpdateLocation({coords:{latitude:\(location.coordinate.latitude),longitude:\(location.coordinate.longitude),accuracy:\(location.horizontalAccuracy)}})")
    }

    func locationDidFail(error: Error) {
        invoker.invokeNative("locationDidFail()")
    }

    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var behindStatusBarView: UIView!
    
    let preferences = MyWarwickPreferences(userDefaults: UserDefaults.standard)
    let invoker = JavaScriptInvoker()

    var webView = WKWebView()

    var unreachableViewController: UIViewController = UIViewController()

    var reachability: Reachability?

    var isOnline = false

    let processPool = WKProcessPool()

    let brandColour1 = UIColor(hue: 285.0 / 360.0, saturation: 27.0 / 100.0, brightness: 59.0 / 100.0, alpha: 1)
    let brandColour2 = UIColor(hue: 4.0 / 360.0, saturation: 55.0 / 100.0, brightness: 67.0 / 100.0, alpha: 1)
    let brandColour3 = UIColor(hue: 180.0 / 360.0, saturation: 63.0 / 100.0, brightness: 53.0 / 100.0, alpha: 1)
    let brandColour4 = UIColor(hue: 200.0 / 360.0, saturation: 65.0 / 100.0, brightness: 53.0 / 100.0, alpha: 1)
    let brandColour5 = UIColor(hue: 14.0 / 360.0, saturation: 66.0 / 100.0, brightness: 64.0 / 100.0, alpha: 1)

    func createWebView() {
        let userContentController = WKUserContentController()
        userContentController.add(MyWarwickMessageHandler(delegate: self, preferences: preferences), name: "MyWarwick")

        if let path = Bundle.main.path(forResource: "Bridge", ofType: "js"), let bridgeJS = try? String(contentsOfFile: path, encoding: .utf8) {
            let output = bridgeJS.replacingOccurrences(of: "{{APP_VERSION}}", with: Config.shortVersionString)
                    .replacingOccurrences(of: "{{APP_BUILD}}", with: Config.bundleVersion)

            userContentController.addUserScript(WKUserScript(source: output, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }


        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = Config.applicationNameForUserAgent
        configuration.preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        configuration.suppressesIncrementalRendering = true
        configuration.userContentController = userContentController
        configuration.processPool = processPool

        webView = WKWebView(frame: CGRect.zero, configuration: configuration)

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        createWebView()
        invoker.webView = webView

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidReceiveRemoteNotification"), object: nil, queue: OperationQueue.main) { _ -> Void in
            self.navigateWithinApp("/notifications")
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidReceiveTransientRemoteNotification"), object: nil, queue: OperationQueue.main) { (notification) -> Void in
            
            let title = (notification as NSNotification).userInfo?["title"] as? String ?? ""
            let body = (notification as NSNotification).userInfo?["body"] as? String ?? ""
            Helper.makeTransientNotificationAlert(title: title, body: body, viewController: self)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { _ -> Void in
            self.invoker.invoke("onApplicationDidBecomeActive()")
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidRegisterForRemoteNotifications"), object: nil, queue: OperationQueue.main) { (notification) -> Void in
            if let deviceToken = (notification as NSNotification).userInfo?["deviceToken"] as? String {
                self.preferences.deviceToken = deviceToken
                self.invoker.invoke("registerForAPNs('\(deviceToken)')")
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.accessibilitySettingChanges), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }

    func accessibilitySettingChanges() {
        self.loadWebView()
    }

    var hideStatusBarBackground: NSLayoutConstraint? = nil

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        renderBackground()
    }
    
    func renderBackground() {
        if preferences.chosenHighContrast ?? false {
            renderBackgroundColour()
        } else {
            renderBackgroundImage()
        }
    }
    
    func renderBackgroundImage() {
        let bgId = preferences.chosenBackgroundId ?? 1
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "Background"+String(bgId))?.draw(in: self.view.bounds)
        
        if let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            self.view.backgroundColor = UIColor(patternImage: image)
        } else {
            UIGraphicsEndImageContext()
            debugPrint("Image not available")
        }
    }
    
    func renderBackgroundColour() {
        let bgId = preferences.chosenBackgroundId ?? 1
        self.view.backgroundColor = getColourForBackground(bgId: bgId)
    }
    
    func updateStatusBarViewBackgroundColour() {
        let bgId = preferences.chosenBackgroundId ?? 1
        behindStatusBarView.backgroundColor = getColourForBackground(bgId: bgId)
    }
    
    private func getColourForBackground(bgId: Int) -> UIColor {
        switch bgId {
        case 2:
            return brandColour2
        case 3:
            return brandColour3
        case 4:
            return brandColour4
        case 5:
            return brandColour5
        default:
            return brandColour1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderBackground()
        
        setLayout()
        unreachableViewController = storyboard!.instantiateViewController(withIdentifier: "CannotConnect")
        loadWebView()
        
        
        if #available(iOS 10.0, *) {
            userNotificationController = UserNotificationController(viewController: self)
            UNUserNotificationCenter.current().delegate = (userNotificationController as! UNUserNotificationCenterDelegate)
        }
        
    }
    
    func setLayout() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.addSubview(webView)
        let webViewTop = NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: webViewContainer, attribute: .top, multiplier: 1, constant: 0)
        let webViewLeading = NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: webViewContainer, attribute: .leading, multiplier: 1, constant: 0)
        let webViewWidth = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: webViewContainer, attribute: .width, multiplier: 1, constant: 0)
        let webViewBottom = NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: webViewContainer, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraints([webViewTop, webViewLeading, webViewWidth, webViewBottom])
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 44, left: 0, bottom: view.layoutMargins.bottom, right: 0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        initReachability()
    }

    func initReachability() {
        if reachability != nil {
            // Prevent creating multiple Reachability instances
            return
        }

        reachability = Reachability()

        reachability?.whenUnreachable = { reachability in
            DispatchQueue.main.async {
                self.isOnline = false
                if !self.preferences.canWorkOffline && self.presentedViewController == nil {
                    self.webView.stopLoading()
                    self.present(self.unreachableViewController, animated: false, completion: nil)
                }
            }
        }

        reachability?.whenReachable = { reachability in
            DispatchQueue.main.async {
                self.isOnline = true
                if self.presentedViewController == self.unreachableViewController {
                    self.dismiss(animated: false, completion: nil)
                }

                if !self.preferences.canWorkOffline {
                    self.loadWebView()
                }
            }
        }

        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start Reachability notifier: \(error)")
        }
    }

    func loadWebView() {
        var url = Config.appURL

        if firstRunAfterTour {
            // firstRunAfterTour is unset after successful sign-in

            url = url.appendingPathComponent("/post_tour")
        } else if Global.didLaunchFromRemoteNotification {
            Global.didLaunchFromRemoteNotification = false

            url = url.appendingPathComponent("/notifications")
        }

        webView.load(URLRequest(url: url as URL))
    }

    // create our own webview controller
    func createWebViewController(url: URL, navItemTitle: String, navItemDismissTitle: String, storyboardIdentifier: String) {
        print("Creating", navItemTitle, "WebView controller for", url)

        let viewController = storyboard!.instantiateViewController(withIdentifier: storyboardIdentifier) as! WebViewController
        viewController.dataSource = self
        viewController.delegate = self
        viewController.navigationItem.title = navItemTitle
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: navItemDismissTitle, style: .plain, target: viewController, action: #selector(viewController.dismissNotifyingDelegate))
        viewController.load(url: url)

        let wrappingNavController = MWUINavigationController(rootViewController: viewController)
        wrappingNavController.navigationBar.isTranslucent = false
        present(wrappingNavController, animated: true)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            presentSafariWebView(url)
        }
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {

            if self.isOnline {
                // allow sign out
                if url.host == Config.webSignOnURL.host && url.path == "/origin/logout" {
                    decisionHandler(.allow)
                    return
                }

                // allow sign in url
                if url.host == Config.webSignOnURL.host && url.path == "/origin/hs" {
                    createWebViewController(url: url, navItemTitle: "Sign in", navItemDismissTitle: "Cancel", storyboardIdentifier: "signinVC")
                    decisionHandler(.cancel)
                    return
                }

                // allow pop over window from websignon
                if url.host == Config.webSignOnURL.host && url.path == "/origin/account/popover" {
                    decisionHandler(.allow)
                    return
                }

                if url.host == "campus.warwick.ac.uk" {
                    decisionHandler(.allow)
                    return
                }

                // allow account setting url http://warwick.ac.uk/myaccount
                if url.host == "warwick.ac.uk" && url.path == "/myaccount" {
                    createWebViewController(url: url, navItemTitle: "Account settings", navItemDismissTitle: "Back", storyboardIdentifier: "accountSettingVC")
                    decisionHandler(.cancel)
                    return
                }

                // allow photos.warwick.ac.uk
                if url.host != nil && Helper.regexMatch(for: "photos(-.+)?.warwick.ac.uk", in: url.host!) {
                    createWebViewController(url: url, navItemTitle: "Photos", navItemDismissTitle: "Back", storyboardIdentifier: "photosVC")
                    decisionHandler(.cancel)
                    return
                }
            }

            if url.host == Config.appURL.host && url.path.hasPrefix("/news/") && url.path.hasSuffix("/redirect") {
                // Open News redirector links in Safari Web View
                decisionHandler(.cancel)
                presentSafariWebView(url)
                return
            }

            if url.host == Config.appURL.host || url.host == Config.webSignOnURL.host {
                decisionHandler(.allow)
                return
            }

            if url.host != nil {
                // open all other external links in Safari Web View
                presentSafariWebView(url)
            } else {
                // handle custom URL schemes
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                } else {
                    let message: String
                    if url.scheme == "message" {
                        message = "Could not find Mail app on this device"
                    } else if url.scheme == "ms-outlook" {
                        message = "Could not find Outlook app on this device"
                    } else {
                        message = ""
                    }
                    let alert = UIAlertController(title: "App not installed", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }

        decisionHandler(.cancel)
    }

    func presentSafariWebView(_ url: URL) {
        let svc = SFSafariViewController(url: url)

        if UIDevice.current.systemVersion.hasPrefix("9.2") {
            // Workaround for a bug in iOS 9.2 - see https://forums.developer.apple.com/thread/29048#discussion-105377
            self.modalPresentationStyle = .overFullScreen

            let nvc = UINavigationController(rootViewController: svc)
            nvc.isNavigationBarHidden = true

            present(nvc, animated: true, completion: nil)
        } else {
            present(svc, animated: true, completion: nil)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web view failed to load \(error)")
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView started provisional navigation")

        invoker.notReady()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            print("Web view finished loading \(url)")
        }
    }

    func tabBarItemForPath(_ path: String) -> UITabBarItem? {
        switch path {
        case "/":
            return tabBar.items![0]
        case "/notifications":
            return tabBar.items![1]
        case "/activity":
            return tabBar.items![2]
//        case "/news": // news will be back in the future
//            return tabBar.items![3]
        case "/search":
            return tabBar.items![3]
        default:
            return nil
        }
    }

    func badgeValueForInt(_ int: Int) -> String? {
        if int <= 0 {
            return nil
        } else if int < 100 {
            return String(int)
        } else {
            return "99+"
        }
    }

    func registerForPushNotifications() {
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.sound, UIUserNotificationType.alert]
        let settings = UIUserNotificationSettings(types: notificationTypes, categories: nil)

        let application = UIApplication.shared
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }

    func removeDeviceTokenFromServer() {
        if let token = preferences.deviceToken {
            invoker.invoke("unregisterForPush('\(token)')")
        }
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        var path = "/" + item.title!.lowercased()

        if (path == "/me") {
            path = "/"
        }

        if (path == "/alerts") {
            path = "/notifications"
        }

        navigateWithinApp(path)
    }

    func navigateWithinApp(_ path: String) {
        invoker.invoke("navigate('\(path)')")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // WebViewDataSource
    func getConfig() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = Config.applicationNameForUserAgent
        configuration.suppressesIncrementalRendering = true
        configuration.processPool = processPool
        return configuration
    }

    // WebViewDelegate
    func didDismissWebView(sender: Any) {
        self.loadWebView()
    }
    
    func setBackgroundToDisplay(bgId: Int, isHighContrast: Bool) {
        preferences.chosenBackgroundId = bgId
        preferences.chosenHighContrast = isHighContrast
        renderBackground()
        updateStatusBarViewBackgroundColour()
    }

}

