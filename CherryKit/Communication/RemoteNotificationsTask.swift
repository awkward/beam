//
//  PushNotificationsTask.swift
//  CherryKit
//
//  Created by Rens Verhoeven on 13-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

public struct RemoteNotificationsPreferences {
    
    public var announcements = true
    public var shop = true
    public var messages = true
    
    init(dictionary: NSDictionary) {
        if let preference = (dictionary.object(forKey: "shop") as AnyObject).boolValue {
            self.shop = preference
        }
        if let preference = (dictionary.object(forKey: "announce") as AnyObject).boolValue {
            self.announcements = preference
        }
        if let preference = (dictionary.object(forKey: "messages") as AnyObject).boolValue {
            self.messages = preference
        }
    }
    
    func dictionaryRepresentation() -> [String: AnyObject] {
        return ["announce": self.announcements as AnyObject, "shop": self.shop as AnyObject, "messages": self.messages as AnyObject]
    }
    
}

open class RemoteNotificationsTaskResult: TaskResult {
    open var preferences: RemoteNotificationsPreferences
    
    init(preferences: RemoteNotificationsPreferences) {
        self.preferences = preferences
        super.init(error: nil)
    }
}

/// Fetches the current remote notification preferences.
open class RemoteNotificationsTask: Task {
    
    open let deviceToken: Data
    
    public init(token: String, deviceToken: Data) {
        self.deviceToken = deviceToken
        super.init(token: token)
    }
    
    open var deviceTokenString: String {
        return self.deviceToken.description.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: "<", with: "")
    }
    
    override var request: URLRequest {
        return cherryRequest("devices/notifications", queryItems: [URLQueryItem(name: "device_token", value: self.deviceTokenString)], method: RequestMethod.Get)
    }
    
    override func parseJSONData(_ data: Data) -> TaskResult {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary, let settings = json["settings"] as? NSDictionary, let preferences = settings["preferences"] as? NSDictionary {
                return RemoteNotificationsTaskResult(preferences: RemoteNotificationsPreferences(dictionary: preferences))
            } else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse share JSON response format"])
            }
        } catch {
            return TaskResult(error: error)
        }
    }
    
}

public struct RemoteNotificationsRegistrationOptions {
    public var appRelease: String
    public var appVersion: String
    public var sandbox = false
    public var userNotificationsEnabled = true
    
    public var preferences: RemoteNotificationsPreferences?
    
    public init(appRelease: String, appVersion: String, sandboxed: Bool, userNotificationsEnabled enabled: Bool) {
        self.appRelease = appRelease
        self.appVersion = appVersion
        self.sandbox = sandboxed
        self.userNotificationsEnabled = enabled
    }
}

open class RemoteNotificationsRegistrationTask: RemoteNotificationsTask {
    
    open let registrationOptions: RemoteNotificationsRegistrationOptions
    
    public init(token: String, deviceToken: Data, registrationOptions options: RemoteNotificationsRegistrationOptions) {
        self.registrationOptions = options
        super.init(token: token, deviceToken: deviceToken)
    }
    
    override var request: URLRequest {
        
        var request = cherryRequest("devices/notifications", queryItems: nil, method: RequestMethod.Post)
        
        let bodyDictionary: NSMutableDictionary = ["device_token": self.deviceTokenString, "app_version": self.registrationOptions.appVersion, "app_release": self.registrationOptions.appRelease, "ios_version": UIDevice.current.systemVersion, "is_enabled": self.registrationOptions.userNotificationsEnabled, "is_sandbox": self.registrationOptions.sandbox]
        if let preferences = self.registrationOptions.preferences {
            bodyDictionary["preferences"] = preferences.dictionaryRepresentation()
        }
        let settingsDictionary: NSMutableDictionary = ["settings": bodyDictionary]
        
        request.httpBody = self.postBodyWithDictionary(settingsDictionary)
        
        return request
    }
    
    open func postBodyWithDictionary(_ dictionary: NSDictionary) -> Data {
        let requestBody = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
        return requestBody
    }
    
}
