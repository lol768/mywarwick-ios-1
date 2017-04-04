import Foundation
import WebKit

class MyWarwickMessageHandler: NSObject, WKScriptMessageHandler {

    var delegate: MyWarwickDelegate

    init(delegate: MyWarwickDelegate) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? NSDictionary, let kind = body["kind"] as? String {
            switch kind {
            case "ready":
                delegate.ready()
            case "setUser":
                if let user = body["user"] as? NSDictionary, let authenticated = user["authenticated"] as? Bool, let authoritative = user["authoritative"] as? Bool {
                    if authenticated {
                        if let usercode = user["usercode"] as? String, let name = user["name"] as? String, let photo = user["photo"] as? NSDictionary, let photoURL = photo["url"] as? String {
                            delegate.setUser(AuthenticatedUser(usercode: usercode, name: name, photoURL: photoURL, authoritative: authoritative))
                        }
                    } else {
                        delegate.setUser(AnonymousUser(authoritative: authoritative))
                    }
                }
            case "setPath":
                if let path = body["path"] as? String {
                    delegate.setPath(path)
                }
            case "setWebSignOnUrls":
                if let signInURL = body["signInUrl"] as? String, let signOutURL = body["signOutURL"] as? String {
                    delegate.setWebSignOnURLs(signIn: signInURL, signOut: signOutURL)
                }
                break
            case "setUnreadNotificationCount":
                if let count = body["count"] as? Int {
                    delegate.setUnreadNotificationCount(count)
                }
            case "setAppCached":
                if let cached = body["cached"] as? Bool {
                    delegate.setAppCached(cached)
                }
            default:
                break
            }
        }
    }
}
