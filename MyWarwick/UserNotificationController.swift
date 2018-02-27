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

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let remoteNotification = response.notification
        let priority = response.notification.request.content.userInfo["priority"] as? String ?? "normal"
        print("here!! priority")
        print(priority)
        if priority == "high"  {
            // now we create a local notification with high priority
            let notification = UILocalNotification()
            let content = remoteNotification.request.content
            notification.alertTitle = content.title
            notification.alertBody = content.body
            notification.userInfo = ["priority": "high"]
            UIApplication.shared.scheduleLocalNotification(notification)
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("local ones")
        let priority = notification.request.content.userInfo["priority"] as? String ?? "normal"
        
        if priority == "high"  {
            completionHandler([.alert, .badge, .sound])
        }
    }
}
