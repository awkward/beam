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
    public static let ProductStoreControllerAvailableDonationsChanged = Notification.Name(rawValue: "ProductStoreControllerAvailableDonationsChangedNotification")
    public static let ProductStoreControllerTransactionUpdated = Notification.Name(rawValue: "ProductStoreControllerTransactionUpdatedNotification")
}

final class ProductStoreController: NSObject {
    
    override init() {
        super.init()
        
        SKPaymentQueue.default().add(self)
        requestProducts()
    }
    
    fileprivate var productsRequest: SKProductsRequest?

    // MARK: - Donation Products
    
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
        let productIdentifiers = self.donationProductIdentifiers
        
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        self.productsRequest!.delegate = self
        self.productsRequest!.start()
    }
    
    func availableProductWithIdentifier(_ identifier: String) -> SKProduct? {
        return self.availableDonationProducts?.first(where: { (product) -> Bool in
            product.productIdentifier == identifier
        })
    }
    
    func purchaseProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

}

// MARK: - SKProductsRequestDelegate
extension ProductStoreController: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let donationProducts = response.products.filter { (product) -> Bool in
            return product.productIdentifier.hasPrefix("beamdonation")
        }
        self.availableDonationProducts = donationProducts
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        NSLog("Products Request (%@) did fail with error \(error)", request)
    }
    
}

// MARK: - SKPaymentTransactionObserver
extension ProductStoreController: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transaction) in
            if transaction.transactionState == SKPaymentTransactionState.purchased || transaction.transactionState == SKPaymentTransactionState.restored {
                if transaction.transactionState == SKPaymentTransactionState.purchased {
                    var properties: [String: AnyObject] = ["Product type": transaction.payment.productIdentifier as AnyObject, "Purchase type": "In-app purchase" as AnyObject]
                    if let product = self.availableProductWithIdentifier(transaction.payment.productIdentifier) {
                        properties["Price locale"] = product.priceLocale.identifier as AnyObject?
                        properties["Local price"] = product.price
                    }
                    Trekker.default.track(event: TrekkerEvent(event: "Product purchase", properties: properties))
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            } else if transaction.transactionState == SKPaymentTransactionState.failed {
                //Failed transaction can be cancelled transaction, however they should still be finished
                SKPaymentQueue.default().finishTransaction(transaction)
            }
            NotificationCenter.default.post(name: .ProductStoreControllerTransactionUpdated, object: transaction)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transaction) in
            NotificationCenter.default.post(name: .ProductStoreControllerTransactionUpdated, object: transaction)
        }
    }
    
}
