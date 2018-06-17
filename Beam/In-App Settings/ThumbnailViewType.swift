//
//  ThumbnailViewType.swift
//  Beam
//
//  Created by Rens Verhoeven on 08/02/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

public enum ThumbnailsViewType: String {
    case large
    case medium
    case small
    case none
    
    public func headerSpacingHeight(atIndex index: Int) -> CGFloat {
        switch self {
        case ThumbnailsViewType.small, ThumbnailsViewType.none:
            if index == 0 {
                return 7
            }
            // Returning 0 as the header height doesn't work for UITableView, so we return the number the closest to 0 that UITableView still appects
            return 0.0000000000000000001
        default:
            if index == 0 {
                return 14
            }
            return 7
        }
    }
    
    public func footerSpacingHeight(atIndex index: Int) -> CGFloat {
        switch self {
        case ThumbnailsViewType.small, ThumbnailsViewType.none:
            // Returning 0 as the header height doesn't work for UITableView, so we return the number the closest to 0 that UITableView still appects
            return 0.0000000000000000001
        default:
            return 7
        }
    }
    
    public var showsToolbarSeperator: Bool {
        switch self {
        case ThumbnailsViewType.small, ThumbnailsViewType.none:
            return false
        default:
            return true
        }
    }
    
    public var showsDomain: Bool {
        switch self {
        case ThumbnailsViewType.small, ThumbnailsViewType.none:
            return true
        default:
            return false
        }
    }
    
    public var needsCommentSpacing: Bool {
        switch self {
        case ThumbnailsViewType.small, ThumbnailsViewType.none:
            return true
        default:
            return false
        }
    }
}
