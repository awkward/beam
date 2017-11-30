//
//  ProductDetailPreviewsTableViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 26-08-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import UPCarouselFlowLayout

protocol ProductDetailPreviewsTableViewCellDelegate: class {
    
    func previewsTableViewCell(_ cell: ProductDetailPreviewsTableViewCell, didTapPreview preview: StoreProductPreview)
    
}

class ProductDetailPreviewsTableViewCell: BeamTableViewCell {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet fileprivate var pageControl: UIPageControl!

    weak var delegate: ProductDetailPreviewsTableViewCellDelegate?
    
    fileprivate var carouselLayout: UPCarouselFlowLayout {
        return self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
    }
    
    var product: StoreProduct? {
        didSet {
            self.previews = product?.previews
        }
    }
    
    fileprivate var previews: [StoreProductPreview]? {
        didSet {
            self.collectionView.reloadData()
            self.pageControl.numberOfPages = previews?.count ?? 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.collectionView.collectionViewLayout = UPCarouselFlowLayout()
        
        self.carouselLayout.scrollDirection = .horizontal
        self.carouselLayout.sideItemScale = 1.0
        self.carouselLayout.sideItemAlpha = 1.0
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let pageControlHeight: CGFloat = 37
        
        let height: CGFloat = min(self.collectionView.bounds.height, ProductViewController.MaxPreviewHeight-pageControlHeight)
       
        var screenRatio = UIScreen.main.bounds.height / UIScreen.main.bounds.width
        if let previewImage = self.previews?.first?.image {
            screenRatio = previewImage.size.height / previewImage.size.width
        }
        self.carouselLayout.itemSize = CGSize(width: height / screenRatio, height: height)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.collectionView.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.contentView.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
    }
    
}

extension ProductDetailPreviewsTableViewCell: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let centerPoint = CGPoint(x: self.collectionView.center.x + self.collectionView.contentOffset.x, y: self.collectionView.center.y + self.collectionView.contentOffset.y)
        if let indexPath =  self.collectionView.indexPathForItem(at: centerPoint) {
            self.pageControl.currentPage = indexPath.item
        }
    }
    
}

extension ProductDetailPreviewsTableViewCell: UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let preview: StoreProductPreview = self.previews?[(indexPath as IndexPath).item] {
            self.delegate?.previewsTableViewCell(self, didTapPreview: preview)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
}

extension ProductDetailPreviewsTableViewCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let previews: [StoreProductPreview] = self.previews else {
            return 0
        }
        return previews.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "preview", for: indexPath) as! ProductPreviewCollectionViewCell
        cell.productPreview = self.previews?[(indexPath as IndexPath).item]
        return cell
    }
    
}
