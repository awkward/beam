//
//  MixpanelAnalyticsService.swift
//  beam
//
//  Created by Rens Verhoeven on 09-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Trekker
import Foundation
import Mixpanel

class MixpanelAnalyticsService: NSObject, TrekkerService {
    
    var serviceName = "Mixpanel"
    
    var versionString: String {
        return self.mixpanelTracker?.libVersion() ?? "1.0"
    }
    
    var mixpanelTracker: Mixpanel!
    
    init(token: String) {
        super.init()
        self.mixpanelTracker = Mixpanel.sharedInstance(withToken: token)
    }
    
    var hasSendVisitSubreddit = false
}

// MARK: - TrekkerEventAnalytics
extension MixpanelAnalyticsService: TrekkerEventAnalytics {
    
    func trackEvent(_ event: String, withProperties properties: [String: Any]?) {
        if event == "Visit subreddit" {
            guard self.hasSendVisitSubreddit == false else {
                return
            }
            if let properties = properties {
                self.mixpanelTracker.track("Visit first subreddit", properties: properties)
            } else {
                self.mixpanelTracker.track("Visit first subreddit")
            }
            self.hasSendVisitSubreddit = true
        } else {
            
            if let properties = properties {
                self.mixpanelTracker.track(event, properties: properties)
            } else {
                self.mixpanelTracker.track(event)
            }
        }
    }
    
}

// MARK: - TrekkerTimedEventAnalytics
extension MixpanelAnalyticsService: TrekkerTimedEventAnalytics {
    
    func startTimingEvent(_ event: String) {
        self.mixpanelTracker.timeEvent(event)
    }
    
    func stopTimingEvent(_ event: String, withProperties properties: [String: Any]?) {
        self.trackEvent(event, withProperties: properties)
    }
    
}

// MARK: - TrekkerEventSuperPropertiesAnalytics
extension MixpanelAnalyticsService: TrekkerEventSuperPropertiesAnalytics {
    
    /// Called to register a set of super propeties with the service. Note that the service itself is responsible for managing the super properties, including saving to disk.
    ///
    /// - Parameter properties: The super properties for the given service.
    func registerEventSuperProperties(_ properties: [String: Any]) {
        self.mixpanelTracker.registerSuperProperties(properties)
    }
    
    /// Should remove all the registered super properties.
    func clearEventSuperProperties() {
        self.mixpanelTracker.clearSuperProperties()
    }
    
}
