//
//  PhotoViewController.swift
//  MyWarwick
//
//  Created by Kai Lan on 02/03/2017.
//  Copyright © 2017 University of Warwick. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import WebKit

class PhotosViewController: WebViewController {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            
            // allow photos
            if url.host == "photos.warwick.ac.uk" {
                decisionHandler(.allow)
                return
            }
            
            // allow websignon
            if url.host == Config.webSignOnURL.host {
                decisionHandler(.allow)
                return
            }
            
        }
        decisionHandler(.cancel)
        delegate?.dismissWebView(sender: self)
    }

}
