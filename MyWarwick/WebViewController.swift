import Foundation
import UIKit
import SafariServices
import WebKit

protocol WebViewDataSource {
    func getConfig() -> WKWebViewConfiguration
}

protocol WebViewDelegate {
    func didDismissWebView(sender: Any)
}

class WebViewController: UIViewController, WKNavigationDelegate {
    
    var delegate: WebViewDelegate?
    var dataSource: WebViewDataSource?
    
    var webView = WKWebView()
    
    func load(url: URL) {
        createWebView()
        
        webView.load(URLRequest(url: url))
    }
    
    func createWebView() {
        let configuration = dataSource?.getConfig() ?? WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self
        view = webView
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        dismissNotifyingDelegate()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        dismissNotifyingDelegate()
    }
    
    func dismissNotifyingDelegate() {
        dismiss(animated: true) {
            self.delegate?.didDismissWebView(sender: self)
        }
    }
    
}
