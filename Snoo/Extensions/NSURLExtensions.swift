//
//  NSURLExtensions.swift
//  Snoo
//
//  Created by Laurin Brandner on 04/06/15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import UIKit

extension URL {
    
    var fragmentParameters: [String: String]? {
        if let queries = fragment?.components(separatedBy: "&") {
            var parameters = [String: String]()
            for query in queries {
                let components = query.components(separatedBy: "=")
                if components.count == 2 {
                    parameters[components[0]] = components[1]
                }
            }
            return parameters
        }
        return nil
    }
    
    var queryParameters: [String: String]? {
        if let queries = query?.components(separatedBy: "&") {
            var parameters = [String: String]()
            for query in queries {
                let components = query.components(separatedBy: "=")
                if components.count == 2 {
                    parameters[components[0]] = components[1]
                }
            }
            return parameters
        }
        return nil
    }

    public static func stringByAddingUrlPercentagesToString(_ string: String, excludeSpace: Bool = false) -> String? {
        let charactersToEscape: String!
        if excludeSpace {
            charactersToEscape = "!*'();@&=+$,/?%#[]\"{}\\"
        } else {
            charactersToEscape = "!*'();@&=+$,/?%#[]\" {}\\"
        }
        let characterSet = CharacterSet(charactersIn: charactersToEscape).inverted
        return string.addingPercentEncoding(withAllowedCharacters: characterSet)
    }
    
}
