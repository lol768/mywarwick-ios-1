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

}

protocol SigninViewControllerDelegate {
    func didClickCancelButton()
    func didSignIn()
    
}

class SigninViewController: UIViewController, WKNavigationDelegate {
    
    var delegate: SigninViewControllerDelegate?
    var datasource: SigninViewControllerDataSource?
    var webView = WKWebView()

    
    override func viewDidLoad() {
        createWebView()
        loadWebView()
        view = webView
    }
    
    func createWebView() {
        let userContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = datasource?.getNameForUserAgent()
        configuration.suppressesIncrementalRendering = true
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        webView.navigationDelegate = self
    }

    func loadWebView() {
        let url = datasource?.getSigninUrl()
        webView.load(URLRequest(url: url! as URL))
    }
    
}
