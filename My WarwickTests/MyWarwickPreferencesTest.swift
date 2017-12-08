//
//  MyWarwickPreferencesTest.swift
//  My WarwickTests
//
//  Created by Kai Lan on 08/12/2017.
//  Copyright © 2017 University of Warwick. All rights reserved.
//

import XCTest
import CoreData

class MyWarwickPreferencesTest: XCTestCase {
    
    
    let preferences = MyWarwickPreferences(userDefaults: UserDefaults.standard)
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTimetableNotificationShouldBeEnabledByDefault() {
        XCTAssert(preferences.timetableNotificationsEnabled)
    }
 

}
