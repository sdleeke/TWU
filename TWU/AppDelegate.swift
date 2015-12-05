
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
import MediaPlayer


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate {

    var window: UIWindow?
    
    func mpPlayerLoadStateDidChange(notification:NSNotification)
    {
        let player = notification.object as! MPMoviePlayerController
        
        /* Enough data has been buffered for playback to continue uninterrupted. */
        
        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
        let loadvalue:UInt8 = UInt8(MPMovieLoadState.PlaythroughOK.rawValue)

        // If there is a sermon that was playing before and we want to start back at the same place, 
        // the PlayPause button must NOT be active until loadState & PlaythroughOK == 1.
        
//        println("\(loadstate)")
//        println("\(loadvalue)")
        
        if ((loadstate & loadvalue) == (1<<1)) {
            print("AppDelegate mpPlayerLoadStateDidChange.MPMovieLoadState.PlaythroughOK")
            //should be called only once, only for  first time audio load.
            if(!Globals.sermonLoaded) {
                let defaults = NSUserDefaults.standardUserDefaults()
                let currentTime = Float(defaults.stringForKey(Constants.CURRENT_TIME)!)

                print("\(currentTime!)")
                print("\(NSTimeInterval(currentTime!))")

                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(currentTime!)
                
                print("\(Globals.mpPlayer!.currentPlaybackTime)")
                
                //iPad
                if let rvc = self.window?.rootViewController as? UISplitViewController {
                    //            println("rvc = UISplitViewController")
                    if let nvc = rvc.viewControllers[1] as? UINavigationController {
                        if let myvc = nvc.topViewController as? MyViewController {
                            //                    println("myvc = MyViewController")
                            myvc.spinner.stopAnimating()
                        }
                    }
                }

                //iPhone
                if let rvc = self.window?.rootViewController as? UINavigationController {
                    //            println("rvc = UINavigationController")
                    if let myvc = rvc.topViewController as? MyViewController {
                        //                    println("myvc = MyViewController")
                        myvc.spinner.stopAnimating()
                    }
                }

                Globals.sermonLoaded = true
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
   
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool
    {
//        println("application:openURL")

        let host = url.host

        //Never used
//        let scheme = url.scheme
//        let path = url.path
//        let query = url.query
        
//        println("Host: \(host) Scheme: \(scheme) Path: \(path) Query: \(query)")
//        println("BaseURL: \(url.baseURL) PathComponents: \(url.pathComponents)")
//        println("AbsoluteURL: \(url.absoluteURL) PathExtension: \(url.pathExtension) RelativePath: \(url.relativePath)")
        
        //Why does this work without having to determine whether the app is sufficiently loaded to
        //allow deep linking?
        
        var selectedSeries:Series?
        
        for series in Globals.series! {
            if (series.name == host) {
                selectedSeries = series
                break
            }
        }

        //iPad
        if let svc = self.window?.rootViewController as? UISplitViewController {
            //            println("rvc = UISplitViewController")
            if let nvc = svc.viewControllers[0] as? UINavigationController {
                //                println("nvc = UINavigationController")
                if let cvc = nvc.topViewController as? MyCollectionViewController {
                    //                    println("nvc = MyCollectionViewController")
                    if (selectedSeries != nil) {
                        Globals.seriesSelected = selectedSeries
                        cvc.performSegueWithIdentifier(Constants.Show_Series, sender: cvc)
                    }
                }
            }
        }
        
        //iPhone
        if let nvc = self.window?.rootViewController as? UINavigationController {
            //     _   println("rvc = UINavigationController")
            if let _ = nvc.topViewController as? MyViewController {
                //                    println("myvc = MyViewController")

                nvc.popToRootViewControllerAnimated(true)
            }

            if let cvc = nvc.topViewController as? MyCollectionViewController {
                //                println("cvc = MyCollectionViewController")
                
                if (selectedSeries != nil) {
                    Globals.seriesSelected = selectedSeries
                    cvc.performSegueWithIdentifier(Constants.Show_Series, sender: cvc)
                }
            }
        }

        return true
    }
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
//        println("application:didFinishLaunchingWithOptions")

        // Override point for customization after application launch.
                
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        do {
            //        audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error:nil)
            try audioSession.setActive(true)
        } catch _ {
        }

        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()

        let seriesDicts = loadSeriesDictsFromJSON()
        Globals.series = seriesFromSeriesDicts(seriesDicts)
        
        loadDefaults()

        Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)
        
        setupSermonPlaying()
        
        return true
    }

    
    func setupSermonPlaying()
    {
        setupPlayer(Globals.sermonPlaying)
        
        if (!Globals.sermonLoaded) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        }
    }

    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        println("applicationWillResignActive")
        setupPlayingInfoCenter()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        println("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        println("applicationWillEnterForeground")
        
        setupPlayingInfoCenter()

        if (Globals.mpPlayer?.currentPlaybackRate == 0) {
            //It is paused, possibly not by us, but by the system
            //But how do we know it hasn't simply finished playing?
            if (Globals.sermonLoaded) {
                updateUserDefaultsCurrentTimeExact()
            }
            Globals.playerPaused = true
        } else {
            Globals.playerPaused = false
        }
        
        //Need to restore slider and play Timers
        
        //iPad
        if let rvc = self.window?.rootViewController as? UISplitViewController {
            //            println("rvc = UISplitViewController")
            if let nvc = rvc.viewControllers[0] as? UINavigationController {
                //                println("nvc = UINavigationController")
                if let cvc = nvc.topViewController as? MyCollectionViewController {
                    //                    println("nvc = MyCollectionViewController")
                    cvc.setupPlayingPausedButton()
                    cvc.collectionView.reloadData()
                }
            }
            if let nvc = rvc.viewControllers[1] as? UINavigationController {
                if let myvc = nvc.topViewController as? MyViewController {
                    //                    println("myvc = MyViewController")
                    myvc.setupPlayPauseButton()
                }
            }
        }
        
        //iPhone
        if let rvc = self.window?.rootViewController as? UINavigationController {
            //            println("rvc = UINavigationController")
            if let cvc = rvc.topViewController as? MyCollectionViewController {
                //                println("cvc = MyCollectionViewController")
                cvc.setupPlayingPausedButton()
                cvc.collectionView.reloadData()
            }
            if let myvc = rvc.topViewController as? MyViewController {
                //                    println("myvc = MyViewController")
                myvc.setupPlayPauseButton()
            }
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
//        println("applicationDidBecomeActive")
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
        
        for series in Globals.series! {
            for sermon in series.sermons! {
                if (sermon.id == Int(filename!)) {
                    sermon.download.session = NSURLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
                    sermon.download.completionHandler = completionHandler
                    //Do we need to recreate the downloadTask for this session?
                }
            }
        }
    }
}

