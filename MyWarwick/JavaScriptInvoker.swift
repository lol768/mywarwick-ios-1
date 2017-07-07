import Foundation
import WebKit

class JavaScriptInvoker {

    var pageReady = false
    var webView: WKWebView?
    var queue: Array<String> = []

    func invoke(_ js: String) {
        if pageReady && webView != nil {
            invokeNow(js)
        } else {
            queue.insert(js, at: 0)
        }
    }

    private func invokeNow(_ js: String) {
        if let wv = webView {
            print("Invoking MyWarwick.\(js)")
            wv.evaluateJavaScript("MyWarwick.\(js)") { (result, error) in
                let path = wv.url!.path
                if path == "/" || path.hasPrefix("/edit") || path.hasPrefix("/tiles") {
                    wv.backgroundColor = UIColor.clear
                } else {
                    UIView.animate(withDuration: 0.5, animations: { // this ensures user not seeing the tile without bg img when leaving meview
                        wv.backgroundColor = UIColor(white: 249 / 255, alpha: 1)
                    })
                }
            }
        }
    }

    func notReady() {
        print("Page is not ready")
        pageReady = false
    }

    func ready() {
        print("Page is ready")

        pageReady = true

        while !queue.isEmpty {
            if let js = queue.popLast() {
                invokeNow(js)
            }
        }
    }
    
    func loadDeviceDetails(url: URL?) {
        let screenSize = UIScreen.main.bounds
        let details = [
            "os": UIDevice.current.systemName,
            "os-version": UIDevice.current.systemVersion,
            "device": UIDevice.current.model,
            "screen-width": String(describing: screenSize.width),
            "screen-height": String(describing: screenSize.height),
            "path": url?.path ?? ""
        ]
        let json = String(
            data: try! JSONSerialization.data(withJSONObject: details),
            encoding: .ascii
        )?.replacingOccurrences(of: "'", with: "\\'")
        invoke("feedback('\(json ?? "{}")')")
    }

}
