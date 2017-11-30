//
//  WebViewController.swift
//  beam
//
//  Created by Robin Speijer on 14-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class WebViewController: BeamViewController, UIWebViewDelegate {
    
    var initialUrl: URL?

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = true
        
        if self.navigationController?.viewControllers[0] == self {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(WebViewController.doneButtonTapped(_:)))
        }
        
        if let url = self.initialUrl {
            self.webView.loadRequest(URLRequest(url: url))
        }
    }
    
    func doneButtonTapped(_ sender: AnyObject) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - UIWebViewDelegate
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        AppDelegate.shared.retainNetworkIndicator(self)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        AppDelegate.shared.releaseNetworkIndicator(self)
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }
        if nsError.code == 102 && nsError.domain == "WebKitErrorDomain" { return };
        
        let alert = BeamAlertController(title: AWKLocalizedString("could-not-load-page"), message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addCancelAction({ (action) in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(UIAlertAction(title: AWKLocalizedString("retry"), style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
            if let url = self.initialUrl {
                self.webView.loadRequest(URLRequest(url: url))
            }
        }))
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        AppDelegate.shared.releaseNetworkIndicator(self)
        
        self.title = webView.stringByEvaluatingJavaScript(from: "document.title")
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
