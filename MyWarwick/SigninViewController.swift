//
//  SigninViewController.swift
//  MyWarwick
//
//  Created by Kai Lan on 28/02/2017.
//  Copyright © 2017 University of Warwick. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import WebKit

protocol SigninViewControllerDataSource {
    func getSigninUrl() -> URL
    func getNameForUserAgent() -> String
    func getProcessPool() -> WKProcessPool
}

protocol SigninViewControllerDelegate {
    func presentSignInVC()
    func dismissSignInVC()
}

class SigninViewController: UIViewController, WKNavigationDelegate {
    
    var delegate: SigninViewControllerDelegate?
    var datasource: SigninViewControllerDataSource?
    var webView = WKWebView()
    
    func load() {
        loadViewIfNeeded()
        createWebView()
        loadWebView()
    }
    
    func createWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = datasource?.getNameForUserAgent()
        configuration.suppressesIncrementalRendering = true
        configuration.processPool = (datasource?.getProcessPool())!
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self
        view = webView
        
        // for future use
        /*
        view.addSubview(webView)
        view.addConstraints([
            NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
            ])*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        webView.scrollView.setContentOffset(CGPoint.zero, animated: false)
    }

    func loadWebView() {
        let url = datasource?.getSigninUrl()
        webView.load(URLRequest(url: url! as URL))
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            
            // sign in
            if url.host == Config.webSignOnURL.host && url.path == "/origin/hs"{
                decisionHandler(.allow)
                return
            }
        
            // go to my warwick
            if url.host == Config.configuredDeploymentURL()?.host && url.path == "/sso/acs" {
                decisionHandler(.allow)
                return
            }
            
        }
        decisionHandler(.cancel)
        delegate?.dismissSignInVC()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (webView.title == "Sign in" && self.presentingViewController == nil) {
            delegate?.presentSignInVC()
        }
    }
    
    func dismissMe() {
        delegate?.dismissSignInVC()
    }
}
