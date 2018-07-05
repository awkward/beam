//
//  PostMetadataView.swift
//  beam
//
//  Created by Rens Verhoeven on 15-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import AWKGallery

protocol PostMetadataViewDelegate: class {
    
    func postMetdataView(_ metadataView: PostMetadataView, didTapUsernameOnPost post: Post)
    func postMetdataView(_ metadataView: PostMetadataView, didTapSubredditOnPost post: Post)
}

@IBDesignable
class PostMetdataSeperatorView: BeamView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isOpaque = true
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        let fillColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        fillColor.setFill()
        path.fill()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //Workaround for a bug where draw rect is not called on frame changes
        self.setNeedsDisplay()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 2, height: 2)
    }

}

class PostMetadataGildedView: BeamView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.addSubview(self.iconImageView)
        self.addSubview(self.textlabel)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.textlabel.textColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        self.iconImageView.tintColor = DisplayModeValue(UIColor(red: 250 / 255, green: 212 / 255, blue: 25 / 255, alpha: 1.0), darkValue: UIColor(red: 170 / 255, green: 147 / 255, blue: 35 / 255, alpha: 1.0))
    }
    
    var count: Int = 0 {
        didSet {
            self.textlabel.text = self.text()
            
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
    var font: UIFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular) {
        didSet {
            self.textlabel.font = self.font
            
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
    fileprivate let spacing: CGFloat = 4.0
    
    fileprivate let textlabel = UILabel()
    fileprivate let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "gilded_star"))
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()
    
    func text() -> String {
        return "×\(self.count)"
    }
    
    override var intrinsicContentSize: CGSize {
        let labelSize = self.textlabel.intrinsicContentSize
        let iconSize = self.iconImageView.intrinsicContentSize
        
        var height = iconSize.height
        if labelSize.height > height {
            height = labelSize.height
        }
        let width = iconSize.width + self.spacing + labelSize.width
        return CGSize(width: ceil(width), height: ceil(height))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let labelSize = self.textlabel.intrinsicContentSize
        let iconSize = self.iconImageView.intrinsicContentSize
        
        var xPosition: CGFloat = 0
        
        let iconFrame = CGRect(origin: CGPoint(x: xPosition, y: self.bounds.midY - (iconSize.height / 2)), size: iconSize)
        self.iconImageView.frame = iconFrame
        
        xPosition += iconSize.width
        xPosition += self.spacing
        
        let labelFrame = CGRect(origin: CGPoint(x: xPosition, y: self.bounds.midY - (labelSize.height / 2)), size: labelSize)
        self.textlabel.frame = labelFrame
    }
    
}

class PostMetadataView: BeamView {
    
    weak var delegate: PostMetadataViewDelegate?
    
    weak var post: Post? {
        didSet {
            self.updateContent()
        }
    }
    
    override var isOpaque: Bool {
        didSet {
            self.displayModeDidChange()
        }
    }
    
    var shouldShowSubreddit = false {
        didSet {
            self.updateLayout()
        }
    }
    
    var shouldShowUsername = true {
        didSet {
            self.updateLayout()
        }
    }
    
    var shouldShowDate = true {
        didSet {
            self.updateLayout()
        }
    }
    
    var shouldShowDomain = true {
        didSet {
            self.updateLayout()
        }
    }
    
    var shouldShowGilded = true {
        didSet {
            self.updateLayout()
        }
    }
    
    var shouldShowStickied = true {
        didSet {
            self.updateLayout()
        }
    }
    
    var shouldShowLocked = true {
        didSet {
            self.updateLayout()
        }
    }
    
    var highlightButtons = true {
        didSet {
            self.displayModeDidChange()
        }
    }
    
    lazy fileprivate var dateLabel = UILabel()
    
    lazy fileprivate var subredditButton = BeamPlainButton(frame: CGRect())
    
    lazy fileprivate var userButton = BeamPlainButton(frame: CGRect())
    
    lazy fileprivate var gildedView = PostMetadataGildedView(frame: CGRect())
    
    lazy fileprivate var domainLabel = UILabel()
    
    lazy fileprivate var stickiedLabel = UILabel()
    
    lazy fileprivate var lockedIconImageView = UIImageView(image: UIImage(named: "post_lock_icon"))
    
    lazy fileprivate var labels: [UIView] = {
        return [self.dateLabel, self.subredditButton, self.userButton, self.gildedView, self.domainLabel, self.stickiedLabel, self.lockedIconImageView]
    }()
    
    lazy fileprivate var seperatorViews: [PostMetdataSeperatorView] = {
        return [PostMetdataSeperatorView(), PostMetdataSeperatorView(), PostMetdataSeperatorView(), PostMetdataSeperatorView(), PostMetdataSeperatorView(), PostMetdataSeperatorView(), PostMetdataSeperatorView(), PostMetdataSeperatorView()]
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.isOpaque = true
        
        self.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        
        let font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        
        self.dateLabel.font = font
        self.subredditButton.titleLabel?.font = font
        self.userButton.titleLabel?.font = font
        self.gildedView.font = font
        self.stickiedLabel.font = font
        self.domainLabel.font = font
        
        self.subredditButton.addTarget(self, action: #selector(PostMetadataView.didTapSubreddit(_:)), for: .touchUpInside)
        self.userButton.addTarget(self, action: #selector(PostMetadataView.didTapUsername(_:)), for: .touchUpInside)
        
        self.addSubview(self.dateLabel)
        
        self.addSubview(self.subredditButton)
        
        self.addSubview(self.userButton)
        
        self.addSubview(self.domainLabel)
        
        self.addSubview(self.gildedView)
        
        self.addSubview(self.stickiedLabel)
        
        self.addSubview(self.lockedIconImageView)
        
        for seperatorView in self.seperatorViews {
            self.addSubview(seperatorView)
        }
    }
    
    fileprivate func updateContent() {
        self.dateLabel.text = self.post?.creationDate?.localizedRelativeTimeString
        self.userButton.setTitle(self.post?.author, for: .normal)
        self.subredditButton.setTitle(self.post?.subreddit?.displayName, for: .normal)
        
        if let URLString = self.post?.urlString, let URL = URL(string: URLString) {
            self.domainLabel.text = URL.host?.replacingOccurrences(of: "www.", with: "")
        }
        
        self.updateButtonTitleColorsAndState()
        
        if let post = self.post, let gildCount = post.gildCount?.intValue, gildCount > 0 {
            self.gildedView.count = gildCount
        } else {
            self.gildedView.count = 0
        }
        
        self.updateLayout()
        
        self.setNeedsLayout()
    }
    
    fileprivate func updateLayout() {
        self.dateLabel.isHidden = !self.shouldShowDate
        
        self.subredditButton.isHidden = !self.shouldShowSubreddit
        
        self.userButton.isHidden = !self.shouldShowUsername
        
        if let post = self.post, let gildCount = post.gildCount?.intValue, gildCount > 0 {
            self.gildedView.isHidden = !self.shouldShowGilded
        } else {
            self.gildedView.isHidden = true
        }
        
        if let urlString = self.post?.urlString, let URL = URL(string: urlString), self.post?.mediaObjects?.count == 0 && !URL.isYouTubeURL && self.post?.isSelfText == false {
            self.domainLabel.isHidden = !self.shouldShowDomain
        } else {
            self.domainLabel.isHidden = true
        }
        
        if let stickied = self.post?.stickied.boolValue, self.shouldShowStickied {
            self.stickiedLabel.isHidden = !stickied
        } else {
            self.stickiedLabel.isHidden = true
        }
        
        if !self.shouldShowLocked {
            self.lockedIconImageView.isHidden = true
        } else if let locked = self.post?.locked.boolValue, locked == true {
            self.lockedIconImageView.isHidden = false
        } else if let archived = self.post?.archived.boolValue, archived == true {
            self.lockedIconImageView.isHidden = false
        } else {
            self.lockedIconImageView.isHidden = true
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.dateLabel.textColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        self.domainLabel.textColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        self.stickiedLabel.textColor = DisplayModeValue(UIColor(red: 68 / 255, green: 156 / 255, blue: 57 / 255, alpha: 1), darkValue: UIColor(red: 90 / 255, green: 156 / 255, blue: 81 / 255, alpha: 1))
        
        let lockedTintColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        if self.lockedIconImageView.tintColor != lockedTintColor {
            self.lockedIconImageView.tintColor = lockedTintColor
        }

        let tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        if self.tintColor != tintColor {
            self.tintColor = tintColor
        }
        
        self.updateButtonTitleColorsAndState()
        
        //Update opaque views
        let opaqueViews: [UIView] = [self.dateLabel, self.subredditButton, self.userButton, self.gildedView, self.domainLabel, self.stickiedLabel, self.lockedIconImageView] + self.seperatorViews
        
        var backgroundColor = UIColor.white
        if self.displayMode == .dark {
            backgroundColor = UIColor.beamDarkContentBackgroundColor()
        }
        if !self.isOpaque {
            backgroundColor = UIColor.clear
        }
        for view in opaqueViews {
            if let button = view as? UIButton {
                button.titleLabel?.backgroundColor = backgroundColor
            }
            view.backgroundColor = backgroundColor
        }
        self.backgroundColor = backgroundColor
        
        for view in opaqueViews {
            if let button = view as? UIButton {
                button.titleLabel?.isOpaque = self.isOpaque
            }
            view.isOpaque = self.isOpaque
        }
    }
    
    fileprivate func updateButtonTitleColorsAndState() {
        self.userButton.setTitleColor(self.highlightButtons ? self.tintColor.withAlphaComponent(1) : UIColor.beamPurpleLight(), for: UIControlState())
        self.subredditButton.setTitleColor(self.highlightButtons ? self.tintColor.withAlphaComponent(1) : UIColor.beamPurpleLight(), for: UIControlState())
    }
    
    // MARK: - Sizing
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 30)
    }
    
    // MARK: - Actions
    
    @objc fileprivate func didTapUsername(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postMetdataView(self, didTapUsernameOnPost: post)
        }
        
    }
    
    @objc fileprivate func didTapSubreddit(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postMetdataView(self, didTapSubredditOnPost: post)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.frame.width > 320 {
            self.stickiedLabel.text = AWKLocalizedString("stickied-post")
        } else {
            self.stickiedLabel.text = AWKLocalizedString("stickied")
        }
        
        for view: UIView in self.labels {
            view.frame = CGRect()
        }
        
        for view: UIView in self.seperatorViews {
            view.frame = CGRect()
            view.isHidden = true
        }
        
        let spacing: CGFloat = 4.0
        var xPosition: CGFloat = self.layoutMargins.left
        let viewsToDisplay: [UIView] = self.labels.filter { (view) -> Bool in
            return view.isHidden == false
        }
        var seperatorIndex: Int = 0
        var index: Int = 0
        for view: UIView in viewsToDisplay {
            
            var size: CGSize = view.intrinsicContentSize
            if view is UIControl {
                size.height = self.bounds.height
            }
            
            let maxWidth: CGFloat = self.bounds.width - self.layoutMargins.right - self.layoutMargins.left
            
            if xPosition + size.width > maxWidth {
                let width: CGFloat = maxWidth - xPosition
                size.width = width
            }
            var frame: CGRect = CGRect.zero
            let yPosition: CGFloat = (self.bounds.height - size.height) / 2.0
            frame.origin = CGPoint(x: xPosition, y: yPosition)
            frame.size = size
            
            view.frame = frame
            
            xPosition += size.width + spacing

            let nextIndex: Int = index + 1
            let nextView: UIView? = viewsToDisplay.count > nextIndex ? viewsToDisplay[nextIndex] : nil

            if nextView != nil {
                //Add a seperator
                let seperatorView: PostMetdataSeperatorView = self.seperatorViews[seperatorIndex]
                seperatorView.isHidden = false
                let seperatorSize: CGSize = seperatorView.intrinsicContentSize
                
                var seperatorFrame: CGRect = CGRect.zero
                let yPosition: CGFloat = (self.bounds.height - seperatorSize.height) / 2.0
                seperatorFrame.origin = CGPoint(x: xPosition, y: yPosition)
                seperatorFrame.size = seperatorSize
                
                seperatorView.frame = seperatorFrame
                
                xPosition += seperatorSize.width + spacing
                
                seperatorIndex += 1
            }
            
            index += 1

        }
        
    }

}

extension PostMetadataViewDelegate where Self: UIViewController {
    
    func postMetdataView(_ metadataView: PostMetadataView, didTapSubredditOnPost post: Post) {
        guard let subreddit = post.subreddit else {
            return
        }
        
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = subreddit
            self.modallyPresentToolBarActionViewController(tabBarController)
        }
    }
    
    func postMetdataView(_ metadataView: PostMetadataView, didTapUsernameOnPost post: Post) {
        if let username = post.author, username != "[deleted]" {
            let navigationController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! BeamColorizedNavigationController
            let profileViewController = navigationController.viewControllers.first as! ProfileViewController
            profileViewController.username = username
            self.modallyPresentToolBarActionViewController(navigationController)
        }
    }
    
    fileprivate func modallyPresentToolBarActionViewController(_ viewController: UIViewController) {
        if let gallery = self.presentedViewController as? AWKGalleryViewController {
            gallery.present(viewController, animated: true, completion: nil)
        } else if let galleryRootViewController = AppDelegate.shared.galleryWindow?.rootViewController, let topViewController = AppDelegate.topViewController(galleryRootViewController) {
            topViewController.present(viewController, animated: true, completion: nil)
        } else {
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
}
