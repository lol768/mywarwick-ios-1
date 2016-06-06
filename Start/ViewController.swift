//
//  ViewController.swift
//  Start
//
//  Created by Alec Cursley on 06/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UITabBarDelegate, UIWebViewDelegate {
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var behindStatusBarView: UIView!
    
    var webView = UIWebView()
    
    var unreachableViewController: UIViewController = UIViewController()
    
    var canWorkOffline = false
    var hasRegisteredForNotifications = false
    var webViewHasLoaded = false
    
    var unregisteredDeviceToken: String?
    
    var reachability: Reachability?
    
    let startBrandColour = UIColor(hue: 285.0/360.0, saturation: 27.0/100.0, brightness: 59.0/100.0, alpha: 1)
    
    func createWebView() {
        webView = UIWebView(frame: CGRectZero)
        
        if let defaultUserAgent = evaluateJavascript("navigator.userAgent") {
            NSUserDefaults.standardUserDefaults().registerDefaults([
                "UserAgent": "\(defaultUserAgent) \(Config.applicationNameForUserAgent)"
                ])
            
            // Now re-create the WebView to allow the change to take effect
            webView = UIWebView(frame: CGRectZero)
        }
        
        webView.delegate = self
        webView.suppressesIncrementalRendering = true
        webView.dataDetectorTypes = .None
        webView.scrollView.bounces = false
    }
    
    func evaluateJavascript(string: String) -> String? {
        return webView.stringByEvaluatingJavaScriptFromString(string)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        unarchiveCookies()
        createWebView()
        
        canWorkOffline = NSUserDefaults.standardUserDefaults().boolForKey("AppCached")
        
        NSNotificationCenter.defaultCenter().addObserverForName("DidReceiveRemoteNotification", object: nil, queue: NSOperationQueue.mainQueue()) { _ -> Void in
            if self.webViewHasLoaded {
                self.navigateWithinStart("/notifications")
            } else {
                self.webView.loadRequest(NSURLRequest(URL: Config.startURL.URLByAppendingPathComponent("/notifications")))
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ -> Void in
            if self.webViewHasLoaded {
                self.evaluateJavascript("Start.appToForeground()")
            }
            
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("DidRegisterForRemoteNotifications", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let deviceToken = notification.userInfo?["deviceToken"] as? String {
                self.unregisteredDeviceToken = deviceToken
            }
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if toInterfaceOrientation != .Portrait && UIDevice.currentDevice().userInterfaceIdiom == .Phone {
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
        hideStatusBarBackground = NSLayoutConstraint(item: behindStatusBarView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 0)
        
        unreachableViewController = storyboard!.instantiateViewControllerWithIdentifier("CannotConnect")
        
        setTabBarHidden(true)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        view.sendSubviewToBack(webView)
        
        view.addConstraints([
            NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: behindStatusBarView, attribute: .Bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
            ])
        
        loadWebView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        initReachability()
    }
    
    func initReachability() {
        if reachability != nil {
            // Prevent creating multiple Reachability instances
            return
        }
        
        reachability = try? Reachability.reachabilityForInternetConnection()
        
        reachability?.whenUnreachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                if !self.canWorkOffline && self.presentedViewController == nil {
                    self.webView.stopLoading()
                    self.presentViewController(self.unreachableViewController, animated: false, completion: nil)
                }
            }
        }
        
        reachability?.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                if self.presentedViewController == self.unreachableViewController {
                    self.dismissViewControllerAnimated(false, completion: nil)
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
            
            url = Config.startURL.URLByAppendingPathComponent("/notifications")
        }
        
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL {
            if url.host == Config.startURL.host || url.host == Config.ssoURL.host {
                return true
            }
        
            if url.scheme == "start" {
                updateAppState()
            } else {
                presentWebView(url)
            }
        }
        
        return false
    }
    
    func updateAppState() {
        if let json = evaluateJavascript("JSON.stringify(Start.APP)") {
            if let data = json.dataUsingEncoding(NSUTF8StringEncoding) {
                if let state = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
                    appStateDidChange(state as! Dictionary<String, AnyObject>)
                }
            }
        }
    }
    
    func presentWebView(url: NSURL) {
        let svc = SFSafariViewController(URL: url)
        
        if UIDevice.currentDevice().systemVersion.hasPrefix("9.2") {
            // Workaround for a bug in iOS 9.2 - see https://forums.developer.apple.com/thread/29048#discussion-105377
            self.modalPresentationStyle = .OverFullScreen
            
            let nvc = UINavigationController(rootViewController: svc)
            nvc.navigationBarHidden = true
            
            presentViewController(nvc, animated: true, completion: nil)
        } else {
            presentViewController(svc, animated: true, completion: nil)
        }
    }
    
    func setTabBarHidden(hidden: Bool) {
        if hidden {
            tabBar.hidden = true
            webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            tabBar.hidden = false
            webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 44, left: 0, bottom: 48, right: 0)
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if let url = webView.request?.URL {
            if url.host == Config.startURL.host {
                webViewHasLoaded = true
                
                setTabBarHidden(false)
            } else {
                setTabBarHidden(true)
            }
        }
        
        archiveCookies()
    }
    
    func appStateDidChange(state: Dictionary<String, AnyObject>) {
        let items = tabBar.items!
        
        setTabBarHidden(state["tabBarHidden"] as! Bool)
        
        if let selectedTabBarItem = tabBarItemForPath(state["currentPath"] as! String) {
            tabBar.selectedItem = selectedTabBarItem
        }
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = state["unreadNotificationCount"] as! Int
        
        items[1].badgeValue = badgeValueForInt(state["unreadNotificationCount"] as! Int)
        
        if !canWorkOffline && state["isAppCached"] as? Bool == true {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "AppCached")
            NSUserDefaults.standardUserDefaults().synchronize()
            canWorkOffline = true
            print("App cached for offline working")
        }
        
        if state["isUserLoggedIn"] as! Bool == true {
            registerForNotifications()
            
            items[1].enabled = true
            items[2].enabled = true
        } else {
            items[1].enabled = false
            items[2].enabled = false
        }
        
        if let deviceToken = self.unregisteredDeviceToken {
            print("Registering for APNs with device token \(deviceToken)")
            
            if self.evaluateJavascript("Start.registerForAPNs(\"\(deviceToken)\")") != nil {
                self.unregisteredDeviceToken = nil
            } else {
                print("Error registering for APNs")
            }
        }
    }
    
    func tabBarItemForPath(path: String) -> UITabBarItem? {
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
    
    func badgeValueForInt(int: Int) -> String? {
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
        
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Sound, UIUserNotificationType.Alert]
        let settings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        
        let application = UIApplication.sharedApplication()
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        var path = "/" + item.title!.lowercaseString
        
        if (path == "/me") {
            path = "/"
        }
        
        navigateWithinStart(path)
    }
    
    func navigateWithinStart(path: String) {
        evaluateJavascript("Start.navigate('\(path)')")
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func unarchiveCookies() {
        if let archive = NSUserDefaults.standardUserDefaults().objectForKey("Cookies") {
            let cookies = NSKeyedUnarchiver.unarchiveObjectWithData(archive as! NSData) as! [NSHTTPCookie]
            for cookie in cookies {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(cookie)
            }
        }
    }
    
    func archiveCookies() {
        let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
        let archive = NSKeyedArchiver.archivedDataWithRootObject(cookies)
        NSUserDefaults.standardUserDefaults().setObject(archive, forKey: "Cookies")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}

