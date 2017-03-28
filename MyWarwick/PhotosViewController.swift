import Foundation
import UIKit
import SafariServices
import WebKit

class PhotosViewController: WebViewController {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            // allow photos
            if Helper.regexMatch(for: "photos(-.+)?.warwick.ac.uk", in: url.host!) {
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
        dismissNotifyingDelegate()
    }

}
