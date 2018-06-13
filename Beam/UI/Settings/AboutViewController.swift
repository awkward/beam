//
//  AboutViewController.swift
//  beam
//
//  Created by David van Leeuwen on 27/08/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import AVFoundation

class AboutViewController: BeamTableViewController {
    
    @IBOutlet fileprivate var backgroundImageView: UIImageView!
    @IBOutlet fileprivate var starsImageView: UIImageView!
    @IBOutlet fileprivate var appIconImageView: UIImageView!
    @IBOutlet fileprivate var players = [AVAudioPlayer]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = AWKLocalizedString("about-title")
        
        let appIconRelativeValue: CGFloat = 25
        let appIconHorizontalAnimation = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.tiltAlongHorizontalAxis)
        appIconHorizontalAnimation.maximumRelativeValue = appIconRelativeValue
        appIconHorizontalAnimation.minimumRelativeValue = -appIconRelativeValue
        let appIconVerticalAnimation = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.tiltAlongVerticalAxis)
        appIconVerticalAnimation.maximumRelativeValue = appIconRelativeValue
        appIconVerticalAnimation.minimumRelativeValue = -appIconRelativeValue
        self.appIconImageView.motionEffects = [appIconHorizontalAnimation, appIconVerticalAnimation]
        
        let starsRelativeValue: CGFloat = 20
        let starsHorizontalAnimation = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.tiltAlongHorizontalAxis)
        starsHorizontalAnimation.maximumRelativeValue = starsRelativeValue
        starsHorizontalAnimation.minimumRelativeValue = -starsRelativeValue
        let starsVerticalAnimation = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.tiltAlongVerticalAxis)
        starsVerticalAnimation.maximumRelativeValue = starsRelativeValue
        starsVerticalAnimation.minimumRelativeValue = -starsRelativeValue
        self.starsImageView.motionEffects = [starsHorizontalAnimation, starsVerticalAnimation]
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.players = [AVAudioPlayer]()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath as IndexPath).row == 0 {
            //Open /r/beamreddit
            UIApplication.shared.open(URL(string: "beamwtf://r/beamreddit")!, options: [:], completionHandler: nil)
        } else if (indexPath as IndexPath).row == 1 {
            //Like on facebook
            UIApplication.shared.open(URL(string: "https://facebook.com/beamforreddit")!, options: [:], completionHandler: nil)
        } else if (indexPath as IndexPath).row == 2 {
            //Beamreddit twitter
            UIApplication.shared.open(URL(string: "https://twitter.com/beamreddit")!, options: [:], completionHandler: nil)
        } else if (indexPath as IndexPath).row == 3 {
            //Open /r/beamreddit
            UIApplication.shared.open(URL(string: "http://madeawkward.com")!, options: [:], completionHandler: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "aboutCell", for: indexPath) as! AboutTableViewCell
        switch (indexPath as IndexPath).row {
        case 0:
            //Reddit
            cell.title = "/r/beamreddit"
            cell.icon = .Reddit
        case 1:
            //Facebook
            cell.title = AWKLocalizedString("like-on-facebook")
            cell.icon = .Facebook
        case 2:
            //TWITTER
            cell.title = "@beamreddit"
            cell.icon = .Twitter
        case 3:
            //Awkward website
            cell.title = "Awkward"
            cell.icon = .Safari
        default:
            cell.title = "Not Implemented"
        }
        return cell
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.backgroundImageView.image = DisplayModeValue(UIImage(named: "about_view_background"), darkValue: UIImage(named: "about_view_background_darkmode"))
    }
    
    @IBAction fileprivate func tappedAppIcon(_ sender: UIButton) {
        //Play sound!
        print("Play sound")
        guard let audioUrl = Bundle.main.url(forResource: "biem", withExtension: "mp3"), let player = try? AVAudioPlayer(contentsOf: audioUrl) else {
            return
        }
        player.prepareToPlay()
        player.play()
        self.players.append(player)
    }
}
