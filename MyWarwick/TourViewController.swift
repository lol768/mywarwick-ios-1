import Foundation
import UIKit

class TourViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    var tourPages: [UIViewController] = []

    let pageControl = UIPageControl()

    let finishButton: UIButton = UIButton(type: .system)

    override func viewDidLoad() {
        if storyboard != nil {
            tourPages = [1, 2, 3, 4, 6, 7, 8].map { (n: Int) -> UIViewController in
                return storyboard!.instantiateViewController(withIdentifier: "TourSlide\(n)")
            }
        }

        pageControl.numberOfPages = tourPages.count

        delegate = self
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

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        view.addSubview(pageControl)

        var pageControlBottomConstraint =  NSLayoutConstraint(item: pageControl, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        if #available(iOS 11, *) {
            pageControlBottomConstraint = NSLayoutConstraint(item: pageControl, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        }
        
        view.addConstraints([
                NSLayoutConstraint(item: pageControl, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: pageControl, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
                pageControlBottomConstraint,
                NSLayoutConstraint(item: pageControl, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24)
        ])

        view.bringSubview(toFront: pageControl)

        if let firstPage = tourPages.first {
            setViewControllers([firstPage], direction: .forward, animated: true, completion: nil)
        }
    }

    func changePage() {
        let previousPage: Int = tourPages.index(of: viewControllers!.first!)!

        let something = previousPage < pageControl.currentPage

        let vc = tourPages[pageControl.currentPage]
        let direction = something ? UIPageViewControllerNavigationDirection.forward : UIPageViewControllerNavigationDirection.reverse

        setViewControllers([vc], direction: direction, animated: true, completion: nil)
    }

    func finish() {
        if let initialViewController = presentingViewController as? InitialViewController {
            initialViewController.finishTour()
        } else {
            dismiss(animated: false, completion: nil)
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

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let vc = pageViewController.viewControllers?.first, let index = tourPages.index(of: vc) {
            pageControl.currentPage = index
        }
    }

}
