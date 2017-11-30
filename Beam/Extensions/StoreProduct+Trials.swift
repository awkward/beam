
//
//  StoreProduct+Trials.swift
//  Beam
//
//  Created by Rens Verhoeven on 09-09-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Foundation
import CherryKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension StoreProduct {
    
    var isTrialAvailable: Bool {
        if self.hasTrialStarted == true {
            return true
        }
        return AppDelegate.shared.cherryController.features?.trialsAvailable == true && AppDelegate.shared.cherryController.accessToken != nil && UIDevice.current.identifierForVendor?.uuidString != nil && self.isPurchased == false && self.storeObject?.price.floatValue > 0
    }
    
    var hasTrialStarted: Bool {
        let productTrial: ProductTrial? = AppDelegate.shared.productStoreController.trials.filter({ (trial: ProductTrial) -> Bool in
            return trial.productIdentifier == self.storeObject?.productIdentifier
        }).first
        return productTrial != nil
    }
    
    var hasTrialEnded: Bool {
        let productTrial: ProductTrial? = AppDelegate.shared.productStoreController.trials.filter({ (trial: ProductTrial) -> Bool in
            return trial.productIdentifier == self.storeObject?.productIdentifier
        }).first
        guard let trial: ProductTrial = productTrial , trial.currentlyActive() == false else {
            return false
        }
        return true
    }
    
    var trialHoursLeft: Double? {
        let productTrial: ProductTrial? = AppDelegate.shared.productStoreController.trials.filter({ (trial: ProductTrial) -> Bool in
            return trial.productIdentifier == self.storeObject?.productIdentifier
        }).first
        guard let trial: ProductTrial = productTrial else {
            return nil
        }
        let timeLeft: Double = trial.expirationDate.timeIntervalSinceNow
        let hoursLeft: Double = timeLeft / 60 / 60
        return hoursLeft
    }
    
    var trialMinutesLeft: Double? {
        let productTrial: ProductTrial? = AppDelegate.shared.productStoreController.trials.filter({ (trial: ProductTrial) -> Bool in
            return trial.productIdentifier == self.storeObject?.productIdentifier
        }).first
        guard let trial: ProductTrial = productTrial else {
            return nil
        }
        let timeLeft: Double = trial.expirationDate.timeIntervalSinceNow
        let minutesLeft: Double = timeLeft / 60 / 60 / 60
        return minutesLeft
    }
}
