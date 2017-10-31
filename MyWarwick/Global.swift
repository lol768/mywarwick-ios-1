import Foundation

class Global {
    static var didLaunchFromRemoteNotification = false

    static let backgroundQueue: DispatchQueue = DispatchQueue(label: "backgroundQueue", qos: .background)

    static let notificationsLock = NSObject()
}
