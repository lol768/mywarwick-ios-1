import Foundation
import CoreData
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
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleNotification(for event: Event) {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: event)
        content.body = notificationBody(for: event)

        let notificationDate = event.start!.addingTimeInterval(TimeInterval(-60 * minutesBefore)) as Date
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: notificationDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: event.serverId!, content: content, trigger: trigger)

        print("Scheduling notification '\(content.title)' at \(notificationDate)")

        UNUserNotificationCenter.current().add(request) { (error) in
            if let e = error {
                print("Error scheduling notification: \(e)")
            }
        }
    }

    func rescheduleAllNotifications() {
        removeAllScheduledNotifications()

        let container = dataController.persistentContainer
        let context = container.viewContext

        let fetchRequest: NSFetchRequest<Event> = NSFetchRequest(entityName: "Event")
        fetchRequest.fetchLimit = 64
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "start", ascending: true)
        ]
        if let events = try? context.fetch(fetchRequest) {
            for event in events {
                scheduleNotification(for: event)
            }
        }

        print("Rescheduled all notifications")
    }
}
