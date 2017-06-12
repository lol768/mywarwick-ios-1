import Foundation
import UIKit

class TourViewController: UIPageViewController, UIPageViewControllerDataSource {

    var tourPages: [UIViewController] = []

    var finishButton: UIButton = UIButton(type: .system)

    override func viewDidLoad() {
        if storyboard != nil {
            tourPages = [1, 2, 3, 4, 5, 6, 7, 8].map { (n: Int) -> UIViewController in
                storyboard!.instantiateViewController(withIdentifier: "TourSlide\(n)")
            }
        }

        dataSource = self
        view.backgroundColor = UIColor.white

        finishButton.addTarget(self, action: #selector(finish), for: .touchUpInside)
        finishButton.setImage(UIImage(named: "Cancel"), for: .normal)
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.tintColor = UIColor.black.withAlphaComponent(0.6)

        view.addSubview(finishButton)

        view.addConstraints([
                NSLayoutConstraint(item: finishButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60),
                NSLayoutConstraint(item: finishButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60),
                NSLayoutConstraint(item: finishButton, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 20),
                NSLayoutConstraint(item: finishButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        view.bringSubview(toFront: finishButton)

        if let firstPage = tourPages.first {
            setViewControllers([firstPage], direction: .forward, animated: true, completion: nil)
        }
    }

    func finish() {
        if let initialViewController = presentingViewController as? InitialViewController {
            initialViewController.finishTour()
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = tourPages.index(of: viewController)!

        if (index >= tourPages.count - 1) {
            return nil
        }

        return tourPages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = tourPages.index(of: viewController)!

        if (index <= 0) {
            return nil
        }

        return tourPages[index - 1]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return tourPages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }

}
