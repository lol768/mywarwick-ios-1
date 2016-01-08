//
//  AppDelegate.swift
//  Start
//
//  Created by Alec Cursley on 06/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let tok = deviceToken.description
        
        let token = tok.substringWithRange(Range(start: tok.startIndex.successor(), end: tok.endIndex.predecessor())).stringByReplacingOccurrencesOfString(" ", withString: "")
        
        let request = NSMutableURLRequest(URL: Config.startURL.URLByAppendingPathComponent("/api/push/apns/subscribe"))
        
        request.HTTPMethod = "POST";
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(["deviceToken": token], options: [])
        } catch {
            print(error)
        }
        
        NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: request.HTTPBody!) { (data, response, error ) -> Void in
            let httpResponse = response as! NSHTTPURLResponse
            
            if httpResponse.statusCode == 200 {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "RegisteredForRemoteNotifications")
                NSUserDefaults.standardUserDefaults().synchronize()
                
                print("Successfully registered for remote notifications")
            }
        }.resume()
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

