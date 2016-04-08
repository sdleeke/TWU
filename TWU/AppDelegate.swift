
//  AppDelegate.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import MessageUI
import CloudKit
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate, UISplitViewControllerDelegate {
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else { return false }
        if topAsDetailController.sermonSelected == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    var window: UIWindow?

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData)
    {
        print("application:didRegisterForRemoteNotificationsWithDeviceToken")
        print("Device token: \(deviceToken.description)")
//        notification("Device token: \(deviceToken.description)")
        let deviceTokenString = "\(deviceToken)"
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString:"<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        print("deviceTokenString: \(deviceTokenString)\n")
        
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError)
    {
        print("application:didFailToRegisterForRemoteNotificationsWithError")
//        showAlert("FailedToRegisterForRemoteNotifications: \(error.description)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void)
    {
        let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        if ckNotification.notificationType == .Query, let queryNotification = ckNotification as? CKQueryNotification
        {
            if #available(iOS 9.0, *) {
                print("subscriptionID: \(queryNotification.subscriptionID)")
            } else {
                // Fallback on earlier versions
            }
            print("recordID: \(queryNotification.recordID)")
            print("recordFields: \(queryNotification.recordFields)")
            
            let aps = userInfo["aps"]

            print("application:didReceiveRemoteNotification:fetchCompletionHandler: \(aps)")

            if queryNotification.recordID?.recordName == "Current Sermon Series" {
//                print("\(aps!["alert"])")
                
                if let alert = aps!["alert"] as? String {
                    switch alert {
                    case "Update Available":
                        dispatch_async(dispatch_get_main_queue()) {
                            UIApplication.sharedApplication().applicationIconBadgeNumber += 1
                            self.sermonUpdateAvailable()
                        }
                        break
                        
                    default:
                        break
                    }
                }
            }
        }
        
        completionHandler(UIBackgroundFetchResult.NoData)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject])
    {
        let alert = userInfo["aps"]!["alert"] as? String
        let category = userInfo["aps"]!["category"] as? String

        print("application:didReceiveRemoteNotification: \(alert) \(category)")

        showAlert("application:didReceiveRemoteNotification: \(alert) \(category)")
    }
    
//    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void)
//    {
//        print("handleActionWithIdentifier:forLocalNotification")
//        
//        showMessage(identifier)
//
////        if identifier == "READ_IDENTIFIER" {
////            print("User selected 'Read'")
////        } else if identifier == "DELETE_IDENTIFIER" {
////            print("User selected 'Delete'")
////        }
//        
//        completionHandler()
//    }
//    
//    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void)
//    {
//        print("handleActionWithIdentifier:forLocalNotification:withResponseInfo")
//
//        showMessage(identifier)
//        
////        if identifier == "READ_IDENTIFIER" {
////            print("User selected 'Read'")
////        } else if identifier == "DELETE_IDENTIFIER" {
////            print("User selected 'Delete'")
////        }
//
//        completionHandler()
//    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void)
    {
        print("application:handleActionWithIdentifier:forRemoteNotification: \(identifier)")
        
//        showAlert(identifier)

        switch identifier! {
        case "LATER":
            print("User selected 'Later'")
            application.applicationIconBadgeNumber += 1
            //The app isn't started in this case.
            break
            
        case "NOW":
            print("User selected 'Now'")
            application.applicationIconBadgeNumber += 1
            // This starts the app and the user is asked to update because the badge numer isn't zero.
//            application.applicationIconBadgeNumber = 0
//            handleRefresh()
            break
            
        default:
            break
        }
        
        completionHandler()
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        print("application:didRegisterUserNotificationSettings: \(notificationSettings)")
    }
    
    func sermonUpdateAvailable()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_AVAILABLE_NOTIFICATION, object: nil)
        })
    }
    
    func showAlert(message:String?)
    {
        let application = UIApplication.sharedApplication()
        let alert = UIAlertView(title: "Remote Notification \(application.applicationIconBadgeNumber)", message: message, delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
//    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool
//    {
////        println("application:openURL")
//
//        let host = url.host
//
//        //Never used
////        let scheme = url.scheme
////        let path = url.path
////        let query = url.query
//        
////        println("Host: \(host) Scheme: \(scheme) Path: \(path) Query: \(query)")
////        println("BaseURL: \(url.baseURL) PathComponents: \(url.pathComponents)")
////        println("AbsoluteURL: \(url.absoluteURL) PathExtension: \(url.pathExtension) RelativePath: \(url.relativePath)")
//        
//        //Why does this work without having to determine whether the app is sufficiently loaded to
//        //allow deep linking?
//        
//        var selectedSeries:Series?
//        
//        selectedSeries = globals.series?.filter({ (series:Series) -> Bool in
//            return series.name == host
//        }).first
//        
//        //iPad
//        if let svc = self.window?.rootViewController as? UISplitViewController {
//            //            println("rvc = UISplitViewController")
//            if let nvc = svc.viewControllers[0] as? UINavigationController {
//                //                println("nvc = UINavigationController")
//                if let cvc = nvc.topViewController as? MediaCollectionViewController {
//                    //                    println("nvc = MediaCollectionViewController")
//                    if (selectedSeries != nil) {
//                        globals.seriesSelected = selectedSeries
//                        cvc.performSegueWithIdentifier(Constants.Show_Series, sender: cvc)
//                    }
//                }
//            }
//        }
//        
//        //iPhone
//        if let nvc = self.window?.rootViewController as? UINavigationController {
//            //     _   println("rvc = UINavigationController")
//            if let _ = nvc.topViewController as? MediaViewController {
//                //                    println("myvc = MediaViewController")
//
//                nvc.popToRootViewControllerAnimated(true)
//            }
//
//            if let cvc = nvc.topViewController as? MediaCollectionViewController {
//                //                println("cvc = MediaCollectionViewController")
//                
//                if (selectedSeries != nil) {
//                    globals.seriesSelected = selectedSeries
//                    cvc.performSegueWithIdentifier(Constants.Show_Series, sender: cvc)
//                }
//            }
//        }
//
//        return true
//    }
    
    func mpPlayerLoadStateDidChange()
    {
        globals.mpPlayerLoadStateDidChange()
    }
    
    func playerTimer()
    {
        globals.playerTimer()
    }

    func setupRemoteNotification()
    {
        let database = CKContainer.defaultContainer().publicCloudDatabase
        database.fetchAllSubscriptionsWithCompletionHandler({ (subscriptions:[CKSubscription]?, error:NSError?) -> Void in
            //            print("\(subscriptions)")
            
            for subscriptionObject in subscriptions! {
                let subscription = subscriptionObject as CKSubscription
                //                print("\(subscription)")
                database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: { (string:String?, error:NSError?) -> Void in
                })
            }
            
            let subscription = CKSubscription(recordType: Constants.SUBSCRIPTION_RECORD_TYPE, predicate: NSPredicate(value: true), subscriptionID: "com.leeke.TWU", options: CKSubscriptionOptions.FiresOnRecordUpdate)
            
            let info = CKNotificationInfo()
            info.shouldSendContentAvailable = true
            if #available(iOS 9.0, *) {
                info.category = Constants.REMOTE_NOTIFICATION_CATEGORY
            }
            info.alertBody = Constants.REMOTE_NOTIFICATION_ALERT_BODY
            info.desiredKeys = Constants.REMOTE_NOTIFICATION_DESIRED_KEYS
            
            subscription.notificationInfo = info
            
            CKContainer.defaultContainer().publicCloudDatabase.saveSubscription(subscription) { (subscription:CKSubscription?, error:NSError?) -> Void in
                
            }
        })
        
        if (Constants.SUPPORT_REMOTE_NOTIFICATION) {
            let nowAction = UIMutableUserNotificationAction()
            nowAction.identifier = Constants.REMOTE_NOTIFICATION_NOW_ACTION_IDENTIFIER
            nowAction.title = Constants.REMOTE_NOTIFICATION_NOW_ACTION_TITLE
            nowAction.activationMode = UIUserNotificationActivationMode.Foreground
            nowAction.destructive = false
            nowAction.authenticationRequired = true
            
            let laterAction = UIMutableUserNotificationAction()
            laterAction.identifier = Constants.REMOTE_NOTIFICATION_LATER_ACTION_IDENTIFIER
            laterAction.title = Constants.REMOTE_NOTIFICATION_LATER_ACTION_TITLE
            laterAction.activationMode = UIUserNotificationActivationMode.Background
            laterAction.destructive = false
            laterAction.authenticationRequired = false
            
            let messageCategory = UIMutableUserNotificationCategory()
            
            messageCategory.identifier = Constants.REMOTE_NOTIFICATION_CATEGORY
            
            messageCategory.setActions([nowAction, laterAction], forContext:UIUserNotificationActionContext.Minimal)
            messageCategory.setActions([nowAction, laterAction], forContext:UIUserNotificationActionContext.Default)
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: Set([messageCategory])) //
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
//        print("application:didFinishLaunchingWithOptions")

        // Override point for customization after application launch.
        
        globals = Globals()
        
        setupRemoteNotification()
        
        startAudio()
        
        globals.addAccessoryEvents()

        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        globals.player.observer = NSTimer.scheduledTimerWithTimeInterval(Constants.PLAYER_TIMER_INTERVAL, target: self, selector: #selector(AppDelegate.playerTimer), userInfo: nil, repeats: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.mpPlayerLoadStateDidChange), name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)
        
        return true
    }

    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        print("applicationWillEnterForeground")
        
        globals.setupPlayingInfoCenter()
        
        if (application.applicationIconBadgeNumber > 0) {
            sermonUpdateAvailable()
        }

        if (globals.player.mpPlayer?.currentPlaybackRate == 0) {
            //It is paused, possibly not by us, but by the system
            if (globals.player.loaded) {
                globals.updateCurrentTimeExact()
            }
            globals.player.paused = true
        } else {
            globals.player.paused = false
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
        })
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        print("applicationWillTerminate")
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void)
    {
        print("application:handleEventsForBackgroundURLSession")
        
        /*
    In iOS, when a background transfer completes or requires credentials, if your app is no longer running, iOS automatically relaunches your app in the background and calls the application:handleEventsForBackgroundURLSession:completionHandler: method on your app’s UIApplicationDelegate object. This call provides the identifier of the session that caused your app to be launched. Your app should store that completion handler, create a background configuration object with the same identifier, and create a session with that configuration object. The new session is automatically reassociated with ongoing background activity. Later, when the session finishes the last background download task, it sends the session delegate a URLSessionDidFinishEventsForBackgroundURLSession: message. Your session delegate should then call the stored completion handler.
        */
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        configuration.sessionSendsLaunchEvents = true
        
        var filename:String?
        
        filename = identifier.substringFromIndex(Constants.DOWNLOAD_IDENTIFIER.endIndex)
        filename = filename?.substringToIndex(filename!.rangeOfString(Constants.MP3_FILE_EXTENSION)!.startIndex)
        
        for series in globals.series! {
            for sermon in series.sermons! {
                if (sermon.id == Int(filename!)) {
                    sermon.audioDownload.session = NSURLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
                    sermon.audioDownload.completionHandler = completionHandler
                    //Do we need to recreate the downloadTask for this session?
                }
            }
        }
    }
}

