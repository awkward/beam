//
//  SnooTests.swift
//  SnooTests
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import UIKit
import XCTest
@testable import Snoo

class Authentication: XCTestCase {
    
    var testController: TestController {
        return TestController.sharedController
    }

    var authenticationController: AuthenticationController {
        return self.testController.authenticationController
    }
    
    override func setUp() {
        super.setUp()
        
        self.testController.authenticationController.removeAllUserAccounts()
        XCTAssertFalse(self.testController.authenticationController.fetchAllAuthenticationSessions().count > 0)

    }
    
    func testApplicationTokenRequest() {

        func testApplicationTokenResult() {
            XCTAssertNotNil(self.authenticationController.applicationSession?.accessToken, "Application token not received")
            XCTAssertEqual(self.authenticationController.applicationSession?.accessToken, self.authenticationController.activeSession?.accessToken)
            XCTAssertTrue(self.authenticationController.isApplicationAuthenticated)
            XCTAssertFalse(self.authenticationController.isAuthenticated)
        }
        
        self.performAuthentication()
        testApplicationTokenResult()
        self.testController.authenticationController = AuthenticationController(clientID: self.testController.redditClientId, redirectUri: self.testController.redditRedirectURI, clientName: self.testController.redditClientName)
        testApplicationTokenResult()
        
        self.resetAuthentication()
    }
    
    func testAccessTokenRequest() {
        self.addUserAccount()
        
        XCTAssertNotNil(self.authenticationController.userSession)
        XCTAssertFalse(self.authenticationController.userSession?.isValid ?? false)
        
        self.performAuthentication()
        
        XCTAssertEqual(self.authenticationController.userSession, self.authenticationController.activeSession)
        XCTAssertTrue(self.authenticationController.isAuthenticated)
        XCTAssertEqual(self.testController.userIdentifier, self.authenticationController.activeUserIdentifier)
        
        self.authenticationController.activeSession?.destroy()
        XCTAssertNil(self.authenticationController.userSession?.refreshToken)
        
        self.resetAuthentication()
        
    }
    
    func testUserRefresh() {
        self.addUserAccount()
        
        self.performAuthentication()
        XCTAssertTrue(self.authenticationController.isAuthenticated)
        XCTAssertEqual(self.authenticationController.activeSession, self.authenticationController.userSession)
        
        let expectation = self.expectation(description: "User refresh")
        self.authenticationController.requestActiveUser { (userID, identifier, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(userID)
            XCTAssertNotNil(identifier)
            
            guard let objectContext = DataController.shared.privateContext else {
                XCTFail("Context missing")
                return
            }
            objectContext.perform {
                do {
                    if let userID = userID, let user = try objectContext.existingObject(with: userID) as? User {
                        XCTAssertNotNil(user)
                        XCTAssertEqual(user.identifier, identifier)
                        XCTAssertEqual(user.username, self.testController.username)
                    }
                } catch {
                    XCTAssertNil(error)
                }
                
                expectation.fulfill()
            }
            
        }
        
        self.waitForExpectations(timeout: 20, handler: nil)
        self.resetAuthentication()
        
    }
    
    func testLogout() {
        self.addUserAccount()
        
        self.performAuthentication()
        XCTAssertTrue(self.authenticationController.isAuthenticated)
        
        let expectation = self.expectation(description: "Logout")
        if let session = self.authenticationController.activeUserSession {
            self.authenticationController.removeUserSession(session, handler: {
                expectation.fulfill()
            })
        } else {
            XCTAssertNil(false, "Account missing")
        }
        
        self.waitForExpectations(timeout: 20) { (error) -> Void in
            XCTAssertNil(error)
        }
        
        self.resetAuthentication()
        
    }
    
    func testLogoutAll() {
        self.addUserAccount()
        
        self.performAuthentication()
        XCTAssertTrue(self.authenticationController.isAuthenticated)
        
        let expectation = self.expectation(description: "Logout")
        self.authenticationController.removeAllUserAccounts()
        if self.authenticationController.fetchAllAuthenticationSessions().count == 0 {
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 20) { (error) -> Void in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(self.authenticationController.isAuthenticated)
        XCTAssertNil(self.authenticationController.userSession)
        
        self.resetAuthentication()
        
    }
    
    func performAuthentication() {
        let authOperations = self.authenticationController.authenticationOperations()
        
        let expectation = self.expectation(description: "User authentication")
        DataController.shared.executeOperations(authOperations) { (error) -> Void in
            XCTAssertNil(error, "An error occured while refreshing access token: \(error)")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 20) { (error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(self.authenticationController.activeSession?.accessToken, "token not received")
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
    
    override func tearDown() {

        super.tearDown()
    }
    
}
