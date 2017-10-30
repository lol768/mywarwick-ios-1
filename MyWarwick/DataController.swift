import Foundation
import CoreData

class DataController: NSObject {
    var persistentContainer: NSPersistentContainer

    override init() {
        persistentContainer = NSPersistentContainer(name: "Model")
        super.init()
    }

    func load(completionClosure: @escaping () -> ()) {
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            completionClosure()
        }
    }
}

