//
//  UICollectionView+Reusable.swift
//  Coyote
//
//  Created by Antoine van der Lee on 28/04/2017.
//  Copyright © 2017 WeTransfer. All rights reserved.
//

import UIKit

// MARK: Reusable support for UICollectionView

extension UICollectionView {
    
    /// Register a Class-Based `UICollectionReusableView` subclass (conforming to `Reusable`).
    ///
    /// - Parameter type: The `Reusable`-conforming subclass to register.
    /// - Parameter kind: The elementKind when registering a supplementary view.
    final func register<T>(_ type: T.Type, ofKind elementKind: String? = nil) where T: Reusable {
        if let cellType = type as? UICollectionViewCell.Type {
            register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
        } else if let supplementaryViewType = type as? UICollectionReusableView.Type, let elementKind = elementKind {
            register(supplementaryViewType, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: supplementaryViewType.reuseIdentifier)
        } else {
            assertionFailure("Failed to register a type with identifier \(type.reuseIdentifier)")
        }
    }
    
    /// Returns a reusable `UICollectionReusableView` object for the class inferred by the return-type.
    ///
    /// - Parameters:
    ///   - type: The class to dequeue.
    ///   - indexPath: The index path specifying the location of the cell.
    ///   - elementKind: The kind of supplementary view to retrieve. Can be `nil` and should only be passed for supplementary views.
    /// - Returns: A `Reusable`, `UICollectionReusableView` instance.
    final func dequeueReusable<T: UICollectionReusableView>(_ type: T.Type = T.self, for indexPath: IndexPath, ofKind elementKind: String? = nil) -> T {
        if  let cellType = type as? UICollectionViewCell.Type,
            let cell = dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier, for: indexPath) as? T {
                return cell
        } else if
            let elementKind = elementKind,
            let supplementaryView = dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: type.reuseIdentifier, for: indexPath) as? T {
                return supplementaryView
        } else {
            fatalError("Failed to dequeue a type with identifier \(type.reuseIdentifier)")
        }
    }
    
}
