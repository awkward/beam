//
//  PostVideoPartCell.swift
//  beam
//
//  Created by Rens Verhoeven on 14/08/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//

import UIKit
import SDWebImage
import Snoo

final class PostVideoPartCell: UITableViewCell, PostCell, MediaImageLoader {
    
    lazy var mediaImageView: UIImageView! = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.accessibilityIgnoresInvertColors = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var playIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIView.ContentMode.center
        imageView.isOpaque = false
        imageView.clipsToBounds = true
        imageView.image = #imageLiteral(resourceName: "video_play_external")
        imageView.accessibilityIgnoresInvertColors = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private(set) var spoilerView: ImageSpoilerView = {
        let spoilerView = ImageSpoilerView()
        spoilerView.translatesAutoresizingMaskIntoConstraints = false
        return spoilerView
    }()
    
    weak var post: Post? {
        didSet {
            guard self.post != oldValue else {
                return
            }
            mediaObject = post?.mediaObjects?.firstObject as? MediaDirectVideo
            startImageLoading()
        }
    }
    
    var mediaObject: MediaObject?
    
    var imageOperation: SDWebImageOperation?
    
    var preferredThumbnailSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    var onDetailView: Bool = false
    
    var shouldShowSpoilerOverlay: Bool = true
    var shouldShowNSFWOverlay: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupView()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
    
    private func setupView() {
        self.preservesSuperviewLayoutMargins = false
        self.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        
        self.contentView.addSubview(self.mediaImageView)
        self.contentView.addSubview(self.playIconImageView)
        
        let constraints = [
            self.mediaImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.mediaImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.mediaImageView.bottomAnchor),
            self.contentView.rightAnchor.constraint(equalTo: self.mediaImageView.rightAnchor),
            
            self.playIconImageView.centerXAnchor.constraint(equalTo: self.mediaImageView.centerXAnchor),
            self.playIconImageView.centerYAnchor.constraint(equalTo: self.mediaImageView.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    class func height(for video: MediaDirectVideo?, width: CGFloat) -> CGFloat {
        guard let video = video else {
            return (width * 0.5625).rounded(.down)
        }
        let scale = width / video.pixelSize.width
        let height = video.pixelSize.height * scale
        return height.rounded(.down)
    }
    
    func imageLoadingCompleted() {
        
    }
    
    func progressDidChange(_ progress: CGFloat) {
        
    }
    
}
