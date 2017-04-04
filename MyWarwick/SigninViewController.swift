import Foundation
import UIKit
import SafariServices
import WebKit

class SigninViewController: WebViewController {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            // sign in
            if url.host == Config.webSignOnURL.host && url.path == "/origin/hs" {
                decisionHandler(.allow)
                return
            }

            // go to my warwick
            if url.host == Config.appURL.host && url.path == "/sso/acs" {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.cancel)
        dismissNotifyingDelegate()
    }

}
