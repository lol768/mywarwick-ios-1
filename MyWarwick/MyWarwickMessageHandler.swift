import Foundation
import WebKit
import CoreLocation

class MyWarwickMessageHandler: NSObject, WKScriptMessageHandler, CLLocationManagerDelegate {

    var delegate: MyWarwickDelegate

    let locationManager = CLLocationManager()

    init(delegate: MyWarwickDelegate) {
        self.delegate = delegate
        super.init()
        locationManager.delegate = self
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? NSDictionary, let kind = body["kind"] as? String {
            switch kind {
            case "ready":
                delegate.ready()
            case "setUser":
                if let user = body["user"] as? NSDictionary, let authenticated = user["authenticated"] as? Bool {
                    // If this value is unspecified, assume a logged-in user is authoritatively so, and a
                    // logged-out user is not authoritatively so.  This triggers push registration for new
                    // users, but prevents deregistration upon signing out, which mimics the behaviour
                    // prior to this change.
                    let authoritative = user["authoritative"] as? Bool ?? authenticated

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
            case "setUnreadNotificationCount":
                if let count = body["count"] as? Int {
                    delegate.setUnreadNotificationCount(count)
                }
            case "setAppCached":
                if let cached = body["cached"] as? Bool {
                    delegate.setAppCached(cached)
                }
            case "setBackgroundToDisplay":
                if let bgId = body["bgId"] as? Int {
                    delegate.setBackgroundToDisplay(bgId: bgId)
                }
            case "loadDeviceDetails":
                delegate.loadDeviceDetails()
            case "launchTour":
                delegate.launchTour()
            case "geolocationGetCurrentPosition":
                if !CLLocationManager.locationServicesEnabled() {
                    break
                }

                let status = CLLocationManager.authorizationStatus()

                if status == .notDetermined {
                    locationManager.requestWhenInUseAuthorization()
                } else if status == .authorizedAlways || status == .authorizedWhenInUse {
                    locationManager.requestLocation()
                }
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            delegate.locationDidUpdate(location: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate.locationDidFail(error: error)
    }
}
