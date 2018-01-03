//
//  ProductStoreController.swift
//  beam
//
//  Created by Robin Speijer on 10-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import StoreKit
import Trekker
import CherryKit

extension Notification.Name {
    public static let ProductStoreControllerAvailableProductsChanged = Notification.Name(rawValue: "ProductStoreControllerAvailableProductsChangedNotification")
    public static let ProductStoreControllerAvailableDonationsChanged = Notification.Name(rawValue: "ProductStoreControllerAvailableDonationsChangedNotification")
    public static let ProductStoreControllerTransactionUpdated = Notification.Name(rawValue: "ProductStoreControllerTransactionUpdatedNotification")
    public static let ProductStoreControllerTrialsChanged = Notification.Name(rawValue: "ProductStoreControllerTrialsChangedNotification")
}

struct ProductStoreControllerValidationResponse {
    let status: Int
    let receipt: ProductStoreControllerReceipt
    
    init?(dictionary: [String: AnyObject]) {
        if let status = dictionary["status"] as? NSNumber, let receiptDict = dictionary["receipt"] as? [String: AnyObject], let receipt = ProductStoreControllerReceipt(dictionary: receiptDict) {
            self.status = status.intValue
            self.receipt = receipt
        } else {
            return nil
        }
    }
}

struct ProductStoreControllerReceipt {
    let bundleId: String
    let appVersion: String
    let originalAppVersion: String
    let purchases: [String]
    
    init?(dictionary: [String: AnyObject]) {
        if let bundleId = dictionary["bundle_id"] as? String, let appVersion = dictionary["application_version"] as? String, let originalAppVersion = dictionary["original_application_version"] as? String {
            self.bundleId = bundleId
            self.appVersion = appVersion
            self.originalAppVersion = originalAppVersion
            
            if let purchasesDicts = dictionary["in_app"] as? [[String: AnyObject]] {
                var purchases = [String]()
                for purchaseDict in purchasesDicts {
                    if let purchaseId = purchaseDict["product_id"] as? String {
                        purchases.append(purchaseId)
                    }
                }
                self.purchases = purchases
            } else {
                self.purchases = [String]()
            }
        } else {
            return nil
        }
    }
}


let PurchasedProductIdentifiersUserDefaultsKey = "PurchasedProductIdentifiersUserDefaultsKey"
let ActiveTrialsIdentifiersUserDefaultsKey = "ActiveTrialsIdentifiersUserDefaultsKey"

class ProductStoreController: NSObject {
    
    override init() {
        super.init()
        
        if let products = UserDefaults.standard.object(forKey: PurchasedProductIdentifiersUserDefaultsKey) as? [String] {
            self.purchasedProductIdentifiers = Set(products)
        }
        if let trialsInfo = UserDefaults.standard.object(forKey: ActiveTrialsIdentifiersUserDefaultsKey) as? [[String: AnyObject]] {
            var trials = [ProductTrial]()
            for trialInfo in trialsInfo {
                if let trial = ProductTrial(dictionary: trialInfo) {
                    trials.append(trial)
                }
            }
            self.trials = trials
        }
        
        validateProducts()
        SKPaymentQueue.default().add(self)
        requestProducts()
    }
    
    fileprivate var productsRequest: SKProductsRequest?
    
    //MARK: - Store Products
    
    var storeProductIdentifiers: [String] {
        if let path = Bundle.main.path(forResource: "Products", ofType: "plist"), let productDicts = NSArray(contentsOfFile: path) as? [[String: AnyObject]] {
            return productDicts.map({ (dict: [String: AnyObject]) -> String in
                return dict[ProductIdentifierKey] as! String
            })
        }
        
        return [String]()
    }
    
    var availableStoreProducts: [SKProduct]? {
        didSet {
            NotificationCenter.default.post(name: .ProductStoreControllerAvailableProductsChanged, object: self)
        }
    }
    
    var purchasedProductIdentifiers = Set<String>() {
        didSet {
            UserDefaults.standard.set(Array(self.purchasedProductIdentifiers), forKey: PurchasedProductIdentifiersUserDefaultsKey)
            if UIApplication.shared.isProtectedDataAvailable {
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    /// Contains currently active and previous trials tied to the device push notification device token
    var trials = [ProductTrial]() {
        didSet {
            let trialDictionaries: [[String: AnyObject]] = self.trials.map( { $0.dictionaryRepresentation() } )
            NotificationCenter.default.post(name: .ProductStoreControllerTrialsChanged, object: self)
            UserDefaults.standard.set(trialDictionaries, forKey: ActiveTrialsIdentifiersUserDefaultsKey)
            if UIApplication.shared.isProtectedDataAvailable {
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    /// Gives a date for when the lastest trail validation occured
    var lastestTrialsValidation: Date?
    
    /** 
     Is true when the user has purchased the display pack.
     For use of showing the media view and allowing certain settings
    */
    var hasPurchasedDisplayOptionsProduct: Bool {
        // Pack in-app purchases will be removed soon. This makes all features available from the start!
        return true
    }
    
    /**
     Is true when the user has purchased the identity pack.
     For use of showing the media view and allowing certain settings
     */
    var hasPurchasedIdentityPackProduct: Bool {
        // Pack in-app purchases will be removed soon. This makes all features available from the start!
        return true
    }
    
    //MARK: - Donation Products 
    
    let donationProductIdentifiers = ["beamdonationtier1", "beamdonationtier2", "beamdonationtier3", "beamdonationtier4"]
    
    var availableDonationProducts: [SKProduct]? {
        didSet {
            NotificationCenter.default.post(name: .ProductStoreControllerAvailableDonationsChanged, object: self)
        }
    }
    
    var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    fileprivate func requestProducts() {
        var productIdentifiers = self.donationProductIdentifiers
        productIdentifiers.append(contentsOf: self.storeProductIdentifiers)
        
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        self.productsRequest!.delegate = self
        self.productsRequest!.start()
    }
    
    func productInfoWithIdentifier(_ identifier: String) -> [String: AnyObject]? {
        if let path = Bundle.main.path(forResource: "Products", ofType: "plist"), let productDicts = NSArray(contentsOfFile: path) as? [[String: AnyObject]] {
            let products = productDicts.filter({ (dict: [String: AnyObject]) -> Bool in
                return (dict[ProductIdentifierKey] as? String) == identifier
            })
            return products.first
        }
        return nil
    }
    
    func availableProductWithIdentifier(_ identifier: String) -> SKProduct? {
        let donations = self.availableDonationProducts?.filter({ $0.productIdentifier == identifier })
        if donations?.first != nil {
            return donations?.first
        }
        
        let storeProducts = self.availableStoreProducts?.filter({ $0.productIdentifier == identifier })
        if storeProducts?.first != nil {
            return storeProducts?.first
        }
        return nil
    }
    
    func purchaseProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        self.restoreAdminProducts()
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /** 
    Restores all products to the purchased products, if the user is an admin.
    */

    func restoreAdminProducts() {
        if AppDelegate.shared.cherryController.isAdminUser {
            if let identifiers = availableStoreProducts?.map( { (product: SKProduct) -> String in
                return product.productIdentifier
            }) {
                let newIdentifiers = Set(identifiers)
                if newIdentifiers.symmetricDifference(self.purchasedProductIdentifiers).count != 0 {
                    self.purchasedProductIdentifiers = Set(identifiers)
                    NotificationCenter.default.post(name: .ProductStoreControllerTransactionUpdated, object: nil)
                }
            }
        }
    }
    
    // MARK: - Product validation 
    
    fileprivate func validateProducts() {
        guard self.userHasAllFreePrivileges else {
            AWKDebugLog("User has \"free\" privileges, ignore validation")
            return
        }
        if let receiptURL = Bundle.main.appStoreReceiptURL, let receipt = try? Data(contentsOf: receiptURL) {
            do {
                let request = try validationRequest(receipt)
                let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                    DispatchQueue.main.async {
                        do {
                            // Parse response and validate
                            if let data = data {
                                let response = try self.parseValidationResponse(data)
                                if response.status == 0 {
                                    self.purchasedProductIdentifiers = Set(response.receipt.purchases)
                                } else {
                                    self.clearPurchasedProductIdentifiers()
                                }
                            }
                            
                        } catch {
                            NSLog("Product validation failed: \(error)")
                            self.clearPurchasedProductIdentifiers()
                        }
                    }
                })
                task.resume()
            } catch {
                NSLog("Could not create product validation request.", error as NSError)
                self.clearPurchasedProductIdentifiers()
            }
            
        } else {
            self.clearPurchasedProductIdentifiers()
            self.restoreAdminProducts()
        }
    }
    
    // MARK: - Trials
    
    func validateTrials() {
        guard UIDevice.current.identifierForVendor?.uuidString != nil else {
            AWKDebugLog("Device token missing")
            return
        }
        guard !Config.CherryAppVersionKey.isEmpty && AppDelegate.shared.cherryController.accessToken != nil else {
            AWKDebugLog("Cherry access missing")
            return
        }
        let task = TrialsTask(token: AppDelegate.shared.cherryController.accessToken!, deviceToken: UIDevice.current.identifierForVendor!.uuidString)
        task.start { (result) -> Void in
            DispatchQueue.main.async {
                if let trialResult = result as? TrialsTaskResult {
                    self.lastestTrialsValidation = Date()
                    
                    for trial: ProductTrial in trialResult.trials {
                        let existingTrial: ProductTrial? = self.trials.filter({
                            let productTrial: ProductTrial = $0
                            return trial.productIdentifier == productTrial.productIdentifier
                        }).first
                        
                        if let existingTrial = existingTrial {
                            trial.expiredWarningShown = existingTrial.expiredWarningShown
                        }
                    }
                    self.trials = trialResult.trials
                } else {
                    if let error = result.error , result.response == nil {
                        AWKDebugLog("Trials non fatal validation error \(error)")
                    } else {
                        self.trials = [ProductTrial]()
                    }
                }
            }
        }
        
    }
    
    func startTrial(_ cherryToken: String, deviceToken: String, identifier: String, completionHandler: @escaping ((_ trials: [ProductTrial]?, _ error: Error?) -> ())) {
        let task = StartTrialTask(token: cherryToken, deviceToken: deviceToken, packName: identifier)
        task.start { (result) -> Void in
            DispatchQueue.main.async {
                if let trialResult = result as? TrialsTaskResult {
                    self.lastestTrialsValidation = Date()
                    self.trials = trialResult.trials
                    completionHandler(self.trials, nil)
                } else {
                    completionHandler(nil, result.error)
                }
            }
        }
    }
    
    func checkForTrialsExpiration(_ viewController: UIViewController) {
        DispatchQueue.main.async { 
            let trials: [ProductTrial] = self.trials
            let purchasedProducts: Set<String> = self.purchasedProductIdentifiers
            let availableProducts: [SKProduct]? = self.availableStoreProducts
            let expiredTrials: [ProductTrial] = trials.filter({
                let trial: ProductTrial = $0
                let isPurchased: Bool = purchasedProducts.contains(trial.productIdentifier)
                if trial.currentlyActive() {
                    return false
                }
                if isPurchased {
                    return false
                }
                if trial.expiredWarningShown {
                    return false
                }
                //Don't let the trial expired alerts begin before Mon, 11 Jul 2016 11:21:05 GMT
                if trial.expirationDate.timeIntervalSince1970 < 1468236065 {
                    return false
                }
                return true
            })
            
            guard let trial: ProductTrial = expiredTrials.first else {
                return
            }
            
            var productName: String = NSLocalizedString("product-name-placeholder", comment: "The placeholder for the product name")
            if let products: [SKProduct] = availableProducts {
                let filteredProducts = products.filter({
                    let product: SKProduct = $0
                    return product.productIdentifier == trial.productIdentifier
                })
                if let product: SKProduct = filteredProducts.first {
                    productName = product.localizedTitle
                }
            }
            
            var alertTitle: String = NSLocalizedString("expired-trial-alert-title", comment: "The title of the alert shown to the user when his/her trial has expired. [PRODUCTNAME] is replaced by the name of the product")
            alertTitle = alertTitle.replacingOccurrences(of: "[PRODUCTNAME]", with: productName)
            
            var alertMessage: String = NSLocalizedString("expired-trial-alert-message", comment: "The message of the alert shown to the user when his/her trial has expired. [PRODUCTNAME] is replaced by the name of the product")
            alertMessage = alertMessage.replacingOccurrences(of: "[PRODUCTNAME]", with: productName)
            
            let alertController: UIAlertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            let closeAction = UIAlertAction(title: AWKLocalizedString("close-button"), style: UIAlertActionStyle.cancel, handler: { (action) in
                trial.expiredWarningShown = true
                self.trials = trials
            })
            alertController.addAction(closeAction)
            
            let viewProductAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("view-pack-button", comment: "The button to view a specific pack"), style: UIAlertActionStyle.default, handler: { (action) in
                trial.expiredWarningShown = true
                self.trials = trials
                
                let storryboard = UIStoryboard(name: "Store", bundle: nil)
                guard let navigation = storryboard.instantiateInitialViewController() as? UINavigationController, let storeViewController = navigation.topViewController as? StoreViewController else {
                    return
                }
                
                BeamSoundType.tap.play()
                
                let product = StoreProduct(identifier: trial.productIdentifier)
                storeViewController.productToShow = product
                navigation.topViewController?.performSegue(withIdentifier: storeViewController.showPackSegueIdentifier, sender: self)
                viewController.present(navigation, animated: true, completion: nil)
            })
            alertController.addAction(viewProductAction)
            
            viewController.present(alertController, animated: true, completion: nil)
            
            
        }
    }
    
    var userHasAllFreePrivileges: Bool {
        #if DEBUG
            let debugging = true
        #else
            let debugging = false
        #endif
        return debugging && AppDelegate.shared.isRunningTestFlight
    }
    
    fileprivate func clearPurchasedProductIdentifiers() {
        if !self.userHasAllFreePrivileges {
            //Debug or testflight does not have a receipt on the device, but they are free to use the purchased products anyway so don't reset the purchased products
            self.purchasedProductIdentifiers = Set<String>()
        }
    }
    
    fileprivate func validationRequest(_ receipt: Data) throws -> URLRequest {
        let requestContents = ["receipt-data": receipt.base64EncodedString(options: [])]
        let requestData = try JSONSerialization.data(withJSONObject: requestContents, options: [])
        
        #if PURCHASE_SANDBOX
            let appStoreURLString = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
            let appStoreURLString = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        let appStoreURL = URL(string: appStoreURLString)!
        
        let request = NSMutableURLRequest(url: appStoreURL)
        request.httpMethod = "POST"
        request.httpBody = requestData
        return request as URLRequest
    }
    
    fileprivate func parseValidationResponse(_ data: Data) throws -> ProductStoreControllerValidationResponse {
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject], let response = ProductStoreControllerValidationResponse(dictionary: json) {
            return response
        } else {
            throw NSError(domain: "com.madeawkward.beam", code: 7722, userInfo: [NSLocalizedDescriptionKey: "Product validation response could not be parsed."])
        }
    }

}

// MARK: - SKProductsRequestDelegate
extension ProductStoreController: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        var storeProducts = [SKProduct]()
        var donationProducts = [SKProduct]()
        for product: SKProduct in response.products {
            if product.productIdentifier.hasPrefix("beamdonation") {
                donationProducts.append(product)
            } else {
                storeProducts.append(product)
            }
        }
        self.availableDonationProducts = donationProducts
        self.availableStoreProducts = storeProducts
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        NSLog("Products Request (%@) did fail with error \(error)", request)
    }
    
}

// MARK: - SKPaymentTransactionObserver
extension ProductStoreController: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            if transaction.transactionState == SKPaymentTransactionState.purchased || transaction.transactionState == SKPaymentTransactionState.restored {
                if transaction.transactionState == SKPaymentTransactionState.purchased {
                    var properties: [String: AnyObject] = ["Product type": transaction.payment.productIdentifier as AnyObject, "Purchase type": "In-app purchase" as AnyObject]
                    if let product = self.availableProductWithIdentifier(transaction.payment.productIdentifier) {
                        properties["Price locale"] = product.priceLocale.identifier as AnyObject?
                        properties["Local price"] = product.price
                    }
                    Trekker.default.track(event: TrekkerEvent(event: "Product purchase",properties: properties))
                }
                //Every transaction that has been restored of perchased sucessfully you handle the action the purchase causes, than finish of the transaction
                self.purchasedProductIdentifiers.insert(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            } else if transaction.transactionState == SKPaymentTransactionState.failed {
                //Failed transaction can be cancelled transaction, however they should still be finished
                SKPaymentQueue.default().finishTransaction(transaction)
            }
            NotificationCenter.default.post(name: .ProductStoreControllerTransactionUpdated, object: transaction)
        }
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            NotificationCenter.default.post(name: .ProductStoreControllerTransactionUpdated, object: transaction)
        }
    }
    
}
