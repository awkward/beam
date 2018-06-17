//
//  InternalLinkRoutingController.swift
//  beam
//
//  Created by Rens Verhoeven on 05-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import JLRoutes
import Snoo
import CoreData
import AWKGallery

private var sharedInternalLinkRoutingControllerInstance = InternalLinkRoutingController()

class InternalLinkRoutingController: JLRoutes {
    
    class var shared: InternalLinkRoutingController {
        return sharedInternalLinkRoutingControllerInstance
    }
    
    fileprivate var currentViewController: UIViewController?
    
    override init() {
        super.init()
        self.setupRoutes()
    }
    
    fileprivate func setupRoutes() {
        //Subreddit routes, required parameter: name
        let subredditRoutes: [String] = ["subreddit/:name",
                                         "r/:name",
                                         "reddit.com/r/:name"]
        self.addRoutes(subredditRoutes) { (parameters: [String: Any]?) -> Bool in
            return self.handleSubredditCallWithParameters(parameters)
        }
        //Multireddit routes, required parameter: username, multiredditname
        let multiredditRoutes: [String] = ["u/:username/m/:multiredditname",
                                 "user/:username/m/:multiredditname",
                                 "reddit.com/user/:username/m/:multiredditname",
                                 "reddit.com/u/:username/m/:multiredditname"]
        self.addRoutes(multiredditRoutes) { (parameters: [String: Any]?) -> Bool in
            return self.handleMultiredditCallWithParameters(parameters)
        }
        //User routes, required parameter: username
        let userRoutes: [String] = ["user/:username",
                                    "u/:username",
                                    "reddit.com/u/:username"]
        self.addRoutes(userRoutes) { (parameters: [String: Any]?) -> Bool in
            return self.handleUserCallWithParameters(parameters)
        }
        //Post routes, required parameter: postid, subredditname optional
        let postRoutes: [String] = ["subreddit/:subredditname/comments/:postid/:postname",
                                    "r/:subredditname/comments/:postid/:postname",
                                    "r/:subredditname/comments/:postid",
                                    "/r/:subredditname/comments/:postid/:postname/:commentid/*",
                                    "/r/:subredditname/comments/:postid/:postname/*",
                                    "post/:postid/:postname",
                                    "post/:postid"]
        self.addRoutes(postRoutes) { (parameters: [String: Any]?) -> Bool in
            return self.handlePostCallWithParameters(parameters)
        }
        
    }
    
    // MARK: - Handle methods
    
    fileprivate func handleSubredditCallWithParameters(_ parameters: [String: Any]!) -> Bool {
        //Get the subreddit name
        if let rawSubredditName: String = parameters["name"] as? String {
            SubredditQuery.fetchSubreddit(rawSubredditName, handler: { (subreddit, _) in
                if let subreddit: Subreddit = subreddit {
                    _ = self.presentViewControllerForSubreddit(subreddit, fromViewController: self.currentViewController!)
                } else {
                    if let errorViewController = self.currentViewController as? NoticeHandling {
                        errorViewController.presentErrorMessage(AWKLocalizedString("subreddit-not-found"))
                    } else {
                        let alertController = BeamAlertController(title: AWKLocalizedString("subreddit-not-found"), message: nil, preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: AWKLocalizedString("OK"), style: .cancel, handler: nil))
                        self.currentViewController!.present(alertController, animated: true, completion: nil)
                    }
                    
                }
            })
        } else {
            //The name is not valid, so we can't get a subreddit to show
            return false
        }
        return true
    }
    
    fileprivate func handleUserCallWithParameters(_ parameters: [AnyHashable: Any]!) -> Bool {
        //Get the username
        if let username: String = parameters["username"] as? String {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            if let navigationController: UINavigationController = storyboard.instantiateInitialViewController() as? UINavigationController,
                let profileViewController: ProfileViewController = navigationController.topViewController as? ProfileViewController {
                    profileViewController.username = username
                    self.currentViewController!.present(navigationController, animated: true, completion: nil)
            }
        } else {
            //The name is not valid, so we can't get a subreddit to show
            return false
        }
        return true
    }
    
    fileprivate func handleMultiredditCallWithParameters(_ parameters: [AnyHashable: Any]!) -> Bool {
        //Get the subreddit name
        if let rawUsername = parameters["username"] as? String, let rawMultiredditName = parameters["multiredditname"] as? String {
            
            MultiredditQuery.fetchMultireddit(rawUsername, multiredditName: rawMultiredditName, handler: { (multireddit, _) in
                if multireddit != nil {
                    _ = self.presentViewControllerForSubreddit(multireddit!, fromViewController: self.currentViewController!)
                } else {
                    if let errorViewController = self.currentViewController as? NoticeHandling {
                        errorViewController.presentErrorMessage(AWKLocalizedString("multireddit-not-found"))
                    } else {
                        let alertController = BeamAlertController(title: AWKLocalizedString("multireddit-not-found"), message: nil, preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: AWKLocalizedString("OK"), style: .cancel, handler: nil))
                        self.currentViewController!.present(alertController, animated: true, completion: nil)
                    }
                    
                }
            })
        } else {
            //The name is not valid, so we can't get a subreddit to show
            return false
        }
        return true
    }
    
    fileprivate func handlePostCallWithParameters(_ parameters: [AnyHashable: Any]!) -> Bool {
        //Get the post ID
        if let rawPostID: String = parameters["postid"] as? String {
            var postFullname: String = rawPostID
            if !postFullname.contains("t3_") {
                postFullname = "t3_\(rawPostID)"
            }
            
            let rawCommentID: String? = parameters["commentid"] as? String
            var commentFullName: String? = rawCommentID
            if let commentID: String = rawCommentID, commentFullName?.contains("t1_") == false {
                commentFullName = "t1_\(commentID)"
            }
            
            let subredditCompletionHandler: ((_ subreddit: Subreddit?) -> Bool) = { (subreddit: Subreddit?) -> Bool in
                guard let viewController: UIViewController = self.currentViewController else {
                    return false
                }
                var fromViewController: UIViewController = viewController
                let fromSubreddit: Subreddit? = self.subredditOfViewController(viewController)
                
                //If the subreddit is not the same, show a new subreddit view
                if subreddit?.identifier != fromSubreddit?.identifier {
                    if let subreddit: Subreddit = subreddit {
                        fromViewController = self.presentViewControllerForSubreddit(subreddit, fromViewController: viewController)
                    }
                }
                
                //Show the post detail view
                guard let postDetailViewController: PostDetailViewController = self.presentViewControllerForPost(postFullname, fromViewController: fromViewController) else {
                    return true
                }
                
                //if the post contained a comment, download it and show it
                if let fullName: String = commentFullName {
                    InfoQuery.fetch(fullName, handler: { (object, _) in
                        if let comment: Comment = object as? Comment {
                            DispatchQueue.main.async {
                                self.presentComment(onPostDetailViewController: postDetailViewController, comment: comment)
                            }
                        }
                    })
                }
                
                return true
                
            }
            
            if let subredditName: String = parameters["subredditname"] as? String {
                //We also have a subreddit, we should first present the subreddit, than the post
                SubredditQuery.fetchSubreddit(subredditName, handler: { (subreddit, _) -> Void in
                    _ = subredditCompletionHandler(subreddit)
                })
            } else {
                //No subreddit, show the post on the frontpage
                return subredditCompletionHandler(nil)
            }
        } else {
            return false
        }
        return true
    }
    
    fileprivate func presentComment(onPostDetailViewController detailViewController: PostDetailViewController, comment: Comment) {
        let commentsViewController = UIStoryboard(name: "Comments", bundle: nil).instantiateViewController(withIdentifier: "comments") as! CommentsViewController
        let childQuery = CommentCollectionQuery()
        childQuery.post = comment.post
        childQuery.parentComment = comment
        
        commentsViewController.query = childQuery
        
        detailViewController.navigationController?.pushViewController(commentsViewController, animated: true)
    }
    
    class func fetchComment(_ objectName: String, handler: @escaping ((_ comment: Comment?, _ error: Error?) -> Void)) {
        let collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        let query = InfoQuery(fullName: objectName)
        collectionController.query = query
        collectionController.startInitialFetching { (collectionID: NSManagedObjectID?, error: Error?) -> Void in
            DispatchQueue.main.async {
                if error != nil {
                    handler(nil, error)
                }
                if let collectionID = collectionController.collectionID, let collection = AppDelegate.shared.managedObjectContext.object(with: collectionID) as? ObjectCollection, let comment = collection.objects?.firstObject as? Comment {
                    handler(comment, nil)
                } else {
                    handler(nil, NSError.beamError(404, localizedDescription: "Comment '\(objectName)' not found"))
                }
            }
        }
    }
    
    // MARK: - Opening Functions
    
    fileprivate func presentViewControllerForSubreddit(_ subreddit: Subreddit, fromViewController viewController: UIViewController) -> SubredditTabBarController {
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        let tabBarController = storyboard.instantiateInitialViewController() as! SubredditTabBarController
        tabBarController.subreddit = subreddit
        viewController.present(tabBarController, animated: true, completion: nil)
        return tabBarController
    }
    
    fileprivate func presentViewControllerForPost(_ postFullname: String, fromViewController viewController: UIViewController) -> PostDetailViewController? {
        if let subredditTabBarController = viewController as? SubredditTabBarController {
            let detailViewController = PostDetailViewController(postName: postFullname, contextSubreddit: subredditTabBarController.subreddit)
            self.navigationController(forViewController: subredditTabBarController)?.pushViewController(detailViewController, animated: false)
            return detailViewController
        } else {
            do {
                let frontpageSubreddit = try Subreddit.frontpageSubreddit()
                let detailViewController = PostDetailViewController(postName: postFullname, contextSubreddit: frontpageSubreddit)
                let subredditViewController = self.presentViewControllerForSubreddit(frontpageSubreddit, fromViewController: viewController)
                self.navigationController(forViewController: subredditViewController)?.pushViewController(detailViewController, animated: false)
                return detailViewController
            } catch {
                
            }
            
        }
        return nil
    }
    
    fileprivate func navigationController(forViewController viewController: UIViewController) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        if let tabBarController: UITabBarController = viewController as? UITabBarController, let selectedViewController: UIViewController = tabBarController.selectedViewController {
            return self.navigationController(forViewController: selectedViewController)
        }
        return viewController.navigationController
    }
    
    fileprivate func subredditOfViewController(_ viewController: UIViewController) -> Subreddit? {
        if let subredditStream: SubredditStreamViewController = viewController as? SubredditStreamViewController {
            return subredditStream.subreddit
        }
        if let postDetailView: PostDetailEmbeddedViewController = viewController as? PostDetailEmbeddedViewController {
            return postDetailView.subreddit
        }
        if let postDetailView: PostDetailViewController = viewController as? PostDetailViewController {
            return postDetailView.embeddedViewController.subreddit
        }
        if let tabBarController: SubredditTabBarController = viewController as? SubredditTabBarController {
            return tabBarController.subreddit
        }
        if let navigationController: UINavigationController = viewController as? UINavigationController, let topViewController: UIViewController = navigationController.topViewController {
            return self.subredditOfViewController(topViewController)
        }
        if let tabBarController: UITabBarController = viewController as? UITabBarController, let selectedViewController: UIViewController = tabBarController.selectedViewController {
            return self.subredditOfViewController(selectedViewController)
        }
        return nil
    }
    
    // MARK: - Route Functions
    
    override class func routeURL(_ url: URL!) -> Bool {
        return InternalLinkRoutingController.shared.routeURL(url)
    }
    
    override class func routeURL(_ url: URL!, withParameters parameters: [String: Any]!) -> Bool {
        return InternalLinkRoutingController.shared.routeURL(url, withParameters: parameters)
    }
    
    override func routeURL(_ url: URL!) -> Bool {
        if let rootViewController = AppDelegate.shared.galleryWindow?.rootViewController?.presentedViewController as? AWKGalleryViewController {
            //Check if the window or rootViewController exist, otherwise we can't navigate. This also sets the currentViewController to present all the other views on.
            self.currentViewController = AppDelegate.topViewController(rootViewController)
            return super.routeURL(url)
        } else if let rootViewController = AppDelegate.shared.window?.rootViewController {
            //Check if the window or rootViewController exist, otherwise we can't navigate. This also sets the currentViewController to present all the other views on.
            self.currentViewController = AppDelegate.topViewController(rootViewController)
            return super.routeURL(url)
        }
        return false
    }
    
    override func routeURL(_ url: URL!, withParameters parameters: [String: Any]!) -> Bool {
        if let rootViewController = AppDelegate.shared.galleryWindow?.rootViewController?.presentedViewController as? AWKGalleryViewController {
            //Check if the window or rootViewController exist, otherwise we can't navigate. This also sets the currentViewController to present all the other views on.
            self.currentViewController = AppDelegate.topViewController(rootViewController)
            return super.routeURL(url, withParameters: parameters)
        } else if let rootViewController = AppDelegate.shared.window?.rootViewController {
            //Check if the window or rootViewController exist, otherwise we can't navigate. This also sets the currentViewController to present all the other views on.
            self.currentViewController = AppDelegate.topViewController(rootViewController)
            return super.routeURL(url, withParameters: parameters)
        }
        return false
    }
    
    func routeURL(_ url: URL, onViewController viewController: UIViewController) -> Bool {
        self.currentViewController = viewController
        return super.routeURL(url)
    }
    
}
