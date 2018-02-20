import Foundation
import WebKit
import CoreLocation

class MyWarwickMessageHandler: NSObject, WKScriptMessageHandler, CLLocationManagerDelegate {
    var delegate: MyWarwickDelegate
    var preferences: MyWarwickPreferences

    let locationManager = CLLocationManager()

    init(delegate: MyWarwickDelegate, preferences: MyWarwickPreferences) {
        self.delegate = delegate
        self.preferences = preferences
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
                if let bgId = body["bgId"] as? Int, let isHighContrast = body["isHighContrast"] as? Bool {
                    delegate.setBackgroundToDisplay(bgId: bgId, isHighContrast: isHighContrast)
                }
            case "loadDeviceDetails":
                delegate.loadDeviceDetails()
            case "launchTour":
                delegate.launchTour()
            case "geolocationGetCurrentPosition":
                requestLocation(updates: false)
            case "geolocationWatchPosition":
                requestLocation(updates: true)
            case "geolocationClearWatch":
                stopLocationUpdates()
            case "setTimetableToken":
                if let token = body["token"] as? String {
                    print("Setting timetable token to \(token)")
                    preferences.timetableToken = token
                }
            case "setTimetableNotificationsEnabled":
                if let enabled = body["enabled"] as? Bool {
                    preferences.timetableNotificationsEnabled = enabled
                }
            case "setTimetableNotificationTiming":
                if let timing = body["timing"] as? Int {
                    preferences.timetableNotificationTiming = timing
                }
            case "setTimetableNotificationsSoundEnabled":
                if let enabled = body["enabled"] as? Bool {
                    preferences.timetableNotificationsSoundEnabled = enabled
                }
            default:
                break
            }
        }
    }

    func requestLocation(updates: Bool) {
        if shouldRequestLocationPermission() {
            locationManager.requestWhenInUseAuthorization()
        } else if hasLocationPermission() {
            if (updates) {
                locationManager.stopUpdatingLocation()
                locationManager.startUpdatingLocation()
            } else {
                locationManager.requestLocation()
            }
        }
    }

    func stopLocationUpdates() {
        if hasLocationPermission() {
            locationManager.stopUpdatingLocation()
        }
    }

    func shouldRequestLocationPermission() -> Bool {
        return CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .notDetermined
    }

    func hasLocationPermission() -> Bool {
        if !CLLocationManager.locationServicesEnabled() {
            return false
        }

        let status = CLLocationManager.authorizationStatus()

        return status == .authorizedWhenInUse || status == .authorizedAlways
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
