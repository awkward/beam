//
//  CommentsHeaderView.swift
//  Beam
//
//  Created by Rens Verhoeven on 03-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

protocol CommentsHeaderViewDelegate: class {
    
    func commentsHeaderView(_ headerView: CommentsHeaderView, didChangeSortType sortType: CollectionSortType)
}

class CommentsHeaderView: BeamView {

    @IBOutlet var sortBar: ScrollableButtonBar!
    @IBOutlet var sortBarBackgroundView: UIView!
    
    var sortType = CollectionSortType.best {
        didSet {
            self.sortBar.selectedItemIndex = self.sortTypes.index(of: self.sortType)
        }
    }
    
    weak var delegate: CommentsHeaderViewDelegate?
    
    fileprivate var sortTypes: [CollectionSortType] = [.best, .top, .new, .controversial, .old, .qa]
    
    var detailViewHeight: CGFloat = 49
    var commentsViewHeight: CGFloat = 56
    
    class func headerView(withDelegate delegate: CommentsHeaderViewDelegate) -> CommentsHeaderView {
        let headerView = UINib(nibName: "CommentsHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CommentsHeaderView
        headerView.delegate = delegate
        return headerView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupView()
    }
    
    func setupView() {
        self.sortBar.items = self.sortTypes.map({ self.titleForSortType($0) })
        self.sortBar.selectedItemIndex = self.sortTypes.index(of: self.sortType)
        self.sortBar.addTarget(self, action: #selector(CommentsHeaderView.sortBarChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    func titleForSortType(_ sortType: CollectionSortType) -> String {
        switch sortType {
        case .best:
            return AWKLocalizedString("comment-sort-type-best")
        case .top:
            return AWKLocalizedString("comment-sort-type-top")
        case .new:
            return AWKLocalizedString("comment-sort-type-new")
        case .controversial:
            return AWKLocalizedString("comment-sort-type-controversial")
        case .old:
            return AWKLocalizedString("comment-sort-type-old")
        case .qa:
            return AWKLocalizedString("comment-sort-type-qa")
        default:
            return "UNKNOWN"
        }
    }
    
    @objc fileprivate func sortBarChanged(_ sender: AnyObject) {
        let sortType = self.sortTypes[self.sortBar.selectedItemIndex ?? 0]
        self.delegate?.commentsHeaderView(self, didChangeSortType: sortType)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.backgroundColor = UIColor.clear
        
        self.sortBarBackgroundView.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.sortBar.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
    }
    
}
