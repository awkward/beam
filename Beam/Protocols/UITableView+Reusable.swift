//
//  UITableView+Reusable.swift
//  Coyote
//
//  Created by Antoine van der Lee on 28/04/2017.
//  Copyright © 2017 WeTransfer. All rights reserved.
//

import UIKit

// MARK: Reusable support for UITableView
extension UITableView {

    /// Register a Class-Based `UITableViewCell` or `UITableViewHeaderFooterView` subclass (conforming to `Reusable`)
    ///
    /// - Parameter type: The `Reusable`-conforming subclass to register
    final func register<T>(_ type: T.Type) where T: Reusable {
        switch type {
        case let headerFooter as UITableViewHeaderFooterView.Type:
            register(headerFooter, forHeaderFooterViewReuseIdentifier: type.reuseIdentifier)
        case let cell as UITableViewCell.Type:
            register(cell, forCellReuseIdentifier: type.reuseIdentifier)
        default:
            assertionFailure("Failed to register a type with identifier \(type.reuseIdentifier)")
        }
    }
    
    /// Returns a reusable `UITableViewCell` or `UITableViewHeaderFooterView` object for the class inferred by the return-type.
    ///
    /// - Parameters:
    ///   - type: The class to dequeue.
    ///   - indexPath: The index path specifying the location of the cell. Can be `nil` when dequeueing a header or footer.
    /// - Returns: A `Reusable`, `UITableViewCell` or `UITableViewHeaderFooterView` object.
    final func dequeueReusable<T: Reusable>(_ type: T.Type = T.self, for indexPath: IndexPath? = nil) -> T {
        if let headerFooterType = type as? UITableViewHeaderFooterView.Type, let headerFooter = dequeueReusableHeaderFooterView(withIdentifier: headerFooterType.reuseIdentifier) as? T {
            return headerFooter
        } else if let cellType = type as? UITableViewCell.Type, let indexPath = indexPath, let cell = dequeueReusableCell(withIdentifier: cellType.reuseIdentifier, for: indexPath) as? T {
            return cell
        } else {
            fatalError("Failed to dequeue a type with identifier \(type.reuseIdentifier)")
        }
    }
    
}
