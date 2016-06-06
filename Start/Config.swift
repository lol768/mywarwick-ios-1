//
//  Config.swift
//  Start
//
//  Created by Alec Cursley on 07/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import Foundation

class Config {
    
    static var startURL = NSURL(string: "https://start.warwick.ac.uk")!
    
    static let ssoURL = NSURL(string: "https://websignon.warwick.ac.uk")!
    
    static let applicationNameForUserAgent = "WarwickStart/1.0"
    
    static func configuredDeploymentURL() -> NSURL? {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let deployment = defaults.stringForKey("StartDeployment") {
            
            if deployment == "custom" {
                if let customDeployment = defaults.stringForKey("StartCustomDeployment") {
                    if let url = NSURL(string: customDeployment) {
                        print("Custom deployment URL: \(url)")
                        return url
                    } else {
                        print("Invalid custom deployment URL: \(customDeployment)")
                    }
                }
            }
            
            print("Configured standard deployment \(deployment)")
            return NSURL(string: "https://\(deployment).warwick.ac.uk")
        }
        
        return nil
    }
    
}