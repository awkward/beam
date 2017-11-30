//
//  Reusable.swift
//  Coyote
//
//  Created by Antoine van der Lee on 14/04/2017.
//  Copyright © 2017 WeTransfer. All rights reserved.
//

import UIKit

typealias ReuseIdentifier = String

/// A protocol defining a reusable view type
protocol Reusable {
    /// Returns default reuseIdentifier for this content type.
    static var reuseIdentifier: ReuseIdentifier { get }
}

extension Reusable {
    static var reuseIdentifier: ReuseIdentifier {
        return String(describing: self)
    }
}
extension UITableViewCell: Reusable { }
extension UICollectionReusableView: Reusable {}
extension UITableViewHeaderFooterView: Reusable { }
