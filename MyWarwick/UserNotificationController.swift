//
//  UserNotificationController.swift
//  MyWarwick
//
//  Created by Kai Lan on 27/02/2018.
//  Copyright © 2018 University of Warwick. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

@available(iOS 10.0, *)
class UserNotificationController: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let priority = notification.request.content.userInfo["priority"] as? String ?? "normal"
        
        if priority == "high"  {
            completionHandler([.alert, .badge, .sound])
        }
    }
}
