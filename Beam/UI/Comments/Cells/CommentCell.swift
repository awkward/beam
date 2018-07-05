//
//  CommentCell.swift
//  beam
//
//  Created by Robin Speijer on 03-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import RedditMarkdownKit
import TTTAttributedLabel
import Trekker

/**
 DeadZonesScrollView is a subclass of UIScrollView that supports "dead zones".
 These dead zones are places where the user can't start scrolling.
 If the initial touch of a scroll is in one of these dead zones, the scrolling doesn't start.
 */
class DeadZonesScrollView: UIScrollView {
    
    /**
     The deadzones in the UIScrollView. These are relative to the normal bounds of the scrollView
     If the initial touch of a scroll is in one of these rects, the scrolling doesn't start.
    */
    var deadZones: [CGRect]?
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var point = gestureRecognizer.location(in: self)
        //The point will be relative to the bounds of the UISrollView. However we want to use is it relative to the frame of the UIScrollView
        point.x -= contentOffset.x
        point.y -= contentOffset.y
        if let deadZones = self.deadZones {
            for zone in deadZones {
                if zone.contains(point) {
                    return false
                }
            }
            
        }
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

enum CommentCellAction {
    case none
    case reply
    case more
    case downvote
    case upvote
    
    func backgroundColor() -> UIColor {
        switch self {
        case CommentCellAction.none:
            return DisplayModeValue(UIColor.groupTableViewBackground, darkValue: UIColor.beamDarkBackgroundColor())
        case CommentCellAction.reply:
            return UIColor.beamYellow()
        case CommentCellAction.more:
            return UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1)
        case CommentCellAction.downvote:
            return UIColor.beamBlue()
        case CommentCellAction.upvote:
            return UIColor.beamRed()
        }
    }
    
    func icon() -> UIImage? {
        switch self {
        case CommentCellAction.none:
            return nil
        case CommentCellAction.reply:
            return UIImage(named: "comment_action_reply")
        case CommentCellAction.more:
            return UIImage(named: "comment_action_more")
        case CommentCellAction.downvote:
            return UIImage(named: "comment_action_downvote")
        case CommentCellAction.upvote:
            return UIImage(named: "comment_action_upvote")
        }
    }
}

class CommentCell: BaseCommentCell {
    
    @IBOutlet fileprivate weak var collapseIconImageView: UIImageView!
    
    @IBOutlet fileprivate weak var authorButton: BeamPlainButton!
    @IBOutlet weak var contentLabel: TTTAttributedLabel!
    @IBOutlet fileprivate weak var metadataLabel: UILabel!
    @IBOutlet fileprivate weak var flairLabel: UILabel!
    
    @IBOutlet fileprivate weak var gildCountSeperatorView: PostMetdataSeperatorView!
    @IBOutlet fileprivate weak var flairLabelSeperatorView: PostMetdataSeperatorView!
    
    @IBOutlet fileprivate var gildCountView: GildCountView!
    
    @IBOutlet fileprivate var commentContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var commentContentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var stackViewToCollapseArrowConstraint: NSLayoutConstraint!
    //The constraint from the comment's content (text) to the link preview button below it.
    @IBOutlet fileprivate var contentToCommentLinkPreviewConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate var scrollView: DeadZonesScrollView!
    
    @IBOutlet fileprivate var leftIconImageView: UIImageView!
    @IBOutlet fileprivate var rightIconImageView: UIImageView!
    
    @IBOutlet var commentLinkPreview: CommentLinkPreviewView!
    
    weak var delegate: CommentCellDelegate?
    
    var allowsSwipeActions = true {
        didSet {
            self.scrollView.isScrollEnabled = self.allowsSwipeActions
        }
    }
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommentCell.handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.require(toFail: self.longPressGestureRecognizer)
        return tapGestureRecognizer
    }()
    
    lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(CommentCell.handleLongPressGesture(_:)))
        longPressGestureRecognizer.delegate = self
        longPressGestureRecognizer.minimumPressDuration = 0.3
        return longPressGestureRecognizer
    }()
    
    //This property is true when the comment on the cell has changed during the setting, use this property to optimize performance by not changing content that has changed
    
    override func reloadContents() {
        super.reloadContents()
        
        if self.comment?.hasBeenDeleted == true || self.isCollapsed == true {
            self.scrollView.isScrollEnabled = false
        } else {
            self.scrollView.isScrollEnabled = self.allowsSwipeActions
        }
        
        self.collapseIconImageView.isHidden = !self.isCollapsed
        if self.commentDidChange || self.comment?.hasBeenDeleted == true {
            self.authorButton.setTitle(self.comment?.author, for: UIControlState.normal)
        }
        
        if self.commentDidChange || self.comment?.hasBeenDeleted == true {
            self.flairLabel.text = self.comment?.authorFlairText
        }
        self.flairLabelSeperatorView.isHidden = (self.comment?.authorFlairText?.count ?? 0) <= 0
        self.flairLabel.isHidden = (self.comment?.authorFlairText?.count ?? 0) <= 0
        self.gildCountSeperatorView.isHidden = (self.comment?.gildCount?.intValue ?? 0) <= 0
        self.gildCountView.isHidden = (self.comment?.gildCount?.intValue ?? 0) <= 0
        
        self.stackViewToCollapseArrowConstraint.isActive = self.isCollapsed
        
        self.reloadAuthorTextColor()
        self.reloadMetaData()
        
        self.displayModeDidChange()
        
        let links = self.contentLabel.linksWithSchemes(schemes: ["http", "https"])
        
        let showsLinkPreview = links.count > 0 && !self.isCollapsed
        
        self.contentToCommentLinkPreviewConstraint.isActive = showsLinkPreview
        self.commentLinkPreview.isHidden = !showsLinkPreview
        if showsLinkPreview {
            self.commentLinkPreview.comment = self.comment
            self.commentLinkPreview.link = links.first
        }
        
        self.contentLabel.isHidden = self.isCollapsed
        
        self.commentDidChange = false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.scrollView.scrollsToTop = false
        self.scrollView.isPagingEnabled = true
        self.scrollView.addGestureRecognizer(self.tapGestureRecognizer)
        self.scrollView.addGestureRecognizer(self.longPressGestureRecognizer)
        
        self.gildCountView.font = UIFont.systemFont(ofSize: 12)
        
        self.leftIconImageView.tintColor = UIColor.white
        self.rightIconImageView.tintColor = UIColor.white
        
        self.setNeedsUpdateConstraints()
    }
    
    fileprivate var contentStylesheet: MarkdownStylesheet {
        return MarkdownStylesheet.beamCommentsStyleSheet(self.displayMode == .dark)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        self.commentContentViewLeadingConstraint.constant = self.contentView.bounds.width
        self.commentContentViewTrailingConstraint.constant = self.contentView.bounds.width
        self.resetScrollViewOffset()
    }
    
    func resetScrollViewOffset() {
        self.scrollView.contentSize = CGSize(width: self.contentView.bounds.width * 3, height: self.contentView.bounds.height)
        self.scrollView.contentOffset = CGPoint(x: self.contentView.bounds.width, y: 0)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let alphaValue: CGFloat = self.isCollapsed ? 0.5: 1.0
        self.gildCountView.alpha = alphaValue
        self.authorButton.alpha = alphaValue
        self.metadataLabel.alpha = alphaValue
        self.flairLabel.alpha = alphaValue
        self.gildCountSeperatorView.alpha = alphaValue
        self.flairLabelSeperatorView.alpha = alphaValue
        
        let imageTintColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.3)
        if imageTintColor != self.collapseIconImageView.tintColor {
            self.collapseIconImageView.tintColor = imageTintColor
        }
        
        self.gildCountView.backgroundColor = self.contentView.backgroundColor
        self.gildCountView.isOpaque = true
        
        self.contentLabel.backgroundColor = self.contentView.backgroundColor
        self.contentLabel.isOpaque = true
        
        self.authorButton.backgroundColor = self.contentView.backgroundColor
        self.authorButton.isOpaque = true
        
        self.metadataLabel.backgroundColor = self.contentView.backgroundColor
        self.metadataLabel.isOpaque = true
        
        self.flairLabel.textColor = UIColor(red: 0.52941, green: 0.62745, blue: 1.00000, alpha: 1.00000)
        self.flairLabel.backgroundColor = self.contentView.backgroundColor
        self.flairLabel.isOpaque = true
        
        self.reloadAuthorTextColor()
        self.reloadMetaData()
        
        if self.isCollapsed == false {
            self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesForMode(self.displayMode)
            self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesForMode(self.displayMode)
            if let comment = comment, let contentString = comment.content {
                if comment.markdownString == nil {
                    comment.markdownString = MarkdownString(string: contentString.stringByTrimmingTrailingWhitespacesAndNewLines())
                }
                self.contentLabel.setText(comment.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
            } else {
                self.contentLabel.attributedText = nil
            }
        }
    }
    
    /// Cancels the long press gesture in case it's not wanted
    func cancelLongPress() {
        self.longPressGestureRecognizer.isEnabled = false
        longPressGestureRecognizer.isEnabled = true
    }
    
    func reloadMetaData() {
        guard self.comment?.hasBeenDeleted == false else {
            self.metadataLabel.text = nil
            return
        }
        var textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        var pointsTextColor = textColor
        
        if VoteStatus(rawValue: self.comment?.voteStatus?.intValue ?? 0) == .up {
            pointsTextColor = UIColor.beamRed()
        } else if VoteStatus(rawValue: self.comment?.voteStatus?.intValue ?? 0) == .down {
            pointsTextColor = UIColor.beamBlue()
        }
        
        if self.displayMode == .dark {
            textColor = UIColor(red: 158 / 255, green: 156 / 255, blue: 166 / 255, alpha: 1.0)
        }
        
        if self.isCollapsed {
            //When isCollapsed, the points text color is the same as the other meta data
            pointsTextColor = textColor
        }
        
        var metadata = [NSAttributedString]()
        if let comment = comment {
            if comment.scoreHidden == true {
                metadata.append(NSAttributedString(string: AWKLocalizedString("score-hidden-block"), attributes: [NSAttributedStringKey.foregroundColor: pointsTextColor]))
            } else if let score = self.comment?.score {
                var localizedPoints = NSLocalizedString("points-inline", comment: "")
                if score.intValue == 1 || score.intValue == -1 {
                    localizedPoints = NSLocalizedString("point-inline", comment: "")
                }
                    
                metadata.append(NSAttributedString(string: "\(score.intValue) \(localizedPoints)", attributes: [NSAttributedStringKey.foregroundColor: pointsTextColor]))
            }
            
            if let timeString = comment.creationDate?.localizedRelativeTimeString {
                metadata.append(NSAttributedString(string: timeString, attributes: [NSAttributedStringKey.foregroundColor: textColor]))
            }
            
            //Add the gilded status to the comment
            
            if let gildCount = comment.gildCount?.intValue, gildCount > 0 {
                self.gildCountView.count = gildCount
                self.gildCountView.isHidden = false
            } else {
                self.gildCountView.isHidden = true
            }
        }
        let attributedString = NSMutableAttributedString()
        for meta in metadata {
            attributedString.append(meta)
            if let index = metadata.index(of: meta), index < metadata.count - 1 {
                attributedString.append(NSAttributedString(string: NSLocalizedString("list-separator", comment: "separated items by a comma: ', '"), attributes: [NSAttributedStringKey.foregroundColor: textColor]))
            }
        }
        self.metadataLabel.attributedText = attributedString
    }
    
    fileprivate func reloadAuthorTextColor() {
        let authorIsOriginalPoster = (comment?.author == comment?.post?.author)
        var titleColor = DisplayModeValue(UIColor(red: 12 / 255, green: 11 / 255, blue: 13 / 255, alpha: 1), darkValue: UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1.0))
        if authorIsOriginalPoster && !self.isCollapsed {
            titleColor = UIColor(red: 0.18823, green: 0.56471, blue: 0.97647, alpha: 1.00000)
        }
        self.authorButton.setTitleColor(titleColor, for: UIControlState())
    }
    
    @IBAction fileprivate func usernameButtonTapped(_ sender: AnyObject) {
        if let comment = self.comment {
            self.delegate?.commentCell(self, didTapUsernameOnComment: comment)
        }
    }
    
    @IBAction fileprivate func linkPreviewTapped(sender: UIControl) {
        guard let comment = self.comment, let link = self.commentLinkPreview.link else {
            return
        }
        if let mediaObjects = comment.mediaObjects?.array as? [MediaObject], mediaObjects.count > 0 {
            self.delegate?.commentCell(self, didTapImagePreview: comment, mediaObjects: mediaObjects)
        } else {
            self.delegate?.commentCell(self, didTapLinkPreview: comment, url: link)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsUpdateConstraints()
        self.resetScrollViewOffset()
        
        let deadZone = CGRect(x: 0, y: 0, width: 50, height: self.bounds.height)
        self.scrollView.deadZones = [deadZone]
    }
    
    func performScrollActionAtOffset(_ contentOffset: CGPoint) {
        if let comment = self.comment {
            let action = self.actionForContentOffset(contentOffset)
            switch action {
            case CommentCellAction.upvote:
                self.delegate?.commentCell(self, didSelectUpvoteOnComment: comment)
            case CommentCellAction.downvote:
                self.delegate?.commentCell(self, didSelectDownvoteOnComment: comment)
            case CommentCellAction.more:
                self.delegate?.commentCell(self, didSelectMoreOnComment: comment)
            case CommentCellAction.reply:
                self.delegate?.commentCell(self, didSelectReplyOnComment: comment)
            default:
                break
            }
        }
        
    }
    
    func actionForContentOffset(_ contentOffset: CGPoint) -> CommentCellAction {
        let offset = contentOffset.x - self.bounds.width
        let minimumOffset: CGFloat = 50
        let actionWidth: CGFloat = 150
        if offset > 0 {
            //The user is swiping from the right side
            if offset <= minimumOffset {
                return CommentCellAction.none
            } else if offset <= actionWidth {
                return CommentCellAction.upvote
            } else {
                return CommentCellAction.downvote
            }
        } else {
            //The user is swiping from the left side. The number will be negative so make it positive
            let positiveOffset = offset * CGFloat(-1)
            
            if positiveOffset <= minimumOffset {
                return CommentCellAction.none
            } else if positiveOffset <= actionWidth {
                return CommentCellAction.reply
            } else {
                return CommentCellAction.more
            }
        }
    }
    
    func link(at point: CGPoint) -> URL? {
        let point = self.contentView.convert(point, to: self.contentLabel)
        let link = self.contentLabel.link(at: point)
        return link?.result.url
    }
    
    @objc func handleTapGesture(_ tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer.state == UIGestureRecognizerState.ended {
            if let comment = self.comment {
                self.delegate?.commentCell(self, didTapComment: comment)
            }
            
        }
    }
    
    @objc func handleLongPressGesture(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            if let comment = self.comment {
                self.delegate?.commentCell(self, didHoldOnComment: comment)
            }
        }
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == self.tapGestureRecognizer || gestureRecognizer == self.longPressGestureRecognizer {
            if touch.view is TTTAttributedLabel && touch.view == self.contentLabel {
                let point = touch.location(in: self.contentLabel)
                if self.contentLabel.containslink(at: point) {
                    self.contentLabel.touchesBegan(Set([touch]), with: nil)
                    return false
                }
            }
            return !(touch.view is UIControl)
        }
        return true
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer || otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        return true
    }
}

extension CommentCell: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.scrollView.isDragging {
            let action = self.actionForContentOffset(scrollView.contentOffset)
            let animationDuration: Double = 0.15
            
            var imageView: UIImageView!
            if action == CommentCellAction.reply || action == CommentCellAction.more {
                imageView = self.leftIconImageView
            } else {
                imageView = self.rightIconImageView
            }
            imageView.image = action.icon()
        
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                self.scrollView.backgroundColor = action.backgroundColor()
                if action == CommentCellAction.none {
                    self.leftIconImageView.alpha = 0
                    self.rightIconImageView.alpha = 0
                } else {
                    imageView.alpha = 1
                }
            })
            
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.performScrollActionAtOffset(scrollView.contentOffset)
        targetContentOffset.pointee.x = self.bounds.width
        targetContentOffset.pointee.y = 0
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollView.backgroundColor = DisplayModeValue(UIColor.groupTableViewBackground, darkValue: UIColor.beamDarkBackgroundColor())
        self.leftIconImageView.alpha = 0
        self.rightIconImageView.alpha = 0
    }
    
}
