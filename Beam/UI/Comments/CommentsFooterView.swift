//
//  CommentsFooterView.swift
//  Beam
//
//  Created by Rens Verhoeven on 03-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

enum CommentsFooterViewState {
    case loading
    case empty
    
    var text: String {
        switch self {
        case CommentsFooterViewState.loading:
            return AWKLocalizedString("loading-comments")
        case CommentsFooterViewState.empty:
            return AWKLocalizedString("comments-empty-message")
        }
    }
}

class CommentsFooterView: BeamView {

    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var textlabel: UILabel!
    @IBOutlet var textLabelTopToActivityIndicatorViewConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var heightConstraint: NSLayoutConstraint!
    
    var height: CGFloat? {
        didSet {
            if let height = self.height {
                self.heightConstraint.isActive = true
                self.heightConstraint.constant = height - self.layoutMargins.top - self.layoutMargins.bottom
            } else {
                self.heightConstraint.isActive = false
            }
            self.setNeedsLayout()
            self.setNeedsUpdateConstraints()
        }
    }
    
    class func footerView() -> CommentsFooterView {
        return UINib(nibName: "CommentsFooterView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CommentsFooterView
    }
    
    var state = CommentsFooterViewState.loading {
        didSet {
            if state != oldValue {
                if self.textlabel != nil {
                    self.reloadContents()
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadContents()
    }
    
    fileprivate func reloadContents() {
        self.textlabel.text = self.state.text
        if self.state == CommentsFooterViewState.loading {
            self.activityIndicatorView.isHidden = false
            self.activityIndicatorView.startAnimating()
        } else {
            self.activityIndicatorView.isHidden = true
            self.activityIndicatorView.stopAnimating()
        }
        self.setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        self.textLabelTopToActivityIndicatorViewConstraint.isActive = self.state == CommentsFooterViewState.loading
    }

    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.backgroundColor = UIColor.clear
        self.activityIndicatorView.color = self.displayMode == DisplayMode.dark ? UIColor.white: nil
        self.textlabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
    }
    
    func sizeToFitWidth(_ width: CGFloat) {
        var frame = self.frame
        var maxSize = UILayoutFittingCompressedSize
        maxSize.width = width
        frame.size = self.systemLayoutSizeFitting(maxSize, withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultLow)
        self.frame = frame
    }

}
