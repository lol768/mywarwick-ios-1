import Foundation
import UIKit
import SafariServices
import WebKit

class SigninViewController: WebViewController {

    func presentSafariWebView(_ url: URL) {
        let svc = SFSafariViewController(url: url)
        
        if UIDevice.current.systemVersion.hasPrefix("9.2") {
            // Workaround for a bug in iOS 9.2 - see https://forums.developer.apple.com/thread/29048#discussion-105377
            self.modalPresentationStyle = .overFullScreen
            
            let nvc = UINavigationController(rootViewController: svc)
            nvc.isNavigationBarHidden = true
            
            present(nvc, animated: true)
        } else {
            present(svc, animated: true)
        }
    }
    
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
            
            // handle other links e.g. t&c etc.
            if url.host != Config.appURL.host {
                decisionHandler(.cancel)
                presentSafariWebView(url)
                return
            }
        }
        decisionHandler(.cancel)
        dismissNotifyingDelegate()
    }

}
