//
//  DonateViewController.swift
//  beam
//
//  Created by John van de Water on 21/10/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import StoreKit

class DonateViewController: BeamViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var donationButtons: [UIButton]!
    
    var productStoreController: ProductStoreController = {
        return AppDelegate.shared.productStoreController
    }()
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = NumberFormatter.Behavior.behavior10_4
        formatter.numberStyle = NumberFormatter.Style.currency
        return formatter
    }()
    
    var purchasingEnabled: Bool = false {
        didSet {
            self.reloadDonateButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(DonateViewController.donationsDidChange(_:)), name: .ProductStoreControllerAvailableDonationsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DonateViewController.transactionUpdated(_:)), name: .ProductStoreControllerTransactionUpdated, object: nil)
        
        self.purchasingEnabled = SKPaymentQueue.default().transactions.count == 0
        
        self.navigationItem.title = AWKLocalizedString("donate-title")
        self.titleLabel.text = AWKLocalizedString("donate-text-title")
        self.textLabel.text = AWKLocalizedString("donate-text-description")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func displayModeDidChange() {
        
        super.displayModeDidChange()
        
        self.reloadDonateButtons()
        
        switch self.displayMode {
        case .default:
            self.titleLabel.textColor = UIColor.beamGreyExtraDark()
            self.textLabel.textColor = UIColor.beamGreyDark()
            self.imageView.image = UIImage(named: "donate_image")
        case .dark:
            self.titleLabel.textColor = UIColor.white
            self.textLabel.textColor = UIColor.beamGreyLight()
            self.imageView.image = UIImage(named: "donate_image_darkmode")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadDonateButtons()
    }
    
    @objc fileprivate func donationsDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.reloadDonateButtons()
        }
    }
    
    @objc fileprivate func transactionUpdated(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.purchasingEnabled = SKPaymentQueue.default().transactions.count == 0
            if let transaction = notification.object as? SKPaymentTransaction {
                if transaction.transactionState == .purchased && transaction.payment.productIdentifier.hasPrefix("beamdonation") {
                    UserSettings[.userHasDonated] = true
                    self.performSegue(withIdentifier: "showThankYou", sender: notification)
                }
            }
        }
    }
    
    func reloadDonateButtons() {
        for identifier in self.productStoreController.donationProductIdentifiers {
            if let index = self.productStoreController.donationProductIdentifiers.index(of: identifier) {
                let button = self.donationButtons[index]
                let product = self.donationProductForProductIdentifier(identifier)
                button.isHidden = (product == nil)
                if let product = product {
                    self.priceFormatter.locale = product.priceLocale
                    let string = self.priceFormatter.string(from: product.price)
                    button.setTitle(string, for: UIControlState())
                }
                button.isEnabled = self.purchasingEnabled
                button.alpha = (self.purchasingEnabled ? 1: 0.5)
            }
        }
    }
    
    func donationProductForProductIdentifier(_ identifier: String) -> SKProduct? {
        let products = self.productStoreController.availableDonationProducts?.filter({$0.productIdentifier == identifier})
        return products?.first
        
    }
    
    @IBAction func donationButtonTapped(_ button: UIButton) {
        if let index = self.donationButtons.index(of: button), let product = self.donationProductForProductIdentifier(self.productStoreController.donationProductIdentifiers[index]) {
            AppDelegate.shared.productStoreController.purchaseProduct(product)
        }
    }
    
}
