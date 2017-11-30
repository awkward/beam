//
//  StoreViewController.swift
//  beam
//
//  Created by Robin Speijer on 10-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import StoreKit
import Trekker

class StoreViewController: BeamTableViewController, UIToolbarDelegate {
    
    var showPackSegueIdentifier: String {
        return "show-pack"
    }
    
    var productToShow: StoreProduct?
    
    // MARK: - Lifecycle
    
    lazy var products: [StoreProduct] = {
        AppDelegate.shared.productStoreController.storeProductIdentifiers.map({ StoreProduct(identifier: $0) })
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.isModallyPresentedRootViewController() == false || self.tabBarController != nil {
            self.navigationItem.leftBarButtonItem = nil
        }
        
        self.navigationItem.title = NSLocalizedString("store-view-title", comment: "The title at the top of the store view")
        self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("restore-button", comment: "The restore purchases button on the store view")
        
        NotificationCenter.default.addObserver(self, selector: #selector(StoreViewController.productsDidChange(_:)), name: .ProductStoreControllerAvailableProductsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StoreViewController.transactionUpdated(_:)), name: .ProductStoreControllerTransactionUpdated, object: nil)
        self.purchasingEnabled = SKPaymentQueue.default().transactions.count == 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.presentedViewController == nil  {
            Trekker.default.track(event: TrekkerEvent(event: "View store"))
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var purchasingEnabled: Bool = false {
        didSet {
            self.navigationItem.rightBarButtonItem?.isEnabled = purchasingEnabled
        }
    }
    
    var restoreTapped: Bool = false
    
    // MARK: - Layout
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.view.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkBackgroundColor())
        self.tableView.indicatorStyle = DisplayModeValue(.black, darkValue: .white)
    }
    
    // MARK: - Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let product = self.productToShow, let productView = segue.destination as? ProductViewController {
            productView.product = product
        }
    }
    
    @objc fileprivate func productsDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.tableView?.reloadData()
        }
    }
    
    @objc fileprivate func transactionUpdated(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.tableView?.reloadData()
            if let transaction = notification.object as? SKPaymentTransaction , self.restoreTapped {
                self.restoreTapped = false
                if transaction.transactionState == SKPaymentTransactionState.restored {
                    let alertController = BeamAlertController(title: AWKLocalizedString("transactions-restored"), message: AWKLocalizedString("transactions-restored-message"), preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addCloseAction()
                    self.present(alertController, animated: true, completion: nil)
                }
               
            }
        }
    }

    @IBAction func restoreButtonTapped(_ sender: AnyObject) {
        self.restoreTapped = true
        AppDelegate.shared.productStoreController.restorePurchases()
    }
    
    @IBAction func viewButtonTapped(_ sender: UIButton) {
        let product = self.products[sender.tag]
        if product.storeObject != nil {
            if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {
                if let productViewController = self.storyboard?.instantiateViewController(withIdentifier: "productView") as? ProductViewController {
                    let navigationController = BeamNavigationController(rootViewController: productViewController)
                    
                    productViewController.product = product
                    
                    self.show(navigationController, sender: sender)
                }
            } else {
                self.productToShow = product
                self.performSegue(withIdentifier: self.showPackSegueIdentifier, sender: self)
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func unwindToStore(_ segue: UIStoryboardSegue) {
        
    }

}

// MARK: - UITableViewDataSource
extension StoreViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "product", for: indexPath) as! ProductTableViewCell
        cell.product = self.products[(indexPath as IndexPath).row]
        // When the button is tapped, we don't have context about the cell, indexpath or product. Therefore use tag to define the product index
        cell.viewButton.tag = (indexPath as IndexPath).row
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension StoreViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = self.products[(indexPath as IndexPath).row]
        if product.storeObject != nil {
            if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {
                if let productViewController = self.storyboard?.instantiateViewController(withIdentifier: "productView") as? ProductViewController {
                    let navigationController = BeamNavigationController(rootViewController: productViewController)
                    
                    productViewController.product = product
                    
                    self.show(navigationController, sender: indexPath)
                }
            } else {
                self.productToShow = product
                self.performSegue(withIdentifier: self.showPackSegueIdentifier, sender: self)
            }
        }
    }
    
}

extension StoreViewController: BeamModalPresentation {
    
    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
    
}
