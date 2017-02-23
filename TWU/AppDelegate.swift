
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate { // UISplitViewControllerDelegate
    
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//        print("application:didFinishLaunchingWithOptions")

        // Override point for customization after application launch.
        
        globals = Globals()
        
        startAudio()
        
        globals.addAccessoryEvents()

        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        return true
    }

    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        print("applicationWillEnterForeground")
        
        if (globals.mediaPlayer.rate == 0) {
            //It is paused, possibly not by us, but by the system
            if globals.mediaPlayer.isPlaying {
                globals.mediaPlayer.pause()
            }
        }
    
        if (globals.mediaPlayer.rate != 0) {
            if globals.mediaPlayer.isPaused {
                globals.mediaPlayer.play()
            }
        }
        
        globals.setupPlayingInfoCenter()
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERIES_UPDATE_UI), object: nil)

            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAY_PAUSE), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAYING_PAUSED), object: nil)
        })
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        print("applicationWillTerminate")
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
//        var filename:String?
//        
//        filename = identifier.substring(from: Constants.IDENTIFIER.DOWNLOAD.endIndex)
//        filename = filename?.substring(to: filename!.range(of: Constants.FILE_EXTENSION.MP3)!.lowerBound)
//        
//        for series in globals.series! {
//            for sermon in series.sermons! {
//                if (sermon.id == Int(filename!)) {
//                    sermon.audioDownload.session = URLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
//                    sermon.audioDownload.completionHandler = completionHandler
//                    //Do we need to recreate the downloadTask for this session?
//                }
//            }
//        }
//    }
}

