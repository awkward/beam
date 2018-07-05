//
//  Subreddits.swift
//  Snoo
//
//  Created by Rens Verhoeven on 03-06-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import XCTest
@testable import Snoo
import CoreData

class Subreddits: XCTestCase {
    
    var testController: TestController {
        return TestController.sharedController
    }
    
    var authenticationController: AuthenticationController {
        return self.testController.authenticationController
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.resetAuthentication()
    }
    
    func testDownloadAndParseLoggedInSubreddits() {
        self.resetAuthentication()
        self.addUserAccount()
        
        XCTAssert(self.authenticationController.userSession != nil, "No available user accounts")
        
        let collectionController = CollectionController(authentication: self.testController.authenticationController, context: testController.managedObjectContext)
        let collectionQuery = SubredditsCollectionQuery()
        collectionController.query = collectionQuery
        
        let expectation = self.expectation(description: "User subreddits")
        collectionController.startInitialFetching { (collectionObjectID, error) in
            XCTAssert(error == nil, "Error getting subreddits: \(error)")
            if let collectionObjectID = collectionObjectID, let collection = self.testController.managedObjectContext.object(with: collectionObjectID) as? SubredditCollection, let subreddits = collection.objects?.array as? [Subreddit] {
                expectation.fulfill()
            } else {
                XCTAssert(collectionObjectID != nil, "No collection object ID")
                XCTAssert(false, "Invalid collection")
            }
        }
        
        self.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testParseSubreddits() {
        self.resetAuthentication()
        self.addUserAccount()
        
        XCTAssert(self.authenticationController.userSession != nil, "No available user accounts")
        
        self.measure {
            if let URL = Bundle(for: Subreddits.self).url(forResource: "SubredditsResponse", withExtension: "json") {
                
                let responseData = try! Data(contentsOf: URL)
                let responseJSON = try! JSONSerialization.jsonObject(with: responseData, options: [])
                self.startMeasuring()
                let query = SubredditsCollectionQuery()
                let parsingOperation = CollectionParsingOperation(query: query)
                parsingOperation.data = responseJSON as? NSDictionary
                let queue = OperationQueue()
                queue.addOperations([parsingOperation], waitUntilFinished: true)
                self.stopMeasuring()
                
                XCTAssert(parsingOperation.error == nil, "Error during parsing \(parsingOperation.error)")
                XCTAssert(parsingOperation.objectCollection != nil, "No collection created")
            } else {
                XCTAssert(false, "Could not find reponse file")
            }
        }
        
    }
    
    func addUserAccount() {
        do {
            let session = AuthenticationSession(userIdentifier: self.testController.userIdentifier, refreshToken: self.testController.userRefreshToken)
            try self.authenticationController.addUserSession(session)
            self.authenticationController.activeSession = session
        } catch {
            XCTAssert(false, "Error adding account")
        }
    }
    
    func resetAuthentication() {
        self.authenticationController.removeAllUserAccounts()
        XCTAssertFalse(self.authenticationController.fetchAllAuthenticationSessions().count > 0)
        
        self.authenticationController.applicationSession = nil
        self.authenticationController.userSession = nil
        
        XCTAssertFalse(self.authenticationController.isApplicationAuthenticated)
        XCTAssertFalse(self.authenticationController.isAuthenticated)
    }
    
}
