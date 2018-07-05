//
//  UserActivityController.swift
//  Snoo
//
//  Created by Rens Verhoeven on 25-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Foundation
import CoreData

private var _sharedUserActivityControllerInstance = UserActivityController()

public final class UserActivityController: NSObject {
    
    static let VisitsFlushInterval: TimeInterval = 60 // 1 minute
    static let VisitsTriggeredFlushCount = 30 //The number visits that is done to trigger a flush
    
    public class var shared: UserActivityController {
        return _sharedUserActivityControllerInstance
    }
    
    open var authenticationController: AuthenticationController? {
        didSet {
            //Flush visits in case there are any
            self.flushVisits()
        }
    }
    
    fileprivate var visitedPostNames = Set<String>()
    fileprivate var flushingVisits = false
    fileprivate var flushTimer: Timer?
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(UserActivityController.userSessionWillChange(_:)), name: AuthenticationController.UserSessionWillChangeNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserActivityController.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        self.flushTimer = Timer.scheduledTimer(timeInterval: UserActivityController.VisitsFlushInterval, target: self, selector: #selector(UserActivityController.flushTimerFired(_:)), userInfo: nil, repeats: true)
        self.flushTimer!.tolerance = 30 //30 seconds of tolerance
    }
    
    deinit {
        self.flushTimer?.invalidate()
        self.flushTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func flushVisits() {
        guard self.authenticationController?.isAuthenticated == true else {
            return
        }
        guard self.authenticationController?.activeUser(DataController.shared.privateContext)?.isGold == true else {
            return
        }
        guard self.visitedPostNames.count > 0 else {
            return
        }
        guard self.flushingVisits == false else {
            return
        }
        self.flushingVisits = true
        
        let request = RedditRequest(authenticationController: self.authenticationController!)
        request.urlSession = self.authenticationController!.userURLSession
        let url = Foundation.URL(string: "/api/store_visits", relativeTo: request.baseURL as URL)!
        
        let visitedLinks = Array(self.visitedPostNames)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = DataRequest.formPOSTDataWithParameters(["links": visitedLinks.joined(separator: ",")])
        request.urlRequest = urlRequest
        
        DataController.shared.executeAndSaveOperations([request]) { (error) in
            self.flushingVisits = false
            if let error = error as NSError? {
                if error.code == 403 {
                    //The user is no longer a gold member, however still clear the qeue!
                    self.visitedPostNames.removeAll()
                }
            } else {
                //Remove the visits
                for link in visitedLinks {
                    self.visitedPostNames.remove(link)
                }
            }
        }
    }
    
    internal func addVisit(_ post: Post) {
        guard let objectName = post.objectName else {
            return
        }
        self.visitedPostNames.insert(objectName)
        
        if self.visitedPostNames.count >= UserActivityController.VisitsTriggeredFlushCount {
            self.flushVisits()
        }
    }
    
    @objc fileprivate func flushTimerFired(_ timer: Timer) {
        self.flushVisits()
    }
    
    @objc fileprivate func userSessionWillChange(_ notification: Notification) {
        self.flushVisits()
    }
    
    @objc fileprivate func applicationDidEnterBackground(_ notification: Notification) {
        self.flushVisits()
    }
}
