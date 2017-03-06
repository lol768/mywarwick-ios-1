import Foundation
import UIKit
import SafariServices
import WebKit

protocol WebViewDataSource {
    func getConfig() -> WKWebViewConfiguration
}

protocol WebViewDelegate {
    func presentWebView(sender: Any)
    func dismissWebView(sender: Any)
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.presentingViewController == nil {
            delegate?.presentWebView(sender: self)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.dismissWebView(sender: self)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.dismissWebView(sender: self)
    }
    
}
