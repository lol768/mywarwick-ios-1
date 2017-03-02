//
//  AccountSettingViewController.swift
//  MyWarwick
//
//  Created by Kai Lan on 02/03/2017.
//  Copyright © 2017 University of Warwick. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import WebKit

class AccountSettingViewController: WebViewController {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            

            // allow the redirect url
            if (url.host == "warwick.ac.uk" || url.host == "www2.warwick.ac.uk") && url.path == "/myaccount" {
                decisionHandler(.allow)
                return
            }
            
            // all everything on websignon
            if url.host == Config.webSignOnURL.host {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.allow)
        delegate?.dismissWebView(sender: self)
    }
}
