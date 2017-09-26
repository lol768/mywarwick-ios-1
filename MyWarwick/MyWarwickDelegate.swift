import Foundation
import CoreLocation

protocol MyWarwickDelegate {

    func ready()

    func setPath(_ path: String)

    func setUnreadNotificationCount(_ count: Int)

    func setAppCached(_ cached: Bool)

    func setUser(_ user: User)

    func setWebSignOnURLs(signIn: String, signOut: String)
    
    func loadDeviceDetails()

    func setBackgroundToDisplay(bgId: Int)
    
    func launchTour()

    func locationDidUpdate(location: CLLocation)

    func locationDidFail(error: Error)

}
