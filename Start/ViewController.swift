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
    
    var webViewDidLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSUserDefaults.standardUserDefaults().registerDefaults([
            "UserAgent": "Safari/App Start/1.0"
        ]);
        
        tabBar.selectedItem = tabBar.items?.first
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://swordfish.warwick.ac.uk")!))
        
        webView.scrollView.bounces = false
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        var path = "/" + item.title!.lowercaseString
        
        if (path == "/me") {
            path = "/";
        }
        
        webView.stringByEvaluatingJavaScriptFromString(String(format: "Store.dispatch({type: 'path.navigate', path: '%@'})", path))
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        webViewDidLoad = true
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return webViewDidLoad ? .LightContent : .Default
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

