import UIKit
import SafariServices
import WebKit

class ViewController: UIViewController, UITabBarDelegate, WKNavigationDelegate, WKUIDelegate, MyWarwickDelegate, WebViewDelegate, WebViewDataSource {

    func ready() {
        invoker.ready()
    }

    func setWebSignOnURLs(signIn: String, signOut: String) {

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

    internal func setPath(_ path: String) {
        if let selectedTabBarItem = tabBarItemForPath(path) {
            tabBar.selectedItem = selectedTabBarItem
        }
    }

    internal func setUser(_ user: User) {
        let items = tabBar.items!

        items[1].isEnabled = user.signedIn
        items[2].isEnabled = user.signedIn

        if (user.authoritative) {
            if (user.signedIn) {
                registerForPushNotifications()
            } else {
                removeDeviceTokenFromServer()
            }
        }
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

    let brandColour = UIColor(hue: 285.0 / 360.0, saturation: 27.0 / 100.0, brightness: 59.0 / 100.0, alpha: 1)

    func createWebView() {
        let userContentController = WKUserContentController()
        userContentController.add(MyWarwickMessageHandler(delegate: self), name: "MyWarwick")

        if let path = Bundle.main.path(forResource: "Bridge", ofType: "js"), let bridgeJS = try? String(contentsOfFile: path, encoding: .utf8) {
            userContentController.addUserScript(WKUserScript(source: bridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }


        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = Config.applicationNameForUserAgent
        configuration.preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        configuration.suppressesIncrementalRendering = true
        configuration.userContentController = userContentController
        configuration.processPool = processPool

        webView = WKWebView(frame: CGRect.zero, configuration: configuration)

        webView.navigationDelegate = self
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        createWebView()
        invoker.webView = webView

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidReceiveRemoteNotification"), object: nil, queue: OperationQueue.main) { _ -> Void in
            self.navigateWithinApp("/notifications")
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
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if toInterfaceOrientation != .portrait && UIDevice.current.userInterfaceIdiom == .phone {
            // Status bar is hidden on iPhone when in landscape
            view.addConstraint(hideStatusBarBackground!)
        } else {
            view.removeConstraint(hideStatusBarBackground!)
        }
    }

    var hideStatusBarBackground: NSLayoutConstraint? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        behindStatusBarView.backgroundColor = brandColour

        // Layout constraint used to collapse the status bar background view
        // when the status bar is hidden
        hideStatusBarBackground = NSLayoutConstraint(item: behindStatusBarView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)

        unreachableViewController = storyboard!.instantiateViewController(withIdentifier: "CannotConnect")

        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        view.sendSubview(toBack: webView)

        view.addConstraints([
                NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: behindStatusBarView, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 44, left: 0, bottom: 48, right: 0)

        loadWebView()
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

        if Global.didLaunchFromRemoteNotification {
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

        let wrappingNavController = UINavigationController(rootViewController: viewController)
        wrappingNavController.navigationBar.isTranslucent = false
        present(wrappingNavController, animated: true)
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

                // allow account setting url http://warwick.ac.uk/myaccount
                if url.host == "warwick.ac.uk" && url.path == "/myaccount" {
                    createWebViewController(url: url, navItemTitle: "Account settings", navItemDismissTitle: "Back", storyboardIdentifier: "accountSettingVC")
                    decisionHandler(.cancel)
                    return
                }

                // allow photos.warwick.ac.uk
                if Helper.regexMatch(for: "photos(-.+)?.warwick.ac.uk", in: url.host!) {
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

            // open all other external links in Safari Web View
            presentSafariWebView(url)
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
        case "/news":
            return tabBar.items![3]
        case "/search":
            return tabBar.items![4]
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
}

