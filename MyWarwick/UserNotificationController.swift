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

    let viewController: ViewController?
    
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let state = UIApplication.shared.applicationState
        if (state == .inactive || state == .background)  {
            if (response.notification.request.content.userInfo["transient"] as? Bool ?? false) {
                let content = response.notification.request.content
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DidReceiveTransientRemoteNotification"), object: self, userInfo: ["title": content.title, "body": content.body])
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DidReceiveRemoteNotification"), object: self, userInfo: nil)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let priority = notification.request.content.userInfo["priority"] as? String ?? "normal"
        
        if priority == "high" && (notification.request.content.userInfo["transient"] as? Bool ?? false)  {
            completionHandler([.badge, .sound, .alert])
        } else {
            completionHandler([.badge])
        }
    }
}
