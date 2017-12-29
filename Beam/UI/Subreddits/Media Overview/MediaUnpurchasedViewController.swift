//
//  MediaUnpurchasedViewController.swift
//  beam
//
//  Created by Robin Speijer on 23-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Trekker
import Snoo

class MediaUnpurchasedGradientView: UIView {
    override class var layerClass : AnyClass {
        return CAGradientLayer.self
    }
    
    fileprivate var gradientLayer: CAGradientLayer {
        return self.layer as! CAGradientLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupGradient()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupGradient()
    }
    
    fileprivate func setupGradient() {
        let gradientColor = UIColor(red:0.94, green:0.94, blue:0.95, alpha:0)
        let gradientColor2 = UIColor(red:0.94, green:0.94, blue:0.95, alpha:0.9)
        let gradientColor3 = UIColor(red:0.94, green:0.94, blue:0.95, alpha:1)
        
        self.gradientLayer.locations = [0, 0.40, 0.65, 1]
        self.gradientLayer.colors = [gradientColor.cgColor, gradientColor2.cgColor, gradientColor3.cgColor, gradientColor3.cgColor]
    }
    
}

class MediaUnpurchasedViewController: BeamViewController, SubredditTabItemViewController {
    
    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var subheadingLabel: UILabel!
    @IBOutlet var topPreviewImageConstraint: NSLayoutConstraint!
    @IBOutlet var viewPackButton: UIButton!
    
    var titleView: SubredditTitleView = SubredditTitleView.titleViewWithSubreddit(nil)
    
    weak var subreddit: Subreddit? {
        didSet {
            self.updateNavigationItem()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.headingLabel.text = AWKLocalizedString("mediaview-unpurchased-heading")
        self.subheadingLabel.text = AWKLocalizedString("mediaview-unpurchased-subheading")
        self.viewPackButton.setTitle(AWKLocalizedString("view-pack"), for: UIControlState())
        
        self.updateNavigationItem()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var placeholderImage: UIImage!
        
        if let image = UIImage(named: "display-placeholder-\(UIScreen.main.bounds.width)") {
            placeholderImage = image
        } else {
            placeholderImage = UIImage(named: "display-placeholder-375")
        }
        
        self.previewImageView.image = placeholderImage
        self.topPreviewImageConstraint.constant = 0
        
        Trekker.default.track(event: "Visit blocked media view")
    }
    
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch self.displayMode {
        case .dark:
            self.headingLabel.textColor = UIColor.white
            self.subheadingLabel.textColor = UIColor.beamGreyLight()
        case .default:
            self.headingLabel.textColor = UIColor.black
            self.subheadingLabel.textColor = UIColor.beamGreyLight()
        }
    }

    @IBAction func upgradeButtonTapped(_ sender: AnyObject) {
        let storeYboard = UIStoryboard(name: "Store", bundle: nil)
        if let navigation = storeYboard.instantiateInitialViewController() as? UINavigationController, let storeViewController = navigation.topViewController as? StoreViewController {
            
            BeamSoundType.tap.play()
            
            let product = StoreProduct(identifier: ProductDisplayPackIdentifier)
            storeViewController.productToShow = product
            navigation.topViewController?.performSegue(withIdentifier: storeViewController.showPackSegueIdentifier, sender: self)
            self.present(navigation, animated: true, completion: nil)
            
        }
    }
}
