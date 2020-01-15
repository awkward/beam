//
//  WebViewController.swift
//  beam
//
//  Created by Robin Speijer on 14-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: BeamViewController, WKNavigationDelegate {
    
    var initialUrl: URL?

    @IBOutlet var webView: WKWebView!
    
    private weak var titleObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.navigationController?.viewControllers.first == self {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(WebViewController.doneButtonTapped(_:)))
        }
        
        webView.navigationDelegate = self
        titleObserver = webView.observe(\WKWebView.title) { (webView, change) in
            self.title = webView.title
        }
        
        if let url = self.initialUrl {
            webView.load(URLRequest(url: url))
        }
    }
    
    @objc func doneButtonTapped(_ sender: AnyObject) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - WKWebViewDelegate
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }
        if nsError.code == 102 && nsError.domain == "WebKitErrorDomain" { return }
        
        let alert = BeamAlertController(title: AWKLocalizedString("could-not-load-page"), message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        alert.addCancelAction({ (_) in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(UIAlertAction(title: AWKLocalizedString("retry"), style: UIAlertAction.Style.default, handler: { (_) -> Void in
            if let url = self.initialUrl {
                self.webView.load(URLRequest(url: url))
            }
        }))
    }
    
}
