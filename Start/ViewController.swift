//
//  ViewController.swift
//  Start
//
//  Created by Alec Cursley on 06/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import UIKit
import JavaScriptCore

@objc
protocol JSCustomObjectExport: JSExport {
    
    var unreadNotificationCount: Int { get set }
    var unreadActivityCount: Int { get set }
    var unreadNewsCount: Int { get set }
    var currentPath: String { get set }
    var isUserLoggedIn: Bool { get set }
    var isUserIdentityLoaded: Bool { get set }
    
    var isAppCached: Bool { get set }
    
}

@objc(AppState)
class AppState: NSObject, JSCustomObjectExport {
    
    var unreadNotificationCount: Int = 0
    var unreadActivityCount: Int = 0
    var unreadNewsCount: Int = 0
    var currentPath: String = "/"
    var isUserLoggedIn: Bool = false
    var isUserIdentityLoaded: Bool = false
    
    var isAppCached: Bool = false
    
}

class ViewController: UIViewController, UIWebViewDelegate, UITabBarDelegate, JSExport {
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var behindStatusBarView: UIView!
    
    var appState = AppState()
    
    var bridgeScript: String?
    
    var unreachableViewController: UIViewController = UIViewController()
    
    let reachability = try? Reachability.reachabilityForInternetConnection()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let path = NSBundle.mainBundle().pathForResource("Bridge", ofType: "js");
        
        bridgeScript = try? String(contentsOfFile: path!)
        
        unarchiveCookies()
        
        if NSUserDefaults.standardUserDefaults().boolForKey("AppCached") {
            appState.isAppCached = true
        }
        
        reachability?.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                if self.presentedViewController != nil {
                    self.dismissViewControllerAnimated(false, completion: nil)
                }
                
                if !self.appState.isAppCached {
                    self.loadWebView()
                }
            }
        }
        reachability?.whenUnreachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                if !self.appState.isAppCached && self.presentedViewController == nil {
                    self.webView.stopLoading()
                    self.presentViewController(self.unreachableViewController, animated: false, completion: nil)
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start Reachability notifier: \(error)")
        }
    }
    
    var hasRegisteredForNotifications = false
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        unreachableViewController = storyboard!.instantiateViewControllerWithIdentifier("CannotConnect")
        
        NSUserDefaults.standardUserDefaults().registerDefaults([
            "UserAgent": Config.webViewUserAgent
        ]);
        
        tabBar.selectedItem = tabBar.items?.first
        
        loadWebView()
        
        webView.scrollView.bounces = false
        
        behindStatusBarView.backgroundColor = UIColor(hue: 285.0/360.0, saturation: 27.0/100.0, brightness: 59.0/100.0, alpha: 1)
    }
    
    func loadWebView() {
        webView.loadRequest(NSURLRequest(URL: Config.startURL))
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        var path = "/" + item.title!.lowercaseString
        
        if (path == "/me") {
            path = "/";
        }
        
        webView.stringByEvaluatingJavaScriptFromString(String(format: "Store.dispatch({type: 'path.navigate', path: '%@'})", path))
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
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL {
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
    
    private var myContext = 0
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if let url = webView.request?.URL {
            if url.host == Config.startURL.host {
                let jsContext: JSContext = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext")! as! JSContext
                
                jsContext.globalObject.setObject(appState, forKeyedSubscript: "app")
                
                appState.addObserver(self, forKeyPath: "currentPath", options: .New, context: &myContext)
                
                jsContext.evaluateScript(bridgeScript)
                
                tabBar.hidden = false
            } else {
                tabBar.hidden = true
            }
        }
        
        archiveCookies()
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
    
    func updateTabBar() {
        if let selectedTabBarItem = tabBarItemForPath(appState.currentPath) {
            tabBar.selectedItem = selectedTabBarItem
        }
        
        tabBar.items![1].badgeValue = badgeValueForInt(appState.unreadNotificationCount)
        tabBar.items![2].badgeValue = badgeValueForInt(appState.unreadActivityCount)
        tabBar.items![3].badgeValue = badgeValueForInt(appState.unreadNewsCount)
        
        if appState.isAppCached {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "AppCached")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        if appState.isUserLoggedIn {
            registerForNotifications()
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
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            self.performSelector("updateTabBar", onThread: NSThread.mainThread(), withObject: nil, waitUntilDone: false)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}

