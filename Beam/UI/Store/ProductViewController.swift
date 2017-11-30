//
//  ProductViewController.swift
//  beam
//
//  Created by Robin Speijer on 17-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import StoreKit
import Trekker
import AWKGallery

class ProductViewController: BeamViewController {
    
    
    /// The maximum height of the preview of a product (screenshot). This is to retain quality. 
    /// The Height is normally calculated based on the screen size
    static let MaxPreviewHeight: CGFloat = 380
    
    var product: StoreProduct? {
        didSet {
            self.storeObject = product?.storeObject
            self.reloadContent()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = NumberFormatter.Behavior.behavior10_4
        formatter.numberStyle = NumberFormatter.Style.currency
        return formatter
    }()
    
    var purchaseButtonTitle: String? {
        var attributedTitle = AWKLocalizedString("purchase").uppercased(with: Locale.current)
        if self.product?.isPurchased == true {
            attributedTitle = AWKLocalizedString("purchased").uppercased(with: Locale.current)
        } else {
            self.priceFormatter.locale = self.product?.storeObject?.priceLocale ?? Locale.current
            let price = self.storeObject?.price ?? NSNumber(value: 0 as Double)
            if let priceString = self.priceFormatter.string(from: price) {
                var title = self.product?.isOnSale == true ? AWKLocalizedString("purchase-product-sale") : AWKLocalizedString("purchase-product")
                if price.floatValue <= 0 {
                    title = self.product?.isOnSale == true ? AWKLocalizedString("purchase-product-free-limited-time") : AWKLocalizedString("purchase-product-free")
                }
                title = title.replacingLocalizablePlaceholders(for: ["PRICE": priceString])
                attributedTitle = title.uppercased(with: Locale.current) as String
            }
        }
        return attributedTitle
    }
    
    fileprivate var storeObject: SKProduct?

    @IBOutlet fileprivate var tableView: UITableView!
    @IBOutlet fileprivate var purchaseButton: BeamButton!
    
    fileprivate var purchasingEnabled: Bool = false {
        didSet {
            self.reloadContent()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.purchasingEnabled = SKPaymentQueue.default().transactions.count == 0
        NotificationCenter.default.addObserver(self, selector: #selector(ProductViewController.transactionChanged(_:)), name: .ProductStoreControllerTransactionUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ProductViewController.trialsChanged(_:)), name: .ProductStoreControllerTrialsChanged, object: nil)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 117
        
        self.reloadContent()
        
        self.purchaseButton.layer.cornerRadius = 0
    }
    
    deinit {
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isModallyPresentedRootViewController() {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "navigationbar_close"), style: .plain, target: self, action: #selector(dismissViewController(_:)))
        }
        
        if self.presentedViewController == nil  {
            if let productIdentifier = self.product?.storeObject?.productIdentifier {
                Trekker.default.track(event: TrekkerEvent(event: "View store product", properties: ["Product type": productIdentifier]))
            } else {
                Trekker.default.track(event: TrekkerEvent(event: "View store product"))
            }
            
        }
        
        self.reloadContent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    fileprivate func reloadContent() {
        self.title = self.storeObject?.localizedTitle
        self.tableView?.reloadData()
        self.purchaseButton?.setTitle(self.purchaseButtonTitle, for: UIControlState())
        self.purchaseButton?.isEnabled = self.product?.isPurchased != true
        self.purchaseButton?.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold)
        
        let trialsAvailable = self.product?.isTrialAvailable
        
        if trialsAvailable == true && self.product?.hasTrialStarted == false {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("get-free-trial-button-item", comment: "The trial button in the top bar"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(ProductViewController.trialButtonTapped(_:)))
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.displayModeDidChange()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let product = self.product, let startTrialView = segue.destination as? StartTrialViewController{
            startTrialView.storeProduct = product
        }
    }
    
    @IBAction func purchaseButtonTapped(_ sender: AnyObject) {
        BeamSoundType.tap.play()
        if AppDelegate.shared.cherryController.isAdminUser {
            let alert = BeamAlertController(title: AWKLocalizedString("admin-purchase-title"), message: AWKLocalizedString("admin-purchase-message"), preferredStyle: UIAlertControllerStyle.alert)
            alert.addCancelAction()
            alert.addAction(UIAlertAction(title: AWKLocalizedString("restore"), style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
                AppDelegate.shared.productStoreController.restoreAdminProducts()
            }))
            self.present(alert, animated: true, completion: nil)
        } else if let product = self.product?.storeObject , !AppDelegate.shared.productStoreController.purchasedProductIdentifiers.contains(product.productIdentifier) {
            AppDelegate.shared.productStoreController.purchaseProduct(product)
        }
    }
    
    @IBAction func trialButtonTapped(_ sender: AnyObject) {
        if AppDelegate.shared.cherryController.accessToken != nil && self.product?.isTrialAvailable == true {
            self.performSegue(withIdentifier: "showStartTrial", sender: nil)
        }
    }
    
    @objc fileprivate func transactionChanged(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.purchasingEnabled = SKPaymentQueue.default().transactions.count == 0
        }
    }
    
    @objc fileprivate func trialsChanged(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.reloadContent()
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.tableView.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkBackgroundColor())
        self.tableView.separatorColor = DisplayModeValue(UIColor.beamSeparator(), darkValue: UIColor.beamDarkTableViewSeperatorColor())
        self.purchaseButton.setTitleColor(DisplayModeValue(UIColor.white, darkValue: UIColor.white), for: UIControlState())
        
        if self.product?.isOnSale == true {
            self.purchaseButton.backgroundColor = UIColor(red: 208/255, green: 46/255, blue: 56/255, alpha: 1)
        }
        
        self.tableView.tableFooterView?.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.tableView.tableHeaderView?.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
    }

}

extension ProductViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard self.product != nil else {
            return 0
        }
        guard let features: [StoreProductFeature] = self.product?.features , features.count > 0 else {
            return 2
        }
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            guard let features: [StoreProductFeature] = self.product?.features , features.count > 0 else {
                return 0
            }
            return features.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as IndexPath).section == 0 {
            //Intro
            let cell: ProductDetailIntroTableViewCell = tableView.dequeueReusableCell(withIdentifier: "intro", for: indexPath) as! ProductDetailIntroTableViewCell
            cell.product = self.product
            return cell
        } else if (indexPath as IndexPath).section == 1 {
            //Previews
            let cell: ProductDetailPreviewsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "preview", for: indexPath) as! ProductDetailPreviewsTableViewCell
            cell.delegate = self
            cell.product = self.product
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "feature") as! ProductFeatureTableViewCell
            cell.feature = self.product?.features?[(indexPath as IndexPath).row]
            return cell
        }
    }
    
}

extension ProductViewController: UITableViewDelegate {
    
    private func previewHeight() -> CGFloat {
        var scaleFactor: CGFloat = UIScreen.main.bounds.height / UIScreen.main.bounds.width
        if let previewImage = self.product?.previews?.first?.image {
            scaleFactor = previewImage.size.height / previewImage.size.width
        }
        return min(((self.tableView.frame.width-50) * scaleFactor) + 20, ProductViewController.MaxPreviewHeight)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as IndexPath).section == 1 {
            return self.previewHeight()
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        //Returning the actual height for hte previews (since we can already calculate it). Will improve the scrolling
        if indexPath.section == 1 {
            return self.previewHeight()
        } else {
            return 300
        }
    }
    
}

extension ProductViewController: ProductDetailPreviewsTableViewCellDelegate {
    
    func previewsTableViewCell(_ cell: ProductDetailPreviewsTableViewCell, didTapPreview preview: StoreProductPreview) {
        let galleryItem = StoreProductPreviewGalleryItem(sourceItem: preview)
        let gallery = AWKGalleryViewController()
        gallery.dataSource = self
        gallery.delegate = self
        gallery.displaysNavigationItemCount = true
        gallery.currentItem = galleryItem
        gallery.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_arrow_back"), style: UIBarButtonItemStyle.plain, target: gallery, action: #selector(AWKGalleryViewController.dismissGallery(_:)))

        self.presentGalleryViewController(gallery, sourceView: self.imageViewForGalleryItem(galleryItem))
    }
    
}

extension ProductViewController: AWKGalleryDataSource {
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        return self.product?.previews?.count ?? 0
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        if let preview = self.product?.previews?[Int(index)] {
            return StoreProductPreviewGalleryItem(sourceItem: preview)
        }
        fatalError()
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        if let item = item as? StoreProductPreviewGalleryItem, let previews = self.product?.previews {
            return previews.index(of: item.sourceItem) ?? 0
        }
        fatalError()
    }
    
}

extension ProductViewController: AWKGalleryDelegate {
    
    fileprivate var previewsCollectionView: UICollectionView? {
        guard let cell: ProductDetailPreviewsTableViewCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? ProductDetailPreviewsTableViewCell else {
            return nil
        }
        return cell.collectionView
    }
    
    func imageViewForGalleryItem(_ item: AWKGalleryItem) -> UIImageView? {
        if let item = item as? StoreProductPreviewGalleryItem, let cell = self.previewsCollectionView?.cellForItem(at: IndexPath(item: item.sourceItem.index, section: 0)) as? ProductPreviewCollectionViewCell {
            return cell.imageView
        }
        return nil
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, didScrollFrom item: AWKGalleryItem) {
        if let oldImageView = self.imageViewForGalleryItem(item) {
            oldImageView.isHidden = false
        }
        
        if let newItem = galleryViewController.currentItem as? StoreProductPreviewGalleryItem {
            self.previewsCollectionView?.scrollToItem(at: IndexPath(item: newItem.sourceItem.index, section: 0), at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
            
            if let newImageView = self.imageViewForGalleryItem(newItem) {
                newImageView.isHidden = true
            }
        }
        
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, presentationAnimationSourceViewFor item: AWKGalleryItem) -> UIView? {
        return self.imageViewForGalleryItem(item)
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, shouldBeDismissedAnimated animated: Bool) {
        if let newItem = galleryViewController.currentItem  {
            let sourceView: UIView? = self.imageViewForGalleryItem(newItem)
            self.dismissGalleryViewController(galleryViewController, sourceView: sourceView)
        }
        
    }
    
}

extension ProductViewController: BeamModalPresentation {

    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }

}

