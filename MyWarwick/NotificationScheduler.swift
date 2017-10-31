import Foundation
import CoreData
import UIKit
import UserNotifications

class NotificationScheduler: NSObject {
    let timeFormatter = DateFormatter()
    var dataController: DataController

    var minutesBefore = 10

    init(dataController: DataController) {
        self.dataController = dataController
        super.init()
        timeFormatter.dateFormat = "HH:mm"
    }

    func notificationBody(for event: Event) -> String {
        let parts = [
            event.parentFullName,
            event.title
        ].flatMap {
            $0
        }

        return "Your " + parts.joined(separator: " ") + " \(event.type!.lowercased()) starts in \(minutesBefore) minutes."
    }

    func notificationTitle(for event: Event) -> String {
        let time = timeFormatter.string(from: event.start! as Date)

        if let type = event.type {
            if let parentShortName = event.parentShortName {
                return "\(parentShortName) \(type.lowercased()) at \(time)"
            }

            return "\(type) at \(time)"
        }

        return "Event at \(time)"
    }

    func removeAllScheduledNotifications() {
        DispatchQueue.main.async {
            objc_sync_enter(Global.notificationsLock)

            // This method must be called on the main thread
            UIApplication.shared.cancelAllLocalNotifications()

            objc_sync_exit(Global.notificationsLock)
        }
    }

    func buildNotification(for event: Event) -> UILocalNotification {
        let notificationDate = event.start!.addingTimeInterval(TimeInterval(-60 * minutesBefore)) as Date

        let notification = UILocalNotification()
        notification.alertTitle = notificationTitle(for: event)
        notification.alertBody = notificationBody(for: event)
        notification.fireDate = notificationDate

        return notification
    }

    func rescheduleAllNotifications() {
        let context = dataController.managedObjectContext

        let fetchRequest: NSFetchRequest<Event> = NSFetchRequest(entityName: "Event")
        fetchRequest.fetchLimit = 64
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "start", ascending: true)
        ]

        var notifications: Array<UILocalNotification> = []

        if let events = try? context.fetch(fetchRequest) {
            for event in events {
                print("enumerating")
                notifications.append(buildNotification(for: event))
            }
            print("done enumerating")
        }

        DispatchQueue.main.async {
            // Lock this object to avoid others trampling on the notifications we're creating
            objc_sync_enter(Global.notificationsLock)

            UIApplication.shared.cancelAllLocalNotifications()
            for notification in notifications {
                print("Scheduling notification '\(notification.alertTitle!)' at \(notification.fireDate!)")
                UIApplication.shared.scheduleLocalNotification(notification)
            }

            objc_sync_exit(Global.notificationsLock)
        }
    }
}
