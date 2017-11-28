import Foundation
import CoreData
import UIKit
import UserNotifications

class NotificationScheduler: NSObject {
    let timeFormatter = DateFormatter()
    var dataController: DataController
    var preferences: MyWarwickPreferences

    init(dataController: DataController, preferences: MyWarwickPreferences) {
        self.dataController = dataController
        self.preferences = preferences
        super.init()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
    }

    func notificationBody(for event: Event, at notificationDate: Date) -> String? {
        if let start = event.start {
            let time = timeFormatter.string(from: start as Date)

            let day = Calendar.current.isDate(start as Date, inSameDayAs: notificationDate) ? "Today" : "Tomorrow"

            if let location = event.location {
                return "\(location)\n\(day) at \(time)"
            }

            return "\(day) at \(time)"
        }

        return nil
    }

    func notificationTitle(for event: Event) -> String? {
        if let type = event.type {
            if let parentShortName = event.parentShortName {
                return "\(parentShortName) \(type)"
            }

            return "\(type)"
        }

        return nil
    }

    func removeAllScheduledNotifications() {
        DispatchQueue.main.async {
            objc_sync_enter(Global.notificationsLock)

            // This method must be called on the main thread
            UIApplication.shared.cancelAllLocalNotifications()

            objc_sync_exit(Global.notificationsLock)
        }
    }

    func buildNotification(for event: Event) -> UILocalNotification? {
        let notificationDate = event.start!.addingTimeInterval(TimeInterval(-60 * preferences.timetableNotificationTiming)) as Date
        if notificationDate >= Date(), let title = notificationTitle(for: event), let body = notificationBody(for: event, at: notificationDate) {
            let notification = UILocalNotification()
            notification.soundName = "TimetableAlarm.wav"
            notification.alertTitle = title
            notification.alertBody = body
            notification.fireDate = notificationDate
            return notification
        }
        return nil
    }

    func rescheduleAllNotifications() {
        var notifications: Array<UILocalNotification> = []

        let context = dataController.managedObjectContext

        if preferences.timetableNotificationsEnabled {
            let fetchRequest: NSFetchRequest<Event> = NSFetchRequest(entityName: "Event")
            fetchRequest.fetchLimit = 64
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "start", ascending: true)
            ]
            fetchRequest.predicate = NSPredicate(format: "start > %@", Date() as NSDate)
            if let events = try? context.fetch(fetchRequest) {
                for event in events {
                    if let notification = buildNotification(for: event) {
                        notifications.append(notification)
                    } else {
                        print("Notification for \(event) was nil")
                    }
                }
            }
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
