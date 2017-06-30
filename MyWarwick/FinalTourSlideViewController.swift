import Foundation
import UIKit

class FinalTourSlideViewController: UIViewController {

    @IBAction func finish(_ sender: Any) {
        if let tourViewController = parent as? TourViewController {
            tourViewController.finish()
        }
    }

}
