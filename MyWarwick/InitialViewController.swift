import Foundation
import UIKit

class InitialViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        let tourComplete = UserDefaults.standard.bool(forKey: "TourComplete")

        let identifier = tourComplete ? "MainViewController" : "TourViewController"

        let viewController = storyboard!.instantiateViewController(withIdentifier: identifier)
        present(viewController, animated: false, completion: nil)
    }

    func finishTour() {
        UserDefaults.standard.set(true, forKey: "TourComplete")

        dismiss(animated: true)
    }

}
