//
//  WebViewController.swift
//  MyWarwick
//
//  Created by Kai Lan on 02/03/2017.
//  Copyright © 2017 University of Warwick. All rights reserved.
//
import Foundation
import UIKit
import SafariServices
import WebKit


protocol WebViewDataSource{
    func getUrl() -> URL
    func getConfig() -> WKWebViewConfiguration
}

protocol WebViewDelegate{
    func presentWebView(sender: Any?)
    func dismissWebView(sender: Any?)
}

class WebViewController: UIViewController, WKNavigationDelegate{
    
    var delegate: WebViewDelegate?
    var datasource: WebViewDataSource?
    var webView = WKWebView()
    
    func load() {
        createWebView()
        loadWebView()
    }
    
    func createWebView() {
        let configuration = datasource?.getConfig() ?? WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self
        view = webView
    }
    
    func loadWebView() {
        let url = datasource?.getUrl()
        webView.load(URLRequest(url: url! as URL))
    }
    
    
    func presentFotTitle(_ webView: WKWebView, didFinish navigation: WKNavigation!, pagetitle: String) {
        if (webView.title == pagetitle && self.presentingViewController == nil) {
            delegate?.presentWebView(sender: self)
        }
    }
    
    //must override
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        fatalError("Must Override")
    }
}
