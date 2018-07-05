//
//  SubredditTableViewCell.swift
//  beam
//
//  Created by Rens Verhoeven on 20-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

/// Defines methods that can be called by a SubredditTableViewCell.
protocol SubredditTableViewCellDelegate: class {
    
    /// When the star button is tapped on subreddit cell.
    ///
    /// - Parameters:
    ///   - cell: The cell that the star was tapped on.
    ///   - subreddit: The subreddit that the user wants to favorite/unfavorite.
    func subredditTableViewCell(_ cell: SubredditTableViewCell, toggleFavoriteOnSubreddit subreddit: Subreddit)
}

/// The cell used to display a subreddit of multireddit.
final class SubredditTableViewCell: BeamTableViewCell {
    
    // MARK: - Private properties
    
    lazy private var starButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "tableview_star_filled"), for: .normal)
        button.isHidden = true
        button.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        button.addTarget(self, action: #selector(toggleFavoriteSubreddit(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy private var subredditPreview: SubredditPreviewView = {
        let view = SubredditPreviewView()
        view.subreddit = self.subreddit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = self.titleLabelFont
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy private var horizontalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.starButton, self.subredditPreview, self.titleStackView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 7
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(14, after: self.starButton)
        return stackView
    }()
    
    private var showStar = false {
        didSet {
            self.configureStarButton()
        }
    }
    
    private var displayProminently: Bool {
        guard self.allowPromimentDisplay else {
            return false
        }
        return self.subreddit?.isBookmarked.boolValue == true || self.subreddit?.identifier == Subreddit.frontpageIdentifier || self.subreddit?.identifier == Subreddit.allIdentifier || self.subreddit is Multireddit
    }
    
    private var starButtonEnabled: Bool {
        return (self.subreddit?.isPrepopulated != true)
    }
    
    private var titleLabelFont: UIFont {
        if self.displayProminently {
            return UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        } else {
            return UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        }
    }
    
    // MARK: - Public Properties
    
    /// The delegate that is called when an action happens on the Subreddit cell.
    weak var delegate: SubredditTableViewCellDelegate?
    
    /// If the cell is allowed to be displayed prominently. Prominent cells have an icon before the title.
    var allowPromimentDisplay = true
    
    /// The subreddit or multireddit the cell should display
    var subreddit: Subreddit? {
        didSet {
            self.titleLabel.font = self.titleLabelFont
            self.titleLabel.text = self.subreddit?.displayName
            self.subredditPreview.subreddit = subreddit
            self.subredditPreview.isHidden = !(self.displayProminently)
            
            if self.subreddit is Multireddit || self.displayProminently {
                self.subredditPreview.isHidden = false
                self.subtitleLabel.isHidden = false
                if let multireddit = self.subreddit as? Multireddit {
                    self.subtitleLabel.text = "\(multireddit.subreddits?.count ?? 0) subreddits"
                } else if self.subreddit?.identifier == Subreddit.frontpageIdentifier {
                    self.subtitleLabel.text = AWKLocalizedString("frontpage-description")
                } else if self.subreddit?.identifier == Subreddit.allIdentifier {
                    self.subtitleLabel.text = AWKLocalizedString("all-description")
                } else {
                    self.subtitleLabel.text = nil
                }
            } else {
                self.subredditPreview.isHidden = true
                self.subtitleLabel.text = nil
            }
            
            self.subtitleLabel.isHidden = !((self.displayProminently || self.subreddit is Multireddit) && self.subtitleLabel.text != nil)
            
            self.displayModeDidChange()
            self.configureStarButton()
            
        }
    }
    
    // MARK: - Initialization
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    // MARK: Setup
    
    private func setupView() {
        self.contentView.addSubview(self.horizontalStackView)
        
        self.setupConstraints()
    }
    
    private func setupConstraints() {
        let constraints = [
            self.horizontalStackView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.horizontalStackView.leftAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leftAnchor),
            self.contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: self.horizontalStackView.bottomAnchor),
            self.contentView.layoutMarginsGuide.rightAnchor.constraint(lessThanOrEqualTo: self.horizontalStackView.rightAnchor),
            
            self.subredditPreview.widthAnchor.constraint(equalTo: self.subredditPreview.heightAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func configureStarButton() {
        if self.subreddit?.isBookmarked.boolValue == true {
            self.starButton.setImage(UIImage(named: "tableview_star_filled"), for: .normal)
        } else {
            self.starButton.setImage(UIImage(named: "tableview_star"), for: .normal)
        }

        self.starButton.isHidden = !self.showStar
        
        self.displayModeDidChange()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.titleLabel.backgroundColor = self.contentView.backgroundColor
        self.subtitleLabel.backgroundColor = self.contentView.backgroundColor
        
        self.titleLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.titleLabel.isOpaque = true
        
        self.subtitleLabel.textColor = self.titleLabel.textColor.withAlphaComponent(0.8)
        
        let starHighlighted = self.starButton.isHighlighted || self.subreddit?.isBookmarked.boolValue == true

        switch self.displayMode {
        case .default:
            if starHighlighted {
                self.starButton.tintColor = UIColor(red: 250 / 255, green: 212 / 255, blue: 25 / 255, alpha: 1.0)
            } else {
                self.starButton.tintColor = UIColor(red: 201 / 255, green: 200 / 255, blue: 204 / 255, alpha: 1.0)
            }
            self.selectedBackgroundView = nil
        case .dark:
            if starHighlighted {
                self.starButton.tintColor = UIColor(red: 250 / 255, green: 212 / 255, blue: 25 / 255, alpha: 0.6)
            } else {
                self.starButton.tintColor = UIColor(red: 201 / 255, green: 200 / 255, blue: 204 / 255, alpha: 1.0)
            }
            let view = UIView()
            view.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1)
            self.selectedBackgroundView = view
        }
        if self.subreddit?.isPrepopulated == true {
            self.starButton.tintColor = UIColor(red: 0.4, green: 0.7, blue: 1, alpha: 1)
        }
    }
    
    @objc private func toggleFavoriteSubreddit(_ sender: UIButton) {
        guard let subreddit = self.subreddit else {
            return
        }
        self.delegate?.subredditTableViewCell(self, toggleFavoriteOnSubreddit: subreddit)
        
        self.configureStarButton()
    }
    
    override func willTransition(to state: UITableViewCellStateMask) {
        self.showStar = state.contains(.showingEditControlMask)

        super.willTransition(to: state)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleLabel.numberOfLines = (self.bounds.height > 44) ? 2: 1
    }
    
}
