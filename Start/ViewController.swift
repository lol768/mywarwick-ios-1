//
//  ViewController.swift
//  Start
//
//  Created by Alec Cursley on 06/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate, UITabBarDelegate {
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var behindStatusBarView: UIView!
    
    var bridgeScript: String?
    
    var unreachableViewController: UIViewController = UIViewController()
    
    var canWorkOffline = false
    var hasRegisteredForNotifications = false
    var webViewHasLoaded = false
    
    var reachability: Reachability?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let path = NSBundle.mainBundle().pathForResource("Bridge", ofType: "js")
        bridgeScript = try? String(contentsOfFile: path!)
        
        unarchiveCookies()
        
        canWorkOffline = NSUserDefaults.standardUserDefaults().boolForKey("AppCached")
        hasRegisteredForNotifications = NSUserDefaults.standardUserDefaults().boolForKey("RegisteredForRemoteNotifications")
        
        NSNotificationCenter.defaultCenter().addObserverForName("DidReceiveRemoteNotification", object: nil, queue: NSOperationQueue.mainQueue()) { _ -> Void in
            if self.webViewHasLoaded {
                self.webView.stringByEvaluatingJavaScriptFromString(String(format: "Store.dispatch({type: 'path.navigate', path: '%@'})", "/notifications"))
            } else {
                self.webView.loadRequest(NSURLRequest(URL: Config.startURL.URLByAppendingPathComponent("/notifications")))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        unreachableViewController = storyboard!.instantiateViewControllerWithIdentifier("CannotConnect")
        
        NSUserDefaults.standardUserDefaults().registerDefaults([
            "UserAgent": Config.webViewUserAgent
            ]);
        
        tabBar.selectedItem = tabBar.items?.first
        
        loadWebView()
        
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = UIColor(white: 1, alpha: 1)
        
        behindStatusBarView.backgroundColor = UIColor(hue: 285.0/360.0, saturation: 27.0/100.0, brightness: 59.0/100.0, alpha: 1)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        initReachability()
    }
    
    func initReachability() {
        reachability = try? Reachability.reachabilityForInternetConnection()
        
        reachability?.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                if self.presentedViewController != nil {
                    self.dismissViewControllerAnimated(false, completion: nil)
                }
                
                if !self.canWorkOffline {
                    self.loadWebView()
                }
            }
        }
        
        reachability?.whenUnreachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                if !self.canWorkOffline && self.presentedViewController == nil {
                    self.webView.stopLoading()
                    self.presentViewController(self.unreachableViewController, animated: false, completion: nil)
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
            url = Config.startURL.URLByAppendingPathComponent("/notifications")
        }
        
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL {
            if url.description.hasPrefix("start://") {
                let json = webView.stringByEvaluatingJavaScriptFromString("JSON.stringify(window.app)")!
                
                let state = try? NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
                
                appStateDidChange(state! as! Dictionary<String, AnyObject>)
                
                return false
            }
            
            if url.host == Config.startURL.host || url.host == Config.ssoURL.host {
                return true
            } else {
                UIApplication.sharedApplication().openURL(url)
                return false
            }
        } else {
            return true
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if let url = webView.request?.URL {
            if url.host == Config.startURL.host {
                webView.stringByEvaluatingJavaScriptFromString(bridgeScript!)
                webViewHasLoaded = true
                
                tabBar.hidden = false
                webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
                webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 91, left: 0, bottom: 48, right: 0)
            } else {
                tabBar.hidden = true
                webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
        }
        
        archiveCookies()
    }
    
    func appStateDidChange(state: Dictionary<String, AnyObject>) {
        if let selectedTabBarItem = tabBarItemForPath(state["currentPath"] as! String) {
            tabBar.selectedItem = selectedTabBarItem
        }
        
        tabBar.items![1].badgeValue = badgeValueForInt(state["unreadNotificationCount"] as! Int)
        tabBar.items![2].badgeValue = badgeValueForInt(state["unreadActivityCount"] as! Int)
        tabBar.items![3].badgeValue = badgeValueForInt(state["unreadNewsCount"] as! Int)
        
        if !canWorkOffline && state["isAppCached"] as! Bool == true {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "AppCached")
            NSUserDefaults.standardUserDefaults().synchronize()
            canWorkOffline = true
            print("App cached for offline working")
        }
        
        if state["isUserLoggedIn"] as! Bool == true {
            registerForNotifications()
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
            path = "/";
        }
        
        webView.stringByEvaluatingJavaScriptFromString(String(format: "Store.dispatch({type: 'path.navigate', path: '%@'})", path))
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func archiveCookies() {
        let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
        let archive = NSKeyedArchiver.archivedDataWithRootObject(cookies)
        NSUserDefaults.standardUserDefaults().setObject(archive, forKey: "Cookies")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func unarchiveCookies() {
        if let archive = NSUserDefaults.standardUserDefaults().objectForKey("Cookies") {
            let cookies = NSKeyedUnarchiver.unarchiveObjectWithData(archive as! NSData) as! [NSHTTPCookie]
            for cookie in cookies {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(cookie)
            }
        }
    }

}

