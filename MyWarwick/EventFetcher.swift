import Foundation
import CoreData

class EventFetcher: NSObject {
    let isoDateFormatter = DateFormatter()
    var dataController: DataController
    var preferences: MyWarwickPreferences

    init(dataController: DataController, preferences: MyWarwickPreferences) {
        self.dataController = dataController
        self.preferences = preferences
        super.init()
        isoDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
    }

    func initialise(_ event: Event, from item: [String: AnyObject]) {
        event.serverId = item["id"] as? String
        event.type = item["type"] as? String
        event.title = item["title"] as? String

        if let location = item["location"] as? [String: String] {
            event.location = location["name"]
        }

        if let parent = item["parent"] as? [String: String] {
            event.parentShortName = parent["shortName"]
            event.parentFullName = parent["fullName"]
        }

        if let dateString = item["start"] as? String, let startDate = isoDateFormatter.date(from: dateString) {
            event.start = startDate as NSDate
        }

        if let dateString = item["end"] as? String, let endDate = isoDateFormatter.date(from: dateString) {
            event.end = endDate as NSDate
        }
    }

    func deleteAllEvents() {
        let context = dataController.managedObjectContext

        context.perform {
            if let events = try? context.fetch(NSFetchRequest<Event>(entityName: "Event")) {
                for event in events {
                    context.delete(event)
                }
            }

            do {
                try context.save()
                print("Deleted all events")
            } catch let e {
                print("Error saving the context with deleted events: \(e)")
            }
        }
    }

    func didReceiveEventData(response: [String: AnyObject]) {
        if let data = response["data"] as? [String: AnyObject], let events = data["items"] as? [[String: AnyObject]] {
            let context = dataController.managedObjectContext

            context.perform {
                if let events = try? context.fetch(NSFetchRequest<Event>(entityName: "Event")) {
                    for event in events {
                        context.delete(event)
                    }
                }

                for item in events {
                    let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context) as! Event
                    self.initialise(event, from: item)
                }

                do {
                    try context.save()
                    print("Event data updated")
                } catch let e {
                    print("Error saving the context with new events: \(e)")
                }

                NotificationScheduler(dataController: self.dataController).rescheduleAllNotifications()
            }
        } else {
            print("Response from timetable endpoint was in an unexpected format")
        }
    }

    func updateEvents(completionHandler: @escaping (Bool) -> ()) {
        var request = URLRequest(url: Config.appURL.appendingPathComponent("/api/timetable"))
        if let token = preferences.timetableToken {
            request.addValue(token, forHTTPHeaderField: "X-Timetable-Token")
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
            if let e = error {
                print("Error in URLSession: \(e)")
                completionHandler(false)
            } else {
                do {
                    let response = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                    self.didReceiveEventData(response: response)
                    completionHandler(true)
                } catch let e {
                    print("Error parsing JSON: \(e)")
                    completionHandler(false)
                }
            }
        }
        task.resume()
    }
}
