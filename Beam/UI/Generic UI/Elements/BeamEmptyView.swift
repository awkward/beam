//
//  BeamEmptyView.swift
//  beam
//
//  Created by John van de Water on 21/10/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

enum BeamEmptyViewType: String {
    case Loading = ""
    
    case Error = "error"
    
    case NoInboxMessages = "inbox_no_messages"
    case NoInboxNotifications = "inbox_no_notifications"
    case MultiredditNoAccess = "multireddit_no_access"
    case MultiredditNoSubreddits = "multireddit_no_subreddits"
    
    case PostNoComments = "post_no_comments"
    case ProfileNoPostsLiked = "profile_no_posts_liked"
    case ProfileNoPostsSaved = "profile_no_posts_saved"
    case ProfileNoPostsHidden = "profile_no_posts_hidden"
    case ProfileNoPostsSubmitted = "profile_no_posts_submitted"
    case ProfileNoComments = "profile_no_comments"
    case ProfileNoGilded = "profile_no_gilded"
    case OtherProfileNoPostsSubmitted = "other_profile_no_posts_submitted"
    case OtherProfileNoComments = "other_profile_no_comments"
    case OtherProfileNoGilded = "other_profile_no_gilded"
    case ProfileNotLoggedIn = "profile_not_logged_in"
    case MultiredditsNotLoggedIn = "multireddits_not_logged_in"
    case MessagesNotLoggedIn = "messages_not_logged_in"
    case SearchNoResults = "search_no_results"
    case SubredditMediaViewEmpty = "subreddit_media_view_empty"
    case SubredditNoPosts = "subreddit_no_posts"
    case SubredditsNoMultireddits = "subreddits_no_multireddits"
    case ImgurUploadsNoImages = "imgur_uploads_empty"
    
    var loginEmptyState: Bool {
        switch self {
        case .MessagesNotLoggedIn, .ProfileNotLoggedIn, .MultiredditsNotLoggedIn:
            return true
        default:
            return false
        }
    }
    
}

class BeamEmptyView: BeamView {
    
    @IBOutlet fileprivate var containerView: UIView!
    @IBOutlet fileprivate var activityIndicator: UIActivityIndicatorView!

    @IBOutlet fileprivate var imageView: UIImageView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var textLabel: UILabel!
    @IBOutlet fileprivate var button: BeamButton!
    
    @IBOutlet fileprivate var buttonConstraints: [NSLayoutConstraint]!
    
    var buttonHandler: ((_ button: UIButton?) -> Void)? {
        didSet {
            self.button.isHidden = self.buttonHandler == nil
        }
    }
    
    var error: Error?
    
    /// The empty view type. This defines the content of the empty view. If the type is ProfileNotLoggedIn, a login buttin is visible. In that case, the buttonHandler will already be set.
    var emptyType: BeamEmptyViewType = .Error {
        // Title and textLabel should also be set based on type. This should still be implemented.
        didSet {
            let isLoading: Bool = self.emptyType == BeamEmptyViewType.Loading
            self.containerView.isHidden = isLoading
            if isLoading {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
            
            var key: String = self.emptyType.rawValue
            if key.hasPrefix("other_") {
                key = key.replacingOccurrences(of: "other_", with: "")
            }
            
            var imageKey: String = key
            
            var showLoginButton = self.emptyType.loginEmptyState
            
            if self.emptyType == BeamEmptyViewType.Error {
                var errorKey: String?
                if let error = self.error as NSError? {
                    if error.domain == NSURLErrorDomain || error.domain == SnooErrorDomain {
                        if error.code == NSURLErrorTimedOut {
                            errorKey = "empty_state_request_timed_out"
                        } else if error.code == 500 || error.code == NSURLErrorBadServerResponse {
                            errorKey = "empty_state_reddit_down"
                        } else if error.code == 401 {
                            errorKey = "empty_state_unauthorized"
                            showLoginButton = true
                        }
                    } else if error.domain == NSCocoaErrorDomain {
                        if error.code == 259 {
                            errorKey = "empty_state_internal_error"
                        }
                    }
                }
                
                if errorKey == nil {
                    if let error = self.error as NSError?, error.domain == NSURLErrorDomain {
                        errorKey = "no_internet_connection"
                    } else {
                        errorKey = "empty_state_internal_error"
                    }
                }
                key = errorKey!
                imageKey = "empty_state_image_error"
            }
            
            var messageKey: String = "\(key)_message"
            let buttonKey: String = "\(key)_button"
            
            if imageKey.count > 0 {
                self.imageView.image = UIImage(named: imageKey)
            } else {
                self.imageView.image = nil
            }
            
            self.titleLabel.text = AWKLocalizedString(key)
            
            var errorCodeString: String = ""
            if let error = self.error as NSError? {
                if AppDelegate.shared.cherryController.isAdminUser {
                    errorCodeString = "\n(\(error.domain) \(error.code))"
                } else {
                    errorCodeString = "\n(\(error.code))"
                }
                
            }
            
            //The search results empty view state needs a different message if the user is logged out
            if self.emptyType == .SearchNoResults && AppDelegate.shared.authenticationController.isAuthenticated == false {
                messageKey = "search_no_results_message_logged_out"
            }
            
            self.textLabel.text = AWKLocalizedString(messageKey).replacingLocalizablePlaceholders(for: ["error-code-string": errorCodeString])
            
            self.button.setTitle(AWKLocalizedString(buttonKey), for: UIControlState())
            self.setNeedsUpdateConstraints()
            
            if showLoginButton {
                self.buttonHandler = {(button) -> Void in
                    AppDelegate.shared.presentAuthenticationViewController()
                }
            }
            
            self.button.isHidden = self.buttonHandler == nil
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        for constraint in self.buttonConstraints {
            constraint.isActive = (self.buttonHandler != nil)
        }
    }
    
    override init(frame: CGRect) {
        fatalError("Use the emptyView class method instead!")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    class func emptyView(_ type: BeamEmptyViewType, error: Error? = nil, frame: CGRect) -> BeamEmptyView {
        let view = UINib(nibName: "BeamEmptyView", bundle: nil).instantiate(withOwner: self, options: nil).first as! BeamEmptyView
        view.error = error
        view.emptyType = type
        view.frame = frame
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.button.addTarget(self, action: #selector(BeamEmptyView.buttonTapped(_:)), for: .touchUpInside)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch self.displayMode {
        case .default:
            self.titleLabel.textColor = UIColor.black
            self.textLabel.textColor = UIColor.black.withAlphaComponent(0.8)
            self.activityIndicator.color = nil
        case .dark:
            self.titleLabel.textColor = UIColor.white
            self.textLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            self.activityIndicator.color = UIColor.white
        }
        
        self.backgroundColor = DisplayModeValue(UIColor.groupTableViewBackground, darkValue: UIColor.beamDarkContentBackgroundColor())
    }
    
    @objc func buttonTapped(_ sender: UIButton?) {
        self.buttonHandler?(sender)
    }
    
}
