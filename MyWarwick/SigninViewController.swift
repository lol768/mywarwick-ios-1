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

class SigninViewController: WebViewController {
    
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
        delegate?.dismissWebView(sender: self)
    }

}
