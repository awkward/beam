//
//  ManagedObjectContext+Snoo.swift
//  Snoo
//
//  Created by Robin Speijer on 06/01/2020.
//  Copyright © 2020 Awkward. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    public func performAndReturn<R>(_ handler: () throws -> R) throws -> R {
        var blockResult: R?
        var thrownError: Error?
        performAndWait {
            do {
                blockResult = try handler()
            } catch {
                thrownError = error
            }
        }
        guard let result = blockResult else {
            throw (thrownError ?? NSError.snooError(localizedDescription: ""))
        }
        return result
    }
    
}

