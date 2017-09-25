//
//  MWUINavigationController.swift
//  MyWarwick
//
//  Created by Kai Lan on 25/09/2017.
//  Copyright © 2017 University of Warwick. All rights reserved.
//

import Foundation
import WebKit

class MWUINavigationController: UINavigationController {
    
    // apparently there is a bug in iOS 10 where UINavigationController dismisses itself when it should not
    // this bug is fixed in iOS 11.
    // this override func guards against this issue by checking if itself is presented, so that only when ((!presented && flag == true ) == true) it should be dismissed.
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if (self.presentedViewController != nil) {
            super.dismiss(animated: flag, completion: completion)
        }
    }
    
}
