//
//  PostMediaParsing.swift
//  Snoo
//
//  Created by Rens Verhoeven on 10/08/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//

import UIKit

protocol PostMediaParser {

    func parseMedia(for post: Post, json: NSDictionary) -> [MediaObject]
    
}
