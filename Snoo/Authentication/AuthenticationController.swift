//
//  Snoo.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public struct AuthenticationConfiguration {
    
    // MARK: API
    public var regularHost = "www.reddit.com"
    public var oauthHost = "oauth.reddit.com"
    public var clientName: String
    public var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    // MARK: Authentication
    public var clientID: String
    public var redirectUri: String
    public var scope: String = "identity,edit,flair,history,modconfig,modflair,modlog,modposts,modwiki,mysubreddits,privatemessages,read,report,save,submit,subscribe,vote"
    
    public init(clientName: String, clientID: String, redirectUri: String, scope: String? = nil) {
        self.clientName = clientName
        self.clientID = clientID
        self.redirectUri = redirectUri
        if let scope = scope {
            self.scope = scope
        }
    }
}

// MARK: -

public final class AuthenticationController: NSObject {
    
    internal static let UserSessionWillChangeNotificationName = Notification.Name(rawValue: "UserSessionWillChangeNotification")
    public static let UserDidChangeNotificationName = Notification.Name(rawValue: "AuthenticationControllerUserDidChangeNotification")
    public static let UserDidUpdateNotificationName = Notification.Name(rawValue: "AuthenticationControllerUserDidUpdateNotification")
    public static let UserDidLogoutNotificationName = Notification.Name(rawValue: "UserDidLogoutNotification")
    static let AuthenticationSessionsChangedNotificationName = Notification.Name(rawValue: "AuthenticationSessionsChangedNotification")
    static let ApplicationTokenDidChangeNotificationName = Notification.Name(rawValue: "ApplicationTokenDidChangeNotification")
    static let UserTokenDidChangeNotificationName = Notification.Name(rawValue: "UserTokenDidChangeNotification")
    
    public static let UserIdentifierKey = "userIdentifier"
    
    // MARK: Properties
    open var configuration: AuthenticationConfiguration

    open var isAuthenticated: Bool {
        return self.userSession?.refreshToken != nil
    }
    
    open var isApplicationAuthenticated: Bool {
        return self.activeSession?.accessToken != nil
    }
    
    internal static let ApplicationSessionKey = "authentication-application-session"
    var applicationSession: AuthenticationSession? {
        get {
            if let sessionData = UserDefaults.standard.object(forKey: AuthenticationController.ApplicationSessionKey) as? Data {
                let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData)
                return session as? AuthenticationSession
            } else {
                return nil
            }
        }
        set {
            if let newValue = newValue {
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: newValue)
                UserDefaults.standard.set(sessionData, forKey: AuthenticationController.ApplicationSessionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AuthenticationController.ApplicationSessionKey)
            }
            self.updateURLSession()
            NotificationCenter.default.post(name: AuthenticationController.ApplicationTokenDidChangeNotificationName, object: self)
        }
    }
    
    internal static let CurrentUserSessionKey = "authentication-current-user-session"
    open var userSessionAvailable: Bool {
        return UserDefaults.standard.object(forKey: AuthenticationController.CurrentUserSessionKey) != nil
    }
    
    open var activeUserSession: AuthenticationSession? {
        return self.userSession
    }
    
    var userSession: AuthenticationSession? {
        didSet {
            self.saveCurrentUserSession()
            self.updateURLSession()
            NotificationCenter.default.post(name: AuthenticationController.UserTokenDidChangeNotificationName, object: self)
        }
    }
    
    fileprivate func saveCurrentUserSession() {
        if let session = self.userSession {
            let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
            UserDefaults.standard.set(sessionData, forKey: AuthenticationController.CurrentUserSessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: AuthenticationController.CurrentUserSessionKey)
        }
        
        DispatchQueue.main.async {
            if UIApplication.shared.isProtectedDataAvailable {
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    var activeSession: AuthenticationSession? {
        get {
            if self.userSession != nil {
                return self.userSession
            } else {
                return self.applicationSession
            }
        }
        set {
            NotificationCenter.default.post(name: AuthenticationController.UserSessionWillChangeNotificationName, object: self.userSession)
            self.userSession = newValue
            self.updateURLSession()
            NotificationCenter.default.post(name: AuthenticationController.AuthenticationSessionsChangedNotificationName, object: self)
            NotificationCenter.default.post(name: AuthenticationController.UserDidChangeNotificationName, object: self, userInfo: self.authenticationNotificationUserInfo(forSession: self.activeSession))
            
        }
    }
    
    fileprivate func authenticationNotificationUserInfo(forSession session: AuthenticationSession?) -> [String: Any]? {
        if let userIdentifier = session?.userIdentifier {
            return [AuthenticationController.UserIdentifierKey: userIdentifier]
        } else {
            return [AuthenticationController.UserIdentifierKey: NSNull()]
        }
    }
    
    open var activeUserIdentifier: String? {
        return self.userSession?.userIdentifier
    }
    
    open func activeUser(_ context: NSManagedObjectContext) -> User? {
        var user: User? = nil
        if let userIdentifier = self.activeUserIdentifier {
            context.performAndWait({ () -> Void in
                do {
                    user = try User.fetchObjectWithIdentifier(userIdentifier, context: context) as? User
                } catch {
                    NSLog("Error fetching user \(error)")
                }
            })
        }
        return user
    }
    
    internal var authorizationState: String?
    
    // MARK: Setup
    
    public init(clientID: String, redirectUri: String, clientName: String, loadCurrentSession: Bool = true) {
        self.configuration = AuthenticationConfiguration(clientName: clientName, clientID: clientID, redirectUri: redirectUri)
        
        super.init()
        
        if loadCurrentSession {
            let oldUserSessionKey = "authentication-user-session"
            if let sessionData = UserDefaults.standard.object(forKey: oldUserSessionKey) as? Data,
                let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? AuthenticationSession {
                do {
                    if let tokenData = try Keychain.load(AuthenticationSession.OldKeychainUsernameKey) {
                        let refreshToken = String(data: tokenData, encoding: .utf8)
                        session.refreshToken = refreshToken
                        try Keychain.delete(AuthenticationSession.OldKeychainUsernameKey)
                    }
                } catch {
                    NSLog("Error getting old refresh token \(error)")
                }
                
                if let user = self.activeUser(DataController.shared.privateContext), session.username == nil {
                    session.username = user.username
                }
                self.userSession = session
                do {
                    try self.addUserSession(session)
                } catch {
                    NSLog("Error upgrading user session \(error)")
                }
                self.saveCurrentUserSession()
                UserDefaults.standard.removeObject(forKey: oldUserSessionKey)
            } else if let sessionData = UserDefaults.standard.object(forKey: AuthenticationController.CurrentUserSessionKey) as? Data,
                let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? AuthenticationSession {
                self.userSession = session
            }
            
            if self.fetchAllAuthenticationSessions().count > 0 && self.userSession == nil {
                self.userSession = self.fetchAllAuthenticationSessions().first
            }
            
        }
    }
    
    // MARK: Helpers
    
    //Privatly used to make userURLSession update
    fileprivate var privateUserURLSession: URLSession?
    
    //Trigger the userURLSession to update, for instance when the token changes
    fileprivate func updateURLSession() {
        if let tokenType = self.activeSession?.tokenType, let token = self.activeSession?.accessToken {
            let currentAuthorizationHeader = self.userURLSession.configuration.httpAdditionalHeaders?["Authorization"] as? String
            let newAuthorizationHeader = "\(tokenType) \(token)"
            if currentAuthorizationHeader != newAuthorizationHeader {
                self.privateUserURLSession = nil
            }
        }
    }
    
    /**
     Use this NSURLSession to make requests to reddit. This session will contain the "Autherization" token related to the user
     */
    open var userURLSession: URLSession {
        if self.privateUserURLSession == nil {
            let configuration = self.basicURLSessionConfiguration
            
            var headers = configuration.httpAdditionalHeaders!
            
            if let tokenType = self.activeSession?.tokenType, let token = self.activeSession?.accessToken {
                headers["Authorization"] = "\(tokenType) \(token)"
            }
            
            configuration.httpAdditionalHeaders = headers
            
            self.privateUserURLSession = URLSession(configuration: configuration)
        }
        return self.privateUserURLSession!
    }
    
    /**
     Returns a NSURLSessionConfiguration without the autherization header. This configuration is used for all requests that needs custom authorization or none.
     */
    open lazy var basicURLSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        
        var headers = [String: String]()
        headers["Accept"] = "application/json"
        headers["User-Agent"] = "ios:\(bundleIdentifier):v\(self.configuration.clientVersion) (by /u/beamreddit)"
        
        configuration.httpAdditionalHeaders = headers
        return configuration
    }()
    
    // MARK: Authentication process
    
    /**
     Operations to be added before other RedditRequest operations. These make sure that the application is correctly authenticated. In case the app is already authenticated, the operations will be instantly finished.
     */
    func authenticationOperations() -> [Operation] {

        if let userSession = self.userSession, let refreshToken = userSession.refreshToken, userSession.isValid == false {
            // Expired user session. First refresh this.
            
            let tokenRequest = AccessTokenRequest(grant: AccessTokenGrant.refreshToken(refreshToken), clientId: self.configuration.clientID, authenticationController: self)
            
            let userRequest = RedditUserRequest(authenticationController: self)
            // By making the user request dependent on the token request, the user request will automatically get the correct authentication session from the token request.
            userRequest.addDependency(tokenRequest)
            
            let userParser = UserParsingOperation()
            userParser.addDependency(userRequest)
            userParser.userParsingCompletionHandler = { [weak self, weak tokenRequest] () in
                guard let request = tokenRequest, let response = request.HTTPResponse else {
                    print("Unknown error updating access token, no response code, error: \(String(describing: tokenRequest?.error))")
                    return
                }
                //Only update the user session when there is an actual reponse
                if response.statusCode == 200 {
                    //The request was sucessful, update the userSession
                    let userSession = request.authenticationSession
                    userSession?.userIdentifier = userParser.userIdentifier
                    userSession?.username = userParser.username
                    userSession?.refreshToken = self?.userSession?.refreshToken
                    self?.userSession = userSession
                    
                } else if response.statusCode == 400 {
                    //Bad request, the refresh token is probably invalid. This error is not returned when something is missing from the request, that will be a 403
                    self?.userSession?.destroy()
                    self?.userSession = nil
                    print("Bad request, destroying user session, statusCode: \(response.statusCode) error: \(String(describing: request.error))")
                } else {
                    print("Unknown error updating access token, statusCode: \(response.statusCode) error: \(String(describing: request.error))")
                }
            }
            
            return [tokenRequest, userRequest, userParser]
            
        } else if let deviceId = UIDevice.current.identifierForVendor?.uuidString, applicationSession?.isValid != true && self.userSession?.isValid != true {
            // Expired app token, no app token and user is not logged in.
                
            let tokenRequest = AccessTokenRequest(grant: AccessTokenGrant.installedClient(deviceId), clientId: self.configuration.clientID, authenticationController: self)
            tokenRequest.requestCompletionHandler = { (error) in
                if let session = tokenRequest.authenticationSession {
                    self.applicationSession = session
                }
            }
            
            return [tokenRequest]
            
        } else {
            // It's all OK.
            return [Operation]()
        }
        
    }
    
    /**
    If the user is not authenticated and he wants to login, you can present a web view to trigger the OAuth authentication process. Use this URL.
    */
    open var authorizationURL: URL? {
        self.authorizationState = UUID().uuidString

        if let redirectString = URL.stringByAddingUrlPercentagesToString(self.configuration.redirectUri), let scopeString = URL.stringByAddingUrlPercentagesToString(self.configuration.scope), let state = authorizationState {
            let urlString = "https://www.reddit.com/api/v1/authorize.compact?client_id=\(self.configuration.clientID)&response_type=code&state=\(state)&redirect_uri=\(redirectString)&duration=permanent&scope=\(scopeString)"
            let url = Foundation.URL(string: urlString)
            return url
        }
        
        return nil
    }
    
    /**
    When the webview asks you to load a certain URL that corresponds to your respond-URL from the OAuth process, call this method with the url. The controller tries to obtain access and will let you know in the handler. The handler can be called from a background thread.
    */
    open func authenticateURL(_ url: URL, handler: ((Bool, Error?) -> Void)?) {
        if let parameters = url.queryParameters,
            let state = parameters["state"],
            let code = parameters["code"] {
                let clientId = self.configuration.clientID
                
                if state == self.authorizationState {
                    let accessTokenRequest = AccessTokenRequest(grant: AccessTokenGrant.authorizationCode(code), clientId: clientId, authenticationController: self)
                    DataController.shared.executeOperations([accessTokenRequest], handler: { (error: Error?) -> Void in
                        
                        if let session = accessTokenRequest.authenticationSession {
                            self.configureSessionAndSetUser(session, handler: { (error: Error?) -> Void in
                                handler?(error == nil, error)
                            })
                        } else {
                            handler?(false, error)
                        }
                        
                    })
                } else {
                    handler?(false, nil)
                }
        } else {
            handler?(false, nil)
        }
        
    }
    
    // MARK: Authentication implementation
    
    fileprivate func configureSessionAndSetUser(_ session: AuthenticationSession, handler: ((Error?) -> Void)?) {
        let context: NSManagedObjectContext! = DataController.shared.privateContext
        
        let deleteOperation = DataController.clearAllObjectsOperation() as! BatchDeleteOperation
        deleteOperation.onlyClearExpiredContent = false
        DataController.shared.executeAndSaveOperations([deleteOperation], handler: { (error: Error?) -> Void in
            
            self.requestUser(session, handler: { (userID: NSManagedObjectID?, identifier: String?, error: Error?) -> Void in
                context.performAndWait({ () -> Void in
                    if let userIdentifier = identifier, let userID = userID, let user = context.object(with: userID) as? User {
                        if let error = error {
                            handler?(error)
                        } else {
                            session.userIdentifier = userIdentifier
                            session.username = user.username
                            
                            do {
                                try self.addUserSession(session)
                                self.switchToAuthenticationSession(session, handler: nil)
                            } catch let error as NSError {
                                print("Error adding user session \(error)")
                                handler?(error)
                                return
                            } catch {
                                print("Unkown error adding user session")
                            }
                            
                            NSLog("Authentication session set. Token: %@", session.accessToken ?? "<access token missing>")
                            
                            handler?(nil)
                        }
                        
                    } else {
                        handler?(error)
                    }
                })
                
            })
            
        })
        
    }
    
    // MARK: Fetching user info
    
    open func requestActiveUser(_ handler: ((_ userID: NSManagedObjectID?, _ identifier: String?, _ error: Error?) -> Void)?) {
        if let userSession = self.userSession, userSession.refreshToken != nil {
            self.requestUser(userSession, handler: handler)
        } else {
            handler?(nil, nil, NSError.snooError(404, localizedDescription: "No current user session"))
        }
    }
    
    fileprivate func requestUser(_ authSession: AuthenticationSession, handler: ((_ userID: NSManagedObjectID?, _ identifier: String?, _ error: Error?) -> Void)?) {
        
        // Create a custom NSURLSession, because we could be inside an authentication process and the user session is not yet set.
        let privateContext: NSManagedObjectContext! = DataController.shared.privateContext
        
        let userRequest = RedditUserRequest(authenticationController: self)
        userRequest.urlSession = self.urlSessionWithAuthenticationSession(authSession)
        
        let userParser = UserParsingOperation()
        userParser.addDependency(userRequest)
        
        DataController.shared.executeAndSaveOperations([userRequest, userParser], context: privateContext) { (error: Error?) -> Void in
            if self.activeUserSession?.username == nil {
                self.activeUserSession?.username = userParser.username
            }
            NotificationCenter.default.post(name: AuthenticationController.UserDidUpdateNotificationName, object: self)
            handler?(userParser.userID, userParser.userIdentifier, error)
        }
        
    }
    
    fileprivate func urlSessionWithAuthenticationSession(_ session: AuthenticationSession) -> URLSession {
        let configuration = self.basicURLSessionConfiguration
        
        var headers = configuration.httpAdditionalHeaders!
        
        if let tokenType = session.tokenType, let token = session.accessToken {
            headers["Authorization"] = "\(tokenType) \(token)"
        }
        
        configuration.httpAdditionalHeaders = headers
        return URLSession(configuration: configuration)
    }
    
    // MARK: Multiple account support
    
    internal var authenticationSessions: [AuthenticationSession] {
        get {
            let data = UserDefaults.standard.object(forKey: "all-authentication-user-sessions") as? [Data] ?? [Data]()
            var sessions = [AuthenticationSession]()
            for dataItem in data {
                if let item = NSKeyedUnarchiver.unarchiveObject(with: dataItem) as? AuthenticationSession {
                    sessions.append(item)
                } else {
                    print("Corrupted account info. Make sure to always use Beam to alter the account info. Session is removed")
                }
            }
            return sessions
        }
        set {
            let dataArray = newValue.map { (session) -> Data in
                return NSKeyedArchiver.archivedData(withRootObject: session)
            }
            UserDefaults.standard.set(dataArray, forKey: "all-authentication-user-sessions")
            NotificationCenter.default.post(name: AuthenticationController.AuthenticationSessionsChangedNotificationName, object: self)
        }
    }
    
    internal func addUserSession(_ session: AuthenticationSession) throws {
        guard session.userIdentifier != nil && session.refreshToken != nil else {
            throw NSError.snooError(400, localizedDescription: "Invalid user session to save, please include a userIdentifier and refreshToken")
        }
        
        let currentSessions = self.authenticationSessions
        
        if let existingSession = currentSessions.first(where: { (filterSession) -> Bool in
            filterSession.userIdentifier == session.userIdentifier
        }) {
            existingSession.refreshToken = session.refreshToken
            existingSession.userIdentifier = session.userIdentifier
            if let username = session.username {
                existingSession.username = username
            }
            if let accessToken = session.accessToken {
                existingSession.accessToken = accessToken
            }
            self.authenticationSessions = currentSessions
        } else {
            self.authenticationSessions = currentSessions + [session]
        }
    }
    
    open func removeUserSession(_ session: AuthenticationSession, handler: (() -> Void)?) {
        let sessions = self.authenticationSessions
        
        if let newSession = sessions.first(where: { (filterSession) -> Bool in
           filterSession.userIdentifier != session.userIdentifier
        }) {
            self.switchToAuthenticationSession(newSession) { (_) in
                session.destroy()
                NotificationCenter.default.post(name: AuthenticationController.UserDidLogoutNotificationName, object: self, userInfo: self.authenticationNotificationUserInfo(forSession: session))
                self.authenticationSessions = sessions.filter({
                    let existingSession: AuthenticationSession = $0
                    return session.userIdentifier != existingSession.userIdentifier
                })
                handler?()
            }
        } else {
            session.destroy()
            NotificationCenter.default.post(name: AuthenticationController.UserDidLogoutNotificationName, object: self, userInfo: self.authenticationNotificationUserInfo(forSession: session))
            self.authenticationSessions = [AuthenticationSession]()
            self.activeSession = nil
            handler?()
        }
    }
    
    open func removeAllUserAccounts() {
        let sessions = self.authenticationSessions
        for session in sessions {
            session.destroy()
            NotificationCenter.default.post(name: AuthenticationController.UserDidLogoutNotificationName, object: self, userInfo: self.authenticationNotificationUserInfo(forSession: session))
        }
        
        self.activeSession = nil
        self.authenticationSessions = [AuthenticationSession]()
    }
    
    open func switchToAuthenticationSession(_ session: AuthenticationSession?, handler: ((_ error: Error?) -> Void)?) {
        if session != nil && session?.refreshToken == nil {
            handler?(NSError.snooError(400, localizedDescription: "The given user account is invalid, this could be because the refresh token no longer exists"))
        } else {
            DataController.shared.cancelAllOperations(completionHandler: {
                guard let newSession = session, let refreshToken = newSession.refreshToken, !newSession.isValid else {
                    self.activeSession = session
                    DataController.shared.executeAndSaveOperations(self.authenticationOperations(), handler: handler)
                    return
                }
                
                //The session was not valid, so we update the new session we are about to set with a new token!
                let tokenRequest = AccessTokenRequest(grant: .refreshToken(refreshToken), clientId: self.configuration.clientID, authenticationController: self)
                DataController.shared.executeOperations([tokenRequest], handler: { (error) in
                    if let error = error {
                        handler?(error)
                    } else {
                        newSession.accessToken = tokenRequest.authenticationSession?.accessToken
                        newSession.expirationDate = tokenRequest.authenticationSession?.expirationDate
                        newSession.refreshToken = tokenRequest.authenticationSession?.refreshToken ?? refreshToken
                        self.activeSession = newSession
                        DataController.shared.executeAndSaveOperations(self.authenticationOperations(), handler: handler)
                    }
                })
                
            })
        }
    }
    
    open func fetchAllAuthenticationSessions() -> [AuthenticationSession] {
        var sessions = self.authenticationSessions.filter({ $0.refreshToken != nil })
        
        sessions.sort { (session1: AuthenticationSession, session2: AuthenticationSession) -> Bool in
            return session1.username?.localizedCaseInsensitiveCompare(session2.username ?? "") == ComparisonResult.orderedAscending
        }
        
        return sessions
    }
    
}
