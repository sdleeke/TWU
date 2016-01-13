//
//  MyCollectionViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class MyCollectionViewController: UIViewController, UISplitViewControllerDelegate, UICollectionViewDelegate, UISearchBarDelegate, NSURLSessionDownloadDelegate {

//    var endObserver: AnyObject?

    var refreshControl:UIRefreshControl?

    var seriesSelected:Series?

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
//    var resultSearchController:UISearchController?

    var session:NSURLSession? // Used for JSON

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.sermonPlaying != nil) {
                if (Globals.playerPaused) {
                    Globals.mpPlayer?.play()
                } else {
                    Globals.mpPlayer?.pause()
                    updateUserDefaultsCurrentTimeExact()
                }
                Globals.playerPaused = !Globals.playerPaused
            } else {
                
            }
        }
    }

    func sorting(button:UIBarButtonItem?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        let alert = UIAlertController(title: Constants.Sorting_Options_Title,
            message: Constants.EMPTY_STRING,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var action : UIAlertAction
        
        var alertTitle:String = Constants.EMPTY_STRING
        
        for option in Constants.Sorting_Options {
            alertTitle = option
//            if (Globals.sorting == option) {
//                alertTitle = Constants.CHECKMARK + Constants.SINGLE_SPACE_STRING + alertTitle
//            }
            action = UIAlertAction(title: alertTitle, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                if (Globals.sorting != option) {
                    Globals.sorting = option
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setObject(option,forKey: Constants.SORTING)
                    defaults.synchronize()
                    
                    //                sortAndGroupSermons()
                    
                    Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)
                    self.collectionView.reloadData()
                    
                    //Moving the list can be very disruptive
                    //                selectOrScrollToSermon(selectedSermon, select: true, scroll: false, position: UITableViewScrollPosition.None)
                }
            })
            if (Globals.sorting == option) {
                action.enabled = false
            }
            alert.addAction(action)
        }
        
        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        //on iPad this is a popover
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        alert.popoverPresentationController?.barButtonItem = button //as? UIBarButtonItem
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func filtering(button:UIBarButtonItem?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        let alert = UIAlertController(title: Constants.Filtering_Options_Title,
            message: Constants.EMPTY_STRING,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var action : UIAlertAction
        
        var alertTitle:String = Constants.EMPTY_STRING
        
        if var books = booksFromSeries(Globals.series) {
            books.append(Constants.All)
            for book in books {
                alertTitle = book
                action = UIAlertAction(title: alertTitle, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    if (Globals.filter != book) {
                        let defaults = NSUserDefaults.standardUserDefaults()
                        defaults.setObject(book,forKey: Constants.FILTER)
                        defaults.synchronize()
                        
                        self.searchBar.placeholder = book

                        if (book == Constants.All) {
                            Globals.showing = .all
                            Globals.filter = nil
                        } else {
                            Globals.showing = .filtered
                            Globals.filter = book
                        }
                        
                        if Globals.searchActive {
                            self.updateSearchResults()
                        }

                        Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)
                        self.collectionView.reloadData()
                        
                        //Moving the list can be very disruptive
                        //                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: false, position: UITableViewScrollPosition.None)
                    }
                })

                if (Globals.showing == .filtered) && (Globals.filter == book) {
                    action.enabled = false
                }
                if (Globals.showing == .all) && (Globals.filter == nil) && (book == Constants.All) {
                    action.enabled = false
                }

                alert.addAction(action)
            }
        }
        
        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        //on iPad this is a popover
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        alert.popoverPresentationController?.barButtonItem = button //as? UIBarButtonItem
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Sorting, style: UIBarButtonItemStyle.Plain, target: self, action: "sorting:")
        let filterButton = UIBarButtonItem(title: Constants.Filter, style: UIBarButtonItemStyle.Plain, target: self, action: "filtering:")
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        
        var barButtons = [UIBarButtonItem]()
        
        barButtons.append(spaceButton)
        
        barButtons.append(sortingButton)
        
        barButtons.append(spaceButton)

        barButtons.append(filterButton)
        
        barButtons.append(spaceButton)
        
        navigationController?.toolbar.translucent = false
        navigationController?.toolbarHidden = false // If this isn't here a colleciton view in an iPad master view controller will NOT show the toolbar - even though it will show in the navigation controller on an iPhone if this occurs in viewWillAppear()
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func updateSearchResults()
    {
        if (searchBar.text != "") {
            Globals.searchSeries = nil
            
            var searchSeries = [Series]()
            
            for series in Globals.seriesToSearch! {
                if (((series.title.rangeOfString(searchBar.text!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                    ((series.scripture.rangeOfString(searchBar.text!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)) {
                        searchSeries.append(series)
                }
            }
            
            Globals.searchSeries = searchSeries
            
        } else {
            Globals.searchSeries = Globals.series
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        println("Text changed: \(searchText)")
        
        updateSearchResults()
        
        collectionView!.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if (!Globals.searchActive) {
            Globals.searchActive = true
            searchBar.showsCancelButton = true
            updateSearchResults()
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        println("Search clicked!")
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        println("Cancel clicked!")
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil

        Globals.searchSeries = nil
        Globals.searchActive = false
        
        Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)
        
        collectionView!.reloadData()
    }
    
    func applicationWillResignActive(notification:NSNotification)
    {
        print("MyCollectionViewController.applicationWillResignActive")
    }
    
    func applicationWillEnterForeground(notification:NSNotification)
    {
        if (Globals.mpPlayer?.currentPlaybackRate == 0) {
            //It is paused, possibly not by us, but by the system
            //But how do we know it hasn't simply finished playing?
            updateUserDefaultsCurrentTimeExact()
            Globals.playerPaused = true
        } else {
            Globals.playerPaused = false
        }
        
        setupPlayingPausedButton()
    }

    private func setupSearchBar()
    {
        switch Globals.showing {
        case .all:
            searchBar.placeholder = "All"
            break
        case .filtered:
            searchBar.placeholder = Globals.filter
            break
        }
    }
    
    
    func setupTitle()
    {
        self.navigationController?.toolbarHidden = false
        self.navigationItem.title = Constants.TWU_LONG
    }
    
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
                
                if let nvc = self.splitViewController?.viewControllers[1] as? UINavigationController {
                    //iPad
                    if let myvc = nvc.topViewController as? MyViewController {
                        //                    println("myvc = MyViewController")
                        myvc.spinner.stopAnimating()
                    }
                } else {
                    //iPhone
                    if let myvc = self.navigationController?.topViewController as? MyViewController {
                        //                    println("myvc = MyViewController")
                        myvc.spinner.stopAnimating()
                    }
                }
                
                Globals.sermonLoaded = true
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    func setupSermonPlaying()
    {
        setupPlayer(Globals.sermonPlaying)
        
        if (!Globals.sermonLoaded) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        } else {
            setupTitle()
        }
    }
    
    func setupViews()
    {
        var mycvc:MyCollectionViewController?
        var myvc:MyViewController?
        
        if let svc = self.splitViewController {
            //iPad
            if let nvc = svc.viewControllers[0] as? UINavigationController {
                mycvc = nvc.topViewController as? MyCollectionViewController
            }
            if let nvc = svc.viewControllers[1] as? UINavigationController {
                myvc = nvc.topViewController as? MyViewController
            }
        } else {
            mycvc = self.navigationController?.topViewController as? MyCollectionViewController
            myvc = self.navigationController?.topViewController as? MyViewController
        }
        
        mycvc?.seriesSelected = Globals.seriesSelected

        if (mycvc != nil) {
            mycvc?.setupSearchBar()
            mycvc?.collectionView.reloadData()
            mycvc?.enableBarButtons()
            mycvc?.setupTitle()
            mycvc?.setupPlayingPausedButton()
            
            if (mycvc!.seriesSelected != nil) && (Globals.activeSeries?.indexOf(mycvc!.seriesSelected!) != nil) {
                print("\(Globals.activeSeries!.indexOf(mycvc!.seriesSelected!))")
                let indexPath = NSIndexPath(forItem: Globals.activeSeries!.indexOf(mycvc!.seriesSelected!)!, inSection: 0)
                mycvc?.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
            }
        }

        if (myvc != nil) {
            myvc?.seriesSelected = mycvc?.seriesSelected

            myvc?.sermonSelected = Globals.sermonSelected

            myvc?.updateUI()
            
            myvc?.scrollToSermon(myvc?.sermonSelected,select:true,position:UITableViewScrollPosition.Top)
        }

    }
    
    func loadSeries(completion: (() -> Void)?)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Sermons"
            })
            
            var success = false
            
            if let seriesDicts = loadSeriesDictsFromJSON() {
                if let series = seriesFromSeriesDicts(seriesDicts) {
                    Globals.series = series
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.navigationItem.title = "Loading Defaults"
                    })
                    loadDefaults()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.navigationItem.title = "Sorting"
                    })
                    Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)

                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.navigationItem.title = "Setting up Player"
                        self.setupSermonPlaying()
                    })
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.setupViews()
                    })
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion?()
                    })
                    success = true
                }
            }
            
            if (!success) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.setupTitle()
                    self.refreshControl?.endRefreshing()
                    
                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                        let alert = UIAlertController(title:"Unable to Load Sermons",
                            message: "Please try to refresh the list or send an email to support@countrysidebible.org to report the problem.",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                })
                return
            }
            
        })
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("URLSession: \(session.description) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    {
        var success = false
        
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) location: \(location)")
        
        if (downloadTask.countOfBytesExpectedToReceive > 0) {
            let fileManager = NSFileManager.defaultManager()
            
            //Get documents directory URL
            if let destinationURL = documentsURL()?.URLByAppendingPathComponent(filename) {
                // Check if file exist
                if (fileManager.fileExistsAtPath(destinationURL.path!)){
                    do {
                        try fileManager.removeItemAtURL(destinationURL)
                    } catch _ {
                        print("failed to remove old json file")
                    }
                }
                
                do {
                    try fileManager.copyItemAtURL(location, toURL: destinationURL)
                    try fileManager.removeItemAtURL(location)
                    success = true
                } catch _ {
                    print("failed to copy new json file to Documents")
                }
            }
        }
        
        if success {
            // ONLY flush and refresh the data once we know we have successfully downloaded the new JSON
            // file and successfully copied it to the Documents directory.
            
            // URL call back does NOT run on the main queue
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                
                updateUserDefaultsCurrentTimeExact()
//                saveSermonSettings()
                
                Globals.mpPlayer?.view.hidden = true
                Globals.mpPlayer?.view.removeFromSuperview()
                
                self.loadSeries() {
                    self.refreshControl?.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            })
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                    let alert = UIAlertController(title:"Unable to Download Sermons",
                        message: "Please try to refresh the list again or send an email to support@countrysidebible.org to report the problem.",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                
                self.refreshControl!.endRefreshing()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.setupTitle()
                
                self.collectionView.reloadData()
                self.setupViews()
            })
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if (error != nil) {
            print("Download failed for: \(session.description)")
        } else {
            print("Download succeeded for: \(session.description)")
        }
        
        //        removeTempFiles()
        
        let filename = task.taskDescription
        print("filename: \(filename!) error: \(error)")
        
        session.invalidateAndCancel()
        
        //        if let taskIndex = Globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
        //            Globals.downloadTasks.removeAtIndex(taskIndex)
        //        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
    }
    
    func downloadJSON()
    {
        navigationItem.title = Constants.DOWNLOADING_TITLE
        
        let jsonURL = "\(Constants.JSON_URL_PREFIX)\(Constants.TWU_SHORT.lowercaseString).\(Constants.SERIES_JSON)"
        let downloadRequest = NSMutableURLRequest(URL: NSURL(string: jsonURL)!)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session?.downloadTaskWithRequest(downloadRequest)
        downloadTask?.taskDescription = Constants.SERIES_JSON
        
        downloadTask?.resume()
        
        //downloadTask goes out of scope but Globals.session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func cancelAllDownloads()
    {
        if (Globals.series != nil) {
            for series in Globals.series! {
                for sermon in series.sermons! {
                    if sermon.download.active {
                        sermon.download.task?.cancel()
                        sermon.download.task = nil
                        
                        sermon.download.totalBytesWritten = 0
                        sermon.download.totalBytesExpectedToWrite = 0
                        
                        sermon.download.state = .none
                    }
                }
            }
        }
    }
    
    func disableToolBarButtons()
    {
        if let barButtons = toolbarItems {
            for barButton in barButtons {
                barButton.enabled = false
            }
        }
    }
    
    func disableBarButtons()
    {
        navigationItem.leftBarButtonItem?.enabled = false
        navigationItem.rightBarButtonItem?.enabled = false
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        if (Globals.series != nil) {
            if let barButtons = toolbarItems {
                for barButton in barButtons {
                    barButton.enabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        if (Globals.series != nil) {
            navigationItem.leftBarButtonItem?.enabled = true
            navigationItem.rightBarButtonItem?.enabled = true
            enableToolBarButtons()
        }
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        cancelAllDownloads()
        
        self.searchBar.placeholder = nil
        Globals.filter = nil
        Globals.activeSeries = nil
        collectionView.reloadData()
        
        if let svc = self.splitViewController {
            //iPad
            if let nvc = svc.viewControllers[1] as? UINavigationController {
                if let myvc = nvc.topViewController as? MyViewController {
                    myvc.seriesSelected = nil
                    myvc.sermonSelected = nil
                    myvc.updateUI()
                }
            }
        }
        
        disableBarButtons()
        
        downloadJSON()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible //iPad only
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: Selector("handleRefresh:"), forControlEvents: UIControlEvents.ValueChanged)

        collectionView.addSubview(refreshControl!)
        
        collectionView.alwaysBounceVertical = true

        setupPlayingPausedButton()
        
        collectionView?.allowsSelection = true

        setupSortingAndGroupingOptions()
    }
    
    func setPlayingPausedButton()
    {
        var title:String = ""
        
        if (Globals.playerPaused) {
            title = Constants.Paused
        } else {
            title = Constants.Playing
        }
        
        var playingPausedButton = navigationItem.rightBarButtonItem
        
        if (playingPausedButton == nil) {
            playingPausedButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: "gotoNowPlaying")
        }
        
        playingPausedButton!.title = title

        navigationItem.setRightBarButtonItem(playingPausedButton, animated: true)
    }

    func setupPlayingPausedButton()
    {
        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) {
            if (!Globals.showingAbout) {
                if (splitViewController != nil) && (Globals.seriesSelected == Globals.sermonPlaying?.series) {
                    if (Globals.sermonSelected != Globals.sermonPlaying) {
                        setPlayingPausedButton()
                    } else {
                        if (navigationItem.rightBarButtonItem != nil) {
                            navigationItem.setRightBarButtonItem(nil, animated: true)
                        }
                    }
                } else {
                    setPlayingPausedButton()
                }
            } else {
                setPlayingPausedButton()
            }
        } else {
            if (navigationItem.rightBarButtonItem != nil) {
                navigationItem.setRightBarButtonItem(nil, animated: true)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.toolbarHidden = false

        if (Globals.searchActive) {
            searchBar.becomeFirstResponder()
        }
        
        //Unreliable
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible //iPad only

        setupPlayingPausedButton()
        
        collectionView.reloadData()
    }
    
    func collectionView(_: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var size:CGFloat = 0.0

        var index = 1
        
        repeat {
            size = (view.bounds.width - CGFloat(10*(index+1)))/CGFloat(index)
            index++
        } while (size > min(view.bounds.height,view.bounds.width)/1.5)

//        print("Size: \(size)")
//        print("\(UIDevice.currentDevice().model)")
        
        return CGSizeMake(size, size)
    }
    
    func about()
    {
        performSegueWithIdentifier(Constants.Show_About, sender: self)
    }
    
//    func addEndObserver() {
////        if (Globals.seriesPlaying != nil) {
////            if (Globals.player != nil) {
////                if (Globals.player!.currentItem != nil) {
////                    endObserver = Globals.player!.addBoundaryTimeObserverForTimes([CMTimeGetSeconds(Globals.player!.currentItem.asset.duration)], queue: dispatch_get_main_queue()) { () -> Void in
////                        //                    navigationItem.setRightBarButtonItem(nil, animated: true)
////                    }
////                }
////            }
////        }
//    }
//    
//    func removeEndObserver()
//    {
////        if (endObserver != nil) {
////            Globals.player?.removeTimeObserver(endObserver)
////            endObserver = nil
////        }
//    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        remoteControlEvent(event!)
        if let nvc = splitViewController?.viewControllers[1] as? UINavigationController {
            if let myvc = nvc.topViewController as? MyViewController {
                myvc.setupPlayPauseButton()
            }
        }
        setupPlayingPausedButton()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if Globals.series == nil {
            disableBarButtons()
            loadSeries(nil)
        }

//        setupPlayingInfoCenter()

//        addEndObserver()
        
//        addEndPlayObserver()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (splitViewController == nil) {
            navigationController?.toolbarHidden = true
        }

//        UIApplication.sharedApplication().endReceivingRemoteControlEvents()

//        removeEndObserver()
        
//        removeEndPlayObserver()
        
//        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
//        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destinationViewController as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.Show_About:
                //The block below only matters on an iPad
                Globals.showingAbout = true
                setupPlayingPausedButton()
                break
                
            case Constants.Show_Series:
//                println("ShowSeries")
                if (Globals.gotoNowPlaying) {
//                    Globals.seriesSelectedIndex = Globals.seriesPlayingIndex
                    
                    //This pushes a NEW MyViewController.
                    
                    Globals.seriesSelected = Globals.sermonPlaying?.series
                    Globals.sermonSelected = Globals.sermonPlaying
                    
                    Globals.gotoNowPlaying = !Globals.gotoNowPlaying
                    navigationItem.setRightBarButtonItem(nil, animated: true)
                } else {
                    if let myCell = sender as? MyCollectionViewCell {
                        let indexPath = collectionView!.indexPathForCell(myCell)
                        Globals.seriesSelected = Globals.activeSeries?[indexPath!.row]
                    }

                    if (Globals.seriesSelected != nil) {
                        if (splitViewController != nil) { //iPad only
                            //The block below only matters on an iPad
                            setupPlayingPausedButton()
                        }
                    }
                }

                if let dvc = destination as? MyViewController {
                    dvc.seriesSelected = Globals.seriesSelected
                    dvc.sermonSelected = Globals.sermonSelected?.series == Globals.seriesSelected ? Globals.sermonSelected : nil
                }
                
                setupSeriesSelectedUserDefaults()
                break
                
            default:
                break
            }
        }

    }
    
    private func setupSeriesSelectedUserDefaults()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if (Globals.seriesSelected != nil) {
            defaults.setObject("\(Globals.seriesSelected!.id)", forKey: Constants.SERIES_SELECTED)
            defaults.removeObjectForKey(Constants.SERMON_SELECTED_INDEX)
            //
            //            println("seriesSelectedIndex: \(Globals.seriesSelectedIndex)")
        }
        
        defaults.synchronize()
    }
    
    func gotoNowPlaying()
    {
//        println("gotoNowPlaying")
        
        Globals.gotoNowPlaying = true
        
        performSegueWithIdentifier(Constants.Show_Series, sender: self)
    }
    
    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        //return series[section].count
        return Globals.activeSeries != nil ? Globals.activeSeries!.count : 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> MyCollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.SERIES_CELL_IDENTIFIER, forIndexPath: indexPath) as! MyCollectionViewCell
    
        // Configure the cell
        cell.series = Globals.activeSeries?[indexPath.row]

        return cell
    }

    // MARK: UICollectionViewDelegate
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        println("didSelect")

//        if let cell: MyCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as? MyCollectionViewCell {
//
//        } else {
//            
//        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        println("didDeselect")

//        if let cell: MyCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as? MyCollectionViewCell {
//
//        } else {
//            
//        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    */
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
//        println("shouldHighlight")
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
//        println("Highlighted")
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
//        println("Unhighlighted")
    }
    
    /*
    // Uncomment this method to specify if the specified item should be selected
    */
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
//        println("shouldSelect")
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
//        println("shouldDeselect")
        return true
    }
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
}
