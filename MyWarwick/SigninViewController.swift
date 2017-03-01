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
    func present()
    func dismiss()
}

class SigninViewController: UIViewController, WKNavigationDelegate {
    
    var delegate: SigninViewControllerDelegate?
    var datasource: SigninViewControllerDataSource?
    var webView = WKWebView()
    var finishedLoading = false
    
    func load() {
        createWebView()
        loadWebView()
        view = webView
    }
    
    func createWebView() {
//        let userContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = datasource?.getNameForUserAgent()
        configuration.suppressesIncrementalRendering = true
//        configuration.userContentController = userContentController
        configuration.processPool = (datasource?.getProcessPool())!
        
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        webView.navigationDelegate = self
    }

    func loadWebView() {
        let url = datasource?.getSigninUrl()
        webView.load(URLRequest(url: url! as URL))
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.host == Config.webSignOnURL.host {
                decisionHandler(.allow)
                return
            }
        
            if url.host == Config.configuredDeploymentURL()?.host && url.path == "/sso/acs" {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.cancel)
        delegate?.dismiss()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.finishedLoading = true;
        if (webView.title == "Sign in" && self.presentingViewController == nil) {
            delegate?.present()
        }
    }
}
