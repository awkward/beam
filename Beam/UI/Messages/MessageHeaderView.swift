//
//  MessageHeaderView.swift
//  Beam
//
//  Created by Rens Verhoeven on 18-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

class MessageHeaderView: BeamView {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    var message: Message? {
        didSet {
            self.titleLabel.text = self.message?.subject
            if let date = self.message?.creationDate {
                self.dateLabel.text = self.dateFormatter.string(for: date)
            } else {
                self.dateLabel.text = nil
            }
            
        }
    }
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    override func draw(_ rect: CGRect) {
        let seperatorPath = UIBezierPath(rect: CGRect(x: 12, y: rect.height - 0.5, width: rect.width - 22, height: 0.5))
        let seperatorColor = DisplayModeValue(UIColor.beamSeperatorColor(), darkValue: UIColor.beamDarkTableViewSeperatorColor())
        seperatorColor.setFill()
        seperatorPath.fill()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.setNeedsDisplay()
        
        switch self.displayMode {
        case .default:
            self.backgroundColor = UIColor.white
            self.titleLabel.textColor = UIColor.beamGreyExtraDark()
            self.dateLabel.textColor = UIColor(red: 127 / 255, green: 127 / 255, blue: 127 / 255, alpha: 1)
        case .dark:
            self.backgroundColor = UIColor.beamDarkContentBackgroundColor()
            self.titleLabel.textColor = UIColor.white
            self.dateLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        }
    }
}
