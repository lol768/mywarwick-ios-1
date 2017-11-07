import Foundation
import CoreData

class DataController: NSObject {
    var managedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

    // Pasta from https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreData/InitializingtheCoreDataStack.html
    func load(completionClosure: @escaping () -> ()) {
        //This resource is the same name as your xcdatamodeld contained in your project
        guard let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)

        managedObjectContext.persistentStoreCoordinator = psc

        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        queue.async {
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
                fatalError("Unable to resolve document directory")
            }
            let storeURL = docURL.appendingPathComponent("DataModel.sqlite")
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                completionClosure()
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }
}

