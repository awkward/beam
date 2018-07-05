//
//  Message+Operations.swift
//  Snoo
//
//  Created by Robin Speijer on 17-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

extension Notification.Name {
    
    public static let RedditMessageDidChangeUnreadState = Notification.Name(rawValue: "MessageDidChangeUnreadStateNotification")
    public static let RedditMessageDidDelete = Notification.Name(rawValue: "MessageDidDeleteNotification")
    public static let RedditMessageDidSend = NSNotification.Name(rawValue: "MessageSentNotification")
}

extension Message {
    
    public func markReadOperation(_ read: Bool, authenticationController: AuthenticationController) -> Operation {
        let request = RedditRequest(authenticationController: authenticationController)
        request.urlSession = authenticationController.userURLSession
        let command = read ? "read_message" : "unread_message"
        let url = URL(string: "/api/\(command)", relativeTo: request.baseURL as URL)!
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var objectName = self.objectName
        if let referenceObjectName = self.reference?.objectName {
            objectName = referenceObjectName
        }
        let identifierQuery = URLQueryItem(name: "id", value: objectName)
        urlComponents.queryItems = [identifierQuery]
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "POST"
        request.urlRequest = urlRequest
        
        request.completionBlock = { [weak self] () in
            self?.managedObjectContext?.perform({ () -> Void in
                self?.unread = NSNumber(value: !read as Bool)
            })
        }
        
        return request
    }
    
    public class func markAllAsReadOperation(authenticationController: AuthenticationController, managedObjectContext: NSManagedObjectContext) -> Operation {
        let request = RedditRequest(authenticationController: authenticationController)
        request.urlSession = authenticationController.userURLSession
        
        let url = URL(string: "/api/read_all_messages", relativeTo: request.baseURL as URL)!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        request.urlRequest = urlRequest
        
        request.requestCompletionHandler = { (error) in
            if error == nil {
                managedObjectContext.performAndWait {
                    let fetchRequest = NSFetchRequest<Message>(entityName: Message.entityName())
                    fetchRequest.predicate = NSPredicate(format: "unread == %@", NSNumber(value: true))
                    do {
                        let messages = try managedObjectContext.fetch(fetchRequest)
                        for message in messages {
                            message.unread = false
                        }
                    } catch {
                    
                    }
                }
            }
            
        }
        
        return request
    }
    
    public func deleteOperation(_ authenticationController: AuthenticationController, managedObjectContext: NSManagedObjectContext) -> Operation {
        let request = RedditRequest(authenticationController: authenticationController)
        request.urlSession = authenticationController.userURLSession
        
        let url = URL(string: "/api/del_msg", relativeTo: request.baseURL as URL)!
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "api_type", value: "json"))
        queries.append(URLQueryItem(name: "id", value: self.identifier!))
        urlComponents.queryItems = queries
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "POST"
        request.urlRequest = urlRequest
        
        request.requestCompletionHandler = { (error: Error?) -> Void in
            guard error == nil else {
                return
            }
            managedObjectContext.performAndWait({
                managedObjectContext.delete(self)
            })
        }
        
        return request
    }
    
}
