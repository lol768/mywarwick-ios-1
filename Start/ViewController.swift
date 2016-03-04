//
//  ViewController.swift
//  Start
//
//  Created by Alec Cursley on 06/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class ViewController: UIViewController, UITabBarDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var behindStatusBarView: UIView!
    
    var webView = WKWebView()
    
    var unreachableViewController: UIViewController = UIViewController()
    
    var canWorkOffline = false
    var hasRegisteredForNotifications = false
    var webViewHasLoaded = false
    
    var deviceToken: String?
    
    var reachability: Reachability?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let preferences = WKPreferences()
        preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")

        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = Config.applicationNameForUserAgent
        configuration.suppressesIncrementalRendering = true
        configuration.preferences = preferences
        
        webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.navigationDelegate = self
        
        canWorkOffline = NSUserDefaults.standardUserDefaults().boolForKey("AppCached")
        
        NSNotificationCenter.defaultCenter().addObserverForName("DidReceiveRemoteNotification", object: nil, queue: NSOperationQueue.mainQueue()) { _ -> Void in
            if self.webViewHasLoaded {
                self.webView.evaluateJavaScript("Store.dispatch({type: 'path.navigate', path: '/notifications'})", completionHandler: nil)
            } else {
                self.webView.loadRequest(NSURLRequest(URL: Config.startURL.URLByAppendingPathComponent("/notifications")))
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ -> Void in
            if self.webViewHasLoaded {
                self.webView.evaluateJavaScript("window.applicationCache.update()", completionHandler: nil)
            }
            
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("DidRegisterForRemoteNotifications", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let deviceToken = notification.userInfo?["deviceToken"] as? String {
                self.deviceToken = deviceToken
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
        
        behindStatusBarView.backgroundColor = UIColor(hue: 285.0/360.0, saturation: 27.0/100.0, brightness: 59.0/100.0, alpha: 1)
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
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.URL {
            if url.description.hasPrefix("start://") {
                decisionHandler(.Cancel)

                webView.evaluateJavaScript("JSON.stringify(window.APP)", completionHandler: { (data, error) -> Void in
                    if let json = data {
                        if let state = try? NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) {
                            self.appStateDidChange(state as! Dictionary<String, AnyObject>)
                        }
                    }
                })
            } else if url.host == Config.startURL.host || url.host == Config.ssoURL.host {
                decisionHandler(.Allow)
            } else {
                decisionHandler(.Cancel)
                
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
        } else {
            decisionHandler(.Allow)
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

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if let url = webView.URL {
            if url.host == Config.startURL.host {
                webViewHasLoaded = true
                
                setTabBarHidden(false)
            } else {
                setTabBarHidden(true)
            }
        }
    }
    
    func appStateDidChange(state: Dictionary<String, AnyObject>) {
        let items = tabBar.items!
        
        setTabBarHidden(state["tabBarHidden"] as! Bool)
        
        if let selectedTabBarItem = tabBarItemForPath(state["currentPath"] as! String) {
            tabBar.selectedItem = selectedTabBarItem
        }
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = state["unreadNotificationCount"] as! Int
        
        items[1].badgeValue = badgeValueForInt(state["unreadNotificationCount"] as! Int)
        items[2].badgeValue = badgeValueForInt(state["unreadActivityCount"] as! Int)
        items[3].badgeValue = badgeValueForInt(state["unreadNewsCount"] as! Int)
        
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
        
        if let deviceToken = self.deviceToken {
            print("Registering for APNs with device token \(deviceToken)")
            
            self.webView.evaluateJavaScript("window.registerForAPNs(\"\(deviceToken)\")", completionHandler: { (data, error) -> Void in
                if error == nil {
                    self.deviceToken = nil
                } else {
                    print("Error registering for APNs: \(error!)")
                }
            })
            
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
        
        webView.evaluateJavaScript("Store.dispatch({type: 'path.navigate', path: '\(path)'})", completionHandler: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}

