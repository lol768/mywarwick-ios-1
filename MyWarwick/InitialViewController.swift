import Foundation
import UIKit

class InitialViewController: UIViewController {

    var firstRunAfterTour = false

    override func viewDidAppear(_ animated: Bool) {
        let tourComplete = UserDefaults.standard.bool(forKey: "TourComplete")

        let identifier = tourComplete ? "MainViewController" : "TourViewController"

        let viewController: ViewController = storyboard!.instantiateViewController(withIdentifier: identifier) as! ViewController
        viewController.firstRunAfterTour = firstRunAfterTour
        present(viewController, animated: false, completion: nil)
    }

    func finishTour() {
        UserDefaults.standard.set(true, forKey: "TourComplete")
        firstRunAfterTour = true

        dismiss(animated: true)
    }

}
