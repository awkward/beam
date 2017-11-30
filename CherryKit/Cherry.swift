//
//  Cherry.swift
//  CherryKit
//
//  Created by Laurin Brandner on 25/06/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public let CherryKitErrorDomain = "nl.madeawkward.cherrykit"
public let CherryKitParsingErrorCode = 10001
public let CherryKitNetworkingErrorCode = 10002

open class Cherry {

    static open var signatureForRequest: ((URLRequest) -> String?)?
    static open var appVersion: String?
    
    static internal var urlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        if let appVersion: String = Cherry.appVersion {
            let headers: [String: String] = [
                "User-Agent": "Beam (v\(appVersion)) by Awkward",
                "X-Beam-Version": appVersion,
                "Content-Type": "application/json"
            ]
            configuration.httpAdditionalHeaders = headers
        } else {
            fatalError("You should provide the app version string to Cherry.")
        }
        return configuration
    }
    
    static open var urlSession: URLSession = URLSession(configuration: Cherry.urlSessionConfiguration)

}
