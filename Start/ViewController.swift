//
//  ViewController.swift
//  Start
//
//  Created by Alec Cursley on 06/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import UIKit
import SafariServices
import WebKit

class ViewController: UIViewController, UITabBarDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var behindStatusBarView: UIView!
    
    var webView = WKWebView()
    
    var unreachableViewController: UIViewController = UIViewController()
    
    var canWorkOffline = false
    var hasRegisteredForNotifications = false
    var webViewHasLoaded = false
    
    var unregisteredDeviceToken: String?
    
    var reachability: Reachability?
    
    var applicationOrigins = Set<String>()
    
    let startBrandColour = UIColor(hue: 285.0/360.0, saturation: 27.0/100.0, brightness: 59.0/100.0, alpha: 1)
    
    func createWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = Config.applicationNameForUserAgent
        configuration.preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        configuration.suppressesIncrementalRendering = true
        
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        webView.navigationDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        createWebView()
        
        canWorkOffline = UserDefaults.standard.bool(forKey: "AppCached")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidReceiveRemoteNotification"), object: nil, queue: OperationQueue.main) { _ -> Void in
            if self.webViewHasLoaded {
                self.navigateWithinStart("/notifications")
            } else {
                self.webView.load(URLRequest(url: Config.startURL.appendingPathComponent("/notifications")))
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { _ -> Void in
            if self.webViewHasLoaded {
                self.webView.evaluateJavaScript("Start.appToForeground()", completionHandler: nil)
            }
            
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidRegisterForRemoteNotifications"), object: nil, queue: OperationQueue.main) { (notification) -> Void in
            if let deviceToken = (notification as NSNotification).userInfo?["deviceToken"] as? String {
                self.unregisteredDeviceToken = deviceToken
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
        
        behindStatusBarView.backgroundColor = startBrandColour
        
        // Layout constraint used to collapse the status bar background view
        // when the status bar is hidden
        hideStatusBarBackground = NSLayoutConstraint(item: behindStatusBarView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        
        unreachableViewController = storyboard!.instantiateViewController(withIdentifier: "CannotConnect")
        
        setTabBarHidden(true)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        view.sendSubview(toBack: webView)
        
        view.addConstraints([
            NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: behindStatusBarView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
            ])
        
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
                if !self.canWorkOffline && self.presentedViewController == nil {
                    self.webView.stopLoading()
                    self.present(self.unreachableViewController, animated: false, completion: nil)
                }
            }
        }
        
        reachability?.whenReachable = { reachability in
            DispatchQueue.main.async {
                if self.presentedViewController == self.unreachableViewController {
                    self.dismiss(animated: false, completion: nil)
                }
                
                if !self.canWorkOffline {
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
        var url = Config.startURL
        
        if Global.didLaunchFromRemoteNotification {
            Global.didLaunchFromRemoteNotification = false
            
            url = Config.startURL.appendingPathComponent("/notifications")
        }
        
        webView.load(URLRequest(url: url as URL))
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.scheme == "start" {
                updateAppState()
            } else {
                let origin = "\(url.scheme!)://\(url.host!)"
                if url.host == Config.startURL.host || applicationOrigins.contains(origin) {
                    decisionHandler(.allow)
                    return
                }
                
                presentWebView(url)
            }
        }
        
        decisionHandler(.cancel)
    }
    
    func updateAppState() {
        webView.evaluateJavaScript("JSON.stringify(Start.APP)") { (json, error) in
            let jsonObject = json as AnyObject?
            
            if let data = jsonObject?.data(using: String.Encoding.utf8.rawValue) {
                if let state = try? JSONSerialization.jsonObject(with: data, options: []) {
                    self.appStateDidChange(state as! Dictionary<String, AnyObject>)
                }
            }
        }
    }
    
    func presentWebView(_ url: URL) {
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
    
    func setTabBarHidden(_ hidden: Bool) {
        if hidden {
            tabBar.isHidden = true
            webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            tabBar.isHidden = false
            webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 44, left: 0, bottom: 48, right: 0)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web view failed to load \(error)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            print("Web view finished loading \(url)")
            
            if url.host == Config.startURL.host {
                webViewHasLoaded = true
                
                setTabBarHidden(false)
            } else {
                setTabBarHidden(true)
            }
        }
    }
    
    func appStateDidChange(_ state: Dictionary<String, AnyObject>) {
        let items = tabBar.items!
        
        if let hidden = state["tabBarHidden"] as? Bool {
            setTabBarHidden(hidden)
        }
        
        if let origins = state["applicationOrigins"] as? Array<String> {
            applicationOrigins = Set(origins)
        }
        
        if let currentPath = state["currentPath"] as? String {
            if let selectedTabBarItem = tabBarItemForPath(currentPath) {
                tabBar.selectedItem = selectedTabBarItem
            }
        }
        
        if let unreadNotificationCount = state["unreadNotificationCount"] as? Int {
            UIApplication.shared.applicationIconBadgeNumber = unreadNotificationCount
            items[1].badgeValue = badgeValueForInt(unreadNotificationCount)
        }
        
        if !canWorkOffline && state["isAppCached"] as? Bool == true {
            UserDefaults.standard.set(true, forKey: "AppCached")
            UserDefaults.standard.synchronize()
            canWorkOffline = true
            print("App cached for offline working")
        }
        
        if state["isUserLoggedIn"] as? Bool == true {
            registerForNotifications()
            
            items[1].isEnabled = true
            items[2].isEnabled = true
        } else {
            items[1].isEnabled = false
            items[2].isEnabled = false
        }
        
        if let deviceToken = self.unregisteredDeviceToken {
            print("Registering for APNs with device token \(deviceToken)")
            
            webView.evaluateJavaScript("Start.registerForAPNs(\"\(deviceToken)\")") { (o, e) in
                if (e != nil) {
                    print("Error registering for APNs: \(e)")
                } else {
                    self.unregisteredDeviceToken = nil
                }
            }
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
    
    func registerForNotifications() {
        if hasRegisteredForNotifications {
            return
        }
        
        hasRegisteredForNotifications = true
        
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.sound, UIUserNotificationType.alert]
        let settings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        
        let application = UIApplication.shared
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        var path = "/" + item.title!.lowercased()
        
        if (path == "/me") {
            path = "/"
        }
        
        navigateWithinStart(path)
    }
    
    func navigateWithinStart(_ path: String) {
        webView.evaluateJavaScript("Start.navigate('\(path)')", completionHandler: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
}

