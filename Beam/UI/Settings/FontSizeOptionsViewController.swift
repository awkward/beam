//
//  FontSizeOptionsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 21-07-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class FontSizeOptionsViewController: BeamTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("font-size-view-title", comment: "The title of the font size view")
        
    }

    fileprivate let categories: [String] = [
        UIContentSizeCategory.extraSmall.rawValue,
        UIContentSizeCategory.small.rawValue,
        UIContentSizeCategory.medium.rawValue,
        UIContentSizeCategory.large.rawValue,
        UIContentSizeCategory.extraLarge.rawValue,
        UIContentSizeCategory.extraExtraLarge.rawValue,
        UIContentSizeCategory.extraExtraExtraLarge.rawValue
    ]

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.categories.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "font-size-cell", for: indexPath)
        
        let currentCategory: String? = FontSizeController.category
        
        if (indexPath as IndexPath).section == 0 {
            cell.textLabel!.text = FontSizeController.displayTitle(forFontSizeCategory: nil)
            
            let appCategory: String = UIApplication.shared.preferredContentSizeCategory.rawValue
            let fontSize: CGFloat = FontSizeController.adjustedFontSize(17, forContentSizeCategory: appCategory)
            cell.textLabel?.font = UIFont.systemFont(ofSize: fontSize)
            
            if currentCategory == nil {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        } else {
            let category: String = self.categories[(indexPath as IndexPath).row]
            
            cell.textLabel!.text = FontSizeController.displayTitle(forFontSizeCategory: category)
            
            let fontSize: CGFloat = FontSizeController.adjustedFontSize(17, forContentSizeCategory: category)
            cell.textLabel?.font = UIFont.systemFont(ofSize: fontSize)
            
            if currentCategory == category {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if (indexPath as IndexPath).section == 0 {
            FontSizeController.category = nil
        } else {
            let category: String = self.categories[(indexPath as IndexPath).row]
            FontSizeController.category = category
        }
        self.tableView.reloadData()
    }

}
