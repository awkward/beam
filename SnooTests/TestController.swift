//
//  TestController.swift
//  Snoo
//
//  Created by Rens Verhoeven on 03-06-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import XCTest
import Snoo
import CoreData

private var _sharedTestInstance = TestController()

/// This class mimics the AppDelegate that will hold AuthenticationController in the normal app
class TestController: NSObject {
    
    internal let redditClientId = "ISKV7kGNtP8X9Q"
    internal let redditClientName = "Beam"
    internal let redditRedirectURI = "beam://127.0.0.1/authorized"
    
    internal let userRefreshToken = "40755501-aA8vk7aKnvkAtnv8T6-s5yZ4KI8"
    internal let userIdentifier = "o9j59"
    internal let username = "btestaccount"
    
    override init() {
        self.authenticationController = AuthenticationController(clientID: self.redditClientId, redirectUri: self.redditRedirectURI, clientName: self.redditClientName, loadCurrentSession: false)
        DataController.sharedController.authenticationController = self.authenticationController
        self.managedObjectContext = DataController.sharedController.createMainContext()
        super.init()
    }
    
    class var sharedController: TestController {
        return _sharedTestInstance
    }
    
    var authenticationController: AuthenticationController

    var managedObjectContext: NSManagedObjectContext
}
