//
//  BeamSound.swift
//  Beam
//
//  Created by Rens Verhoeven on 27-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import Snoo
import AudioToolbox

//The string will be the file name in the bundle
enum BeamSoundType: String {
    case upvote
    case downvote
    case tap
    
    func play() {
        guard UserSettings[.playSounds] else {
            return
        }
        if let soundURL = Bundle.main.url(forResource: self.rawValue, withExtension: "caf") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            // Play
            AudioServicesPlaySystemSound(mySound)
            
            AudioServicesAddSystemSoundCompletion(mySound, nil, nil, { (soundID, _) in
                AudioServicesRemoveSystemSoundCompletion(soundID)
                AudioServicesDisposeSystemSoundID(soundID)
                }, nil)
        }
    }
}

//Extension of VoteStatus for vote sound
extension VoteStatus {
    
    var soundType: BeamSoundType {
        switch self {
        case .up:
            return BeamSoundType.upvote
        case .down:
            return BeamSoundType.downvote
        default:
            return BeamSoundType.tap
        }
    }
}
