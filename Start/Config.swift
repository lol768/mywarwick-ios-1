//
//  Config.swift
//  Start
//
//  Created by Alec Cursley on 07/01/2016.
//  Copyright © 2016 University of Warwick. All rights reserved.
//

import Foundation

class Config {
    
    static var startURL = URL(string: "https://start-dev.warwick.ac.uk")!
    
    static let applicationNameForUserAgent = "WarwickStart/1.0"
    
    static func configuredDeploymentURL() -> URL? {
        let defaults = UserDefaults.standard
        
        if let deployment = defaults.string(forKey: "StartDeployment") {
            
            if deployment == "custom" {
                if let customDeployment = defaults.string(forKey: "StartCustomDeployment") {
                    if let url = URL(string: customDeployment) {
                        print("Custom deployment URL: \(url)")
                        return url
                    } else {
                        print("Invalid custom deployment URL: \(customDeployment)")
                    }
                }
            }
            
            print("Configured standard deployment \(deployment)")
            return URL(string: "https://\(deployment).warwick.ac.uk")
        }
        
        return nil
    }
    
}
