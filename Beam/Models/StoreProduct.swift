//
//  StoreProduct.swift
//  beam
//
//  Created by Robin Speijer on 17-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import StoreKit

struct StoreProductFeature {
    
    var heading: String?
    var subheading: String?
    var iconName: String?
    
    var icon: UIImage? {
        if let iconName = self.iconName {
            return UIImage(named: iconName)
        }
        return nil
    }
    
}

struct StoreProduct: Equatable {
    
    var identifier: String
    
    var iconName: String?
    var icon: UIImage? {
        if let iconName = self.iconName {
            return UIImage(named: iconName)
        }
        return nil
    }
    
    var heading: String?
    var subheading: String?
    var description: String?
    
    var features: [StoreProductFeature]?
    var previews: [StoreProductPreview]?
    
    init(identifier: String) {
        self.identifier = identifier
        
        if let path = Bundle.main.path(forResource: "Products", ofType: "plist"), let productDicts = NSArray(contentsOfFile: path) as? [[String: AnyObject]], let product = productDicts.filter({ ($0[ProductIdentifierKey] as? String) == identifier }).first {

            if let headingKey: String = product[ProductHeadingKey] as? String {
                self.heading = AWKLocalizedString(headingKey)
            }
            
            if let subheadingKey: String = product[ProductSubheadingKey] as? String {
                self.subheading = AWKLocalizedString(subheadingKey)
            }
            
            if let descriptionKey: String = product[ProductDescriptionKey] as? String {
                self.description = AWKLocalizedString(descriptionKey)
            }
            
            self.iconName = product[ProductIconKey] as? String
            
            if let featureDicts = (product[ProductFeaturesKey] as? [[String: AnyObject]]) {
                self.features = [StoreProductFeature]()
                for featureDict in featureDicts {
                    var feature = StoreProductFeature()
                    feature.heading = AWKLocalizedString(featureDict[ProductFeatureHeadingKey] as? String ?? "")
                    feature.subheading = AWKLocalizedString(featureDict[ProductFeatureSubheadingKey] as? String ?? "")
                    feature.iconName = featureDict[ProductFeatureIconKey] as? String
                    self.features?.append(feature)
                }
            }
            
            if let previewDicts = (product[ProductPreviewsKey] as? [[String: AnyObject]]) {
                self.previews = [StoreProductPreview]()
                for (previewIdx, previewDict) in previewDicts.enumerated() {
                    if let imageName = previewDict[ProductPreviewImageKey] as? String {
                        var preview = StoreProductPreview(atIndex: previewIdx, imageName: imageName, product: self)
                        preview.movieURLString = previewDict[ProductPreviewMovieURL] as? String
                        self.previews?.append(preview)
                    }
                }
            }
            
        } else {
            fatalError("Products file could not be found")
        }
    }
    
    var storeObject: SKProduct? {
        return AppDelegate.shared.productStoreController.availableStoreProducts?.filter({ $0.productIdentifier == self.identifier }).first
    }
    
    var isPurchased: Bool {
        return AppDelegate.shared.productStoreController.purchasedProductIdentifiers.contains(self.identifier)
    }
    
    var isOnSale: Bool {
        return AppDelegate.shared.cherryController.features?.sales[self.identifier] != nil
    }
    
    //From 0 to 100
    var discount: Float? {
        if let discount = AppDelegate.shared.cherryController.features?.sales[self.identifier]?.discount {
            return discount
        }
        return nil
    }
    
}

func ==(lhs: StoreProduct, rhs: StoreProduct) -> Bool {
    return lhs.identifier == rhs.identifier
}
