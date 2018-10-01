
//  AppDelegate.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
//import MessageUI
//import CloudKit
import MediaPlayer

extension UIApplication
{
    func isRunningInFullScreen() -> Bool
    {
        if let w = self.keyWindow
        {
            let maxScreenSize = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            let minScreenSize = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            
            let maxAppSize = max(w.bounds.size.width, w.bounds.size.height)
            let minAppSize = min(w.bounds.size.width, w.bounds.size.height)
            
            return (maxScreenSize == maxAppSize) && (minScreenSize == minAppSize)
        }
        
        return true
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate // AVAudioSessionDelegate Deprecated in 12.0
{
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else { return false }
        if topAsDetailController.sermonSelected == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        
        return false
    }
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
//        print("application:didFinishLaunchingWithOptions")

        guard let svc = window?.rootViewController as? UISplitViewController else {
            return false
        }
        
//        globals = Globals()
        
        Globals.shared.splitViewController = svc
        
        Globals.shared.splitViewController.delegate = self
        
        Globals.shared.splitViewController.preferredDisplayMode = .allVisible

        let hClass = Globals.shared.splitViewController.traitCollection.horizontalSizeClass
        let vClass = Globals.shared.splitViewController.traitCollection.verticalSizeClass
        
        if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
            if let navigationController = Globals.shared.splitViewController.viewControllers[Globals.shared.splitViewController.viewControllers.count-1] as? UINavigationController {
                navigationController.topViewController?.navigationItem.leftBarButtonItem = Globals.shared.splitViewController.displayModeButtonItem
            }
        }
        
        // Override point for customization after application launch.
        
        Globals.shared.addAccessoryEvents()
        
        startAudio()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("applicationWillResignActive")
        
//        Thread.onMainThread {
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
//        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground")
        
//        Thread.onMainThread {
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_ENTER_BACKGROUND), object: nil)
//        }
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        print("applicationWillEnterForeground")
        
        if (Globals.shared.mediaPlayer.rate == 0) {
            //It is paused, possibly not by us, but by the system
            if Globals.shared.mediaPlayer.isPlaying {
                Globals.shared.mediaPlayer.pause()
            }
        }
    
        if (Globals.shared.mediaPlayer.rate != 0) {
            if Globals.shared.mediaPlayer.isPaused {
                Globals.shared.mediaPlayer.play()
            }
        }
        
        Globals.shared.mediaPlayer.setupPlayingInfoCenter()
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERIES_UPDATE_UI), object: nil)

            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAYING_PAUSED), object: nil)

//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
        
//        Thread.onMainThread {
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
//        }
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
        
//        Thread.onMainThread {
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_TERMINATE), object: nil)
//        }
    }

//    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
//    {
//        print("application:handleEventsForBackgroundURLSession")
//        
//        /*
//    In iOS, when a background transfer completes or requires credentials, if your app is no longer running, iOS automatically relaunches your app in the background and calls the application:handleEventsForBackgroundURLSession:completionHandler: method on your app’s UIApplicationDelegate object. This call provides the identifier of the session that caused your app to be launched. Your app should store that completion handler, create a background configuration object with the same identifier, and create a session with that configuration object. The new session is automatically reassociated with ongoing background activity. Later, when the session finishes the last background download task, it sends the session delegate a URLSessionDidFinishEventsForBackgroundURLSession: message. Your session delegate should then call the stored completion handler.
//        */
//        
//        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
//        configuration.sessionSendsLaunchEvents = true
//        
//        var filename = String(identifier[Constants.IDENTIFIER.DOWNLOAD.endIndex...])
//        
//        if let range = filename.range(of: Constants.FILE_EXTENSION.MP3) {
//            filename = String(filename[..<range.lowerBound])
//        }
//        
//        if let allSeries = Globals.shared.series {
//            for series in allSeries {
//                if let sermons = series.sermons {
//                    for sermon in sermons {
//                        if sermon.id == Int(filename) {
//                            sermon.audioDownload.session = URLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
//                            sermon.audioDownload.completionHandler = completionHandler
//                            //Do we need to recreate the downloadTask for this session?
//                        }
//                    }
//                }
//            }
//        }
//    }
}

