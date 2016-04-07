//
//  MediaCollectionViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class MediaCollectionViewController: UIViewController, UISplitViewControllerDelegate, UICollectionViewDelegate, UISearchBarDelegate, NSURLSessionDownloadDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

//    var endObserver: AnyObject?

    var refreshControl:UIRefreshControl?

    var seriesSelected:Series? {
        didSet {
//            globals.seriesSelected = seriesSelected
            if (seriesSelected != nil) {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject("\(seriesSelected!.id)", forKey: Constants.SERIES_SELECTED)
                defaults.synchronize()

                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                })
            } else {
                print("MediaCollectionViewController:seriesSelected nil")
            }
        }
    }

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
//    var resultSearchController:UISearchController?

    var session:NSURLSession? // Used for JSON

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (globals.sermonPlaying != nil) {
                if (globals.playerPaused) {
                    globals.mpPlayer?.play()
                } else {
                    globals.mpPlayer?.pause()
                    globals.updateCurrentTimeExact()
                }
                globals.playerPaused = !globals.playerPaused
            } else {
                
            }
        }
    }

    func sorting(button:UIBarButtonItem?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Sorting_Options_Title
                
                popover.delegate = self
                
                popover.purpose = .selectingSorting
                popover.strings = Constants.Sorting_Options
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }

//        let alert = UIAlertController(title: Constants.Sorting_Options_Title,
//            message: Constants.EMPTY_STRING,
//            preferredStyle: UIAlertControllerStyle.ActionSheet)
//        
//        var action : UIAlertAction
//        
//        var alertTitle:String = Constants.EMPTY_STRING
//        
//        for option in Constants.Sorting_Options {
//            alertTitle = option
//            action = UIAlertAction(title: alertTitle, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                if (globals.sorting != option) {
//                    globals.sorting = option
//                    
//                    globals.activeSeries = sortSeries(globals.activeSeries,sorting: globals.sorting)
//                    self.collectionView.reloadData()
//                    
//                    //Moving the list can be very disruptive
//                    //                selectOrScrollToSermon(selectedSermon, select: true, scroll: false, position: UITableViewScrollPosition.None)
//                }
//            })
//            if (globals.sorting == option) {
//                action.enabled = false
//            }
//            alert.addAction(action)
//        }
//        
//        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
//            
//        })
//        alert.addAction(action)
//        
//        //on iPad this is a popover
//        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
//        alert.popoverPresentationController?.barButtonItem = button //as? UIBarButtonItem
//        
//        presentViewController(alert, animated: true, completion: nil)
    }
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        switch purpose {
        case .selectingSorting:
            globals.sorting = strings[index]
            collectionView.reloadData()
            break
            
        case .selectingFiltering:
            if (globals.filter != strings[index]) {
                self.searchBar.placeholder = strings[index]
                
                if (strings[index] == Constants.All) {
                    globals.showing = .all
                    globals.filter = nil
                } else {
                    globals.showing = .filtered
                    globals.filter = strings[index]
                }
                
                self.collectionView.reloadData()
                
                let indexPath = NSIndexPath(forItem:0,inSection:0)
                self.collectionView.scrollToItemAtIndexPath(indexPath,atScrollPosition:UICollectionViewScrollPosition.CenteredVertically, animated: true)
            }
            break
            
        case .selectingShow:
            break
            
        default:
            break
        }
    }
    
    func filtering(button:UIBarButtonItem?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Filtering_Options_Title
                
                popover.delegate = self
                
                popover.purpose = .selectingFiltering
                popover.strings = booksFromSeries(globals.series)
                popover.strings?.insert(Constants.All, atIndex: 0)
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }

//        let alert = UIAlertController(title: Constants.Filtering_Options_Title,
//            message: Constants.EMPTY_STRING,
//            preferredStyle: UIAlertControllerStyle.ActionSheet)
//        
//        var action : UIAlertAction
//        
//        var alertTitle:String = Constants.EMPTY_STRING
//        
//        if var books = booksFromSeries(globals.series) {
//            books.append(Constants.All)
//            for book in books {
//                alertTitle = book
//                action = UIAlertAction(title: alertTitle, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    if (globals.filter != book) {
//                        self.searchBar.placeholder = book
//                        
//                        if (book == Constants.All) {
//                            globals.showing = .all
//                            globals.filter = nil
//                        } else {
//                            globals.showing = .filtered
//                            globals.filter = book
//                        }
//                        
//                        globals.activeSeries = sortSeries(globals.activeSeries,sorting: globals.sorting)
//                        self.collectionView.reloadData()
//                        
//                        let indexPath = NSIndexPath(forItem:0,inSection:0)
//                        self.collectionView.scrollToItemAtIndexPath(indexPath,atScrollPosition:UICollectionViewScrollPosition.CenteredVertically, animated: true)
//                    }
//                })
//                
//                if (globals.showing == .filtered) && (globals.filter == book) {
//                    action.enabled = false
//                }
//                if (globals.showing == .all) && (globals.filter == nil) && (book == Constants.All) {
//                    action.enabled = false
//                }
//                
//                alert.addAction(action)
//            }
//        }
//        
//        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
//            
//        })
//        alert.addAction(action)
//        
//        //on iPad this is a popover
//        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
//        alert.popoverPresentationController?.barButtonItem = button //as? UIBarButtonItem
//        
//        presentViewController(alert, animated: true, completion: nil)
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

    func settings(button:UIBarButtonItem?)
    {
        dismissViewControllerAnimated(true, completion: nil)
        performSegueWithIdentifier(Constants.Show_Settings, sender: nil)
    }
    
    private func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Sort, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MediaCollectionViewController.sorting(_:)))
        let filterButton = UIBarButtonItem(title: Constants.Filter, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MediaCollectionViewController.filtering(_:)))
        let settingsButton = UIBarButtonItem(title: Constants.Settings, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MediaCollectionViewController.settings(_:)))
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        
        var barButtons = [UIBarButtonItem]()
        
        barButtons.append(spaceButton)
        
        barButtons.append(sortingButton)
        
        barButtons.append(spaceButton)

        barButtons.append(filterButton)
        
        barButtons.append(spaceButton)
        
        barButtons.append(settingsButton)
        
        barButtons.append(spaceButton)
        
        navigationController?.toolbar.translucent = false
        navigationController?.toolbarHidden = false // If this isn't here a colleciton view in an iPad master view controller will NOT show the toolbar - even though it will show in the navigation controller on an iPhone if this occurs in viewWillAppear()
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func sermonUpdateAvailable()
    {
        if (navigationController?.visibleViewController == self) {
            var title:String?
            
            switch UIApplication.sharedApplication().applicationIconBadgeNumber {
            case 0:
                // Error
                return
                
            case 1:
                title = Constants.Sermon_Update_Available
                break
                
            default:
                title = Constants.Sermon_Updates_Available
                break
            }
            
            let alert = UIAlertController(title:title,
                message: nil,
                preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let updateAction = UIAlertAction(title: Constants.REMOTE_NOTIFICATION_NOW_ACTION_TITLE, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                self.handleRefresh(self.refreshControl!)
            })
            alert.addAction(updateAction)
            
            //        if (!Reachability.isConnectedToNetwork()) {
            //            updateAction.enabled = false
            //        }
            
            let laterAction = UIAlertAction(title: Constants.REMOTE_NOTIFICATION_LATER_ACTION_TITLE, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(laterAction)
            
            let cancelAction = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(cancelAction)
            
            alert.modalPresentationStyle = UIModalPresentationStyle.Popover
            
            alert.popoverPresentationController?.sourceView = self.searchBar
            alert.popoverPresentationController?.sourceRect = self.searchBar.frame
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool
    {
        return !globals.loading && !globals.refreshing && (globals.series != nil)
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        println("Text changed: \(searchText)")
        
        globals.searchButtonClicked = false
        
        globals.searchText = searchBar.text
        
        collectionView!.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        globals.searchButtonClicked = false

        if (!globals.searchActive) {
            globals.searchActive = true
            searchBar.showsCancelButton = true
            
            globals.searchText = searchBar.text
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        println("Search clicked!")
        globals.searchButtonClicked = true
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        println("Cancel clicked!")
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil

        globals.searchText = nil
        globals.searchSeries = nil
        globals.searchActive = false
        
        collectionView!.reloadData()
    }
    
    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
        //        print("searchBarResultsListButtonClicked")
        
        if !globals.loading && !globals.refreshing && (globals.series != nil) && (self.storyboard != nil) {
//            popover = storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? PopoverTableViewController
//            
//            popover?.modalPresentationStyle = .Popover
//            //            popover?.preferredContentSize = CGSizeMake(300, 500)
//            
//            popover?.popoverPresentationController?.permittedArrowDirections = .Up
//            popover?.popoverPresentationController?.delegate = self
//            
//            popover?.popoverPresentationController?.sourceView = searchBar
//            popover?.popoverPresentationController?.sourceRect = searchBar.bounds
//            
//            popover?.delegate = self
//            popover?.purpose = .selectingTags
//            popover?.strings = globals.sermons.all?.sermonTags
//            
//            popover?.strings?.append(Constants.All)
//            
//            if (popover != nil) {
//                presentViewController(popover!, animated: true, completion: nil)
//            }
        }
    }

    private func setupSearchBar()
    {
        switch globals.showing {
        case .all:
            searchBar.placeholder = Constants.All
            break
        case .filtered:
            searchBar.placeholder = globals.filter
            break
        }
    }
    
    func setupTitle()
    {
        if (!globals.loading && !globals.refreshing) {
            self.navigationController?.toolbarHidden = false
            self.navigationItem.title = Constants.TWU_LONG
        }
    }
    
    func scrollToSeries(series:Series?)
    {
        if (seriesSelected != nil) && (globals.activeSeries?.indexOf(series!) != nil) {
            let indexPath = NSIndexPath(forItem: globals.activeSeries!.indexOf(series!)!, inSection: 0)
            
            //Without this background/main dispatching there isn't time to scroll after a reload.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: true)
                })
            })
        }
    }
    
    func setupViews()
    {
        setupSearchBar()
        
        collectionView.reloadData()
        
        enableBarButtons()
        
        setupTitle()
        
        setupPlayingPausedButton()
        
        scrollToSeries(seriesSelected)
        
        if (splitViewController != nil) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
            })
        }
    }
    
    func loadSeries(completion: (() -> Void)?)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            globals.loading = true

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.Loading_Sermons
            })
            
            var success = false
            var newSeries:[Series]?
            var newSeriesIndex = [Int:Series]()
            
            if let seriesDicts = loadSeriesDictsFromJSON() {
                if let series = seriesFromSeriesDicts(seriesDicts) {
                    newSeries = series
                    for newSermonSeries in newSeries! {
                        newSeriesIndex[newSermonSeries.id] = newSermonSeries
                    }
                    success = true
                }
            }
            
            if (!success) {
                // REVERT TO KNOWN GOOD JSON
                removeJSONFromFileSystemDirectory() // This will cause JSON to be loaded from the BUNDLE next time.
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.setupTitle()
                    self.refreshControl?.endRefreshing()
                    
                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                        let alert = UIAlertController(title:Constants.Unable_to_Load_Sermons,
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
            
            var seriesNewToUser:[Series]?
            var sermonsNewToUser = [Int:Int]()
            
//            print("\(globals.series?.count)")

            if globals.series != nil {
                let old = Set(globals.series!.map({ (series:Series) -> Int in
                    return series.id
                }))
                
                let new = Set(newSeries!.map({ (series:Series) -> Int in
                    return series.id
                }))
                
                let onlyInNew = new.subtract(old)
                
                if (onlyInNew.count > 0) {
                    seriesNewToUser = onlyInNew.map({ (id:Int) -> Series in
                        return newSeriesIndex[id]!
                    })
                } else {
                    for oldSeries in globals.series! {
                        if (newSeriesIndex[oldSeries.id]!.show - oldSeries.show) != 0 {
                            sermonsNewToUser[oldSeries.id] = newSeriesIndex[oldSeries.id]!.show - oldSeries.show
                        }
                    }
                }
            }
            
            globals.series = newSeries
            
            self.seriesSelected = globals.seriesSelected

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.Loading_Defaults
            })
            globals.loadDefaults()

            //Handled in didSet's when defaults are loaded.
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.navigationItem.title = Constants.Sorting
//            })
//            globals.activeSeries = sortSeries(globals.activeSeries,sorting: globals.sorting)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.Setting_up_Player
                globals.playOnLoad = false
                globals.setupPlayer(globals.sermonPlaying)
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.TWU_LONG
                self.setupViews()
            })
            
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var message:String?
                    
                    if (seriesNewToUser != nil) && (seriesNewToUser!.count > 0) {
                        if (globals.filter == nil) {
                            if (globals.sorting != Constants.Newest_to_Oldest) && (globals.sorting != Constants.Oldest_to_Newest) {
                                if (seriesNewToUser!.count == 1) {
                                    message = "Change sorting to Newest to Oldest or Oldest to Newest to see the new sermon series \"\(seriesNewToUser!.first!.title!)\" at the beginning or end of the list."
                                }
                                if (seriesNewToUser!.count > 1) {
                                    message = "Change sorting to Newest to Oldest or Oldest to Newest to see the \(seriesNewToUser!.count) new sermon series at the beginning or end of the list."
                                }
                            }
                            if (globals.sorting == Constants.Newest_to_Oldest) {
                                if (seriesNewToUser!.count == 1) {
                                    message = "The new sermon series \"\(seriesNewToUser!.first!.title!)\" is at the beginning of the list."
                                }
                                if (seriesNewToUser!.count > 1) {
                                    message = "There are \(seriesNewToUser!.count) new sermon series at the beginning of the list."
                                }
                            }
                            if (globals.sorting == Constants.Oldest_to_Newest) {
                                if (seriesNewToUser!.count == 1) {
                                    message = "The new sermon series \"\(seriesNewToUser!.first!.title!)\" is at the end of the list."
                                }
                                if (seriesNewToUser!.count > 1) {
                                    message = "There are \(seriesNewToUser!.count) new sermon series at the end of the list."
                                }
                            }
                        } else {
                            if (seriesNewToUser!.count == 1) {
                                message = "The new sermon series \"\(seriesNewToUser!.first!.title!)\" has been added.  Select All under Filter and Newest to Oldest or Oldest to Newest under Sort to see the new sermon series at the beginning or end of the list."
                            }
                            if (seriesNewToUser!.count > 1) {
                                message = "A total of \(seriesNewToUser!.count) new sermon series have been added.  Select All under Filter and Newest to Oldest or Oldest to Newest under Sort to see the new sermon series at the beginning or end of the list."
                            }
                        }
                    } else {
//                        print("\(sermonsNewToUser)")
                        if (sermonsNewToUser.count > 0) {
                            if sermonsNewToUser.keys.count == 1 {
                                if let sermonsAdded = sermonsNewToUser[sermonsNewToUser.keys.first!] {
                                    if sermonsAdded == 1 {
                                        message = "One sermon was added "
                                    }
                                    if sermonsAdded > 1 {
                                        message = "\(sermonsAdded) sermons were added "
                                    }
                                    message = message! + "to the series \(newSeriesIndex[sermonsNewToUser.keys.first!]!.title!)."
                                }
                            } else
                            if sermonsNewToUser.keys.count > 1 {
                                var seriesCount = 0
                                var sermonCount = 0
                                
                                for (_,value) in sermonsNewToUser {
                                    seriesCount += 1
                                    sermonCount += value
                                }
                                message = "\(sermonCount) sermons were added across \(seriesCount) different series."
                            }
                            else {
                                message = "An error occured."
                            }
                        } else {
                            message = "No new sermons were added."
                        }
                    }
                    
                    let alert = UIAlertView(title: "Sermon Update Complete", message: message, delegate: self, cancelButtonTitle: "OK")
                    alert.show()
                    
                    completion?()
                })
            }

            globals.loading = false
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
            if let destinationURL = cachesURL()?.URLByAppendingPathComponent(filename) {
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
                globals.playerPaused = true
                globals.mpPlayer?.pause()
                
                globals.updateCurrentTimeExact()
                
                globals.mpPlayer?.view.hidden = true
                globals.mpPlayer?.view.removeFromSuperview()
                
                self.loadSeries() {
                    self.refreshControl?.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                    
                    globals.refreshing = false
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
                
                self.collectionView.reloadData()
                
                globals.refreshing = false

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
        
        //downloadTask goes out of scope but globals.session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func cancelAllDownloads()
    {
        if (globals.series != nil) {
            for series in globals.series! {
                for sermon in series.sermons! {
                    if sermon.audioDownload.active {
                        sermon.audioDownload.task?.cancel()
                        sermon.audioDownload.task = nil
                        
                        sermon.audioDownload.totalBytesWritten = 0
                        sermon.audioDownload.totalBytesExpectedToWrite = 0
                        
                        sermon.audioDownload.state = .none
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
        if (globals.series != nil) {
            if let barButtons = toolbarItems {
                for barButton in barButtons {
                    barButton.enabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        if (globals.series != nil) {
            navigationItem.leftBarButtonItem?.enabled = true
            navigationItem.rightBarButtonItem?.enabled = true
            enableToolBarButtons()
        }
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        globals.refreshing = true

        cancelAllDownloads()
        
        self.searchBar.placeholder = nil
        
        if splitViewController != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
            })
        }
        
        disableBarButtons()
        
        downloadJSON()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if globals.series == nil {
            loadSeries(nil)
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MediaCollectionViewController.setupPlayingPausedButton), name: Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MediaCollectionViewController.sermonUpdateAvailable), name: Constants.SERMON_UPDATE_AVAILABLE_NOTIFICATION, object: nil)

        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible //iPad only
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(MediaCollectionViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)

        collectionView.addSubview(refreshControl!)
        
        collectionView.alwaysBounceVertical = true

        setupPlayingPausedButton()
        
        collectionView?.allowsSelection = true

        setupSortingAndGroupingOptions()
    }
    
    func setPlayingPausedButton()
    {
        if (globals.sermonPlaying != nil) {
            var title:String?
            
            if (globals.playerPaused) {
                title = Constants.Paused
            } else {
                title = Constants.Playing
            }
            
            var playingPausedButton = navigationItem.rightBarButtonItem
            
            if (playingPausedButton == nil) {
                playingPausedButton = UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MediaCollectionViewController.gotoNowPlaying))
            }
            
            playingPausedButton!.title = title
            
            navigationItem.setRightBarButtonItem(playingPausedButton, animated: true)
        } else {
            navigationItem.setRightBarButtonItem(nil, animated: true)
        }
    }

    func setupPlayingPausedButton()
    {
        if (globals.mpPlayer != nil) && (globals.sermonPlaying != nil) {
            if (!globals.showingAbout) {
                if (splitViewController != nil) {
                    // iPad
                    if (!splitViewController!.collapsed) {
                        // Master and detail view controllers are both present
//                        print("seriesSelected: \(seriesSelected)")
//                        print("globals.sermonPlaying?.series: \(globals.sermonPlaying?.series)")
                        if (seriesSelected == globals.sermonPlaying?.series) {
                            if let sermonSelected = seriesSelected?.sermonSelected {
                                if (sermonSelected != globals.sermonPlaying) {
                                    setPlayingPausedButton()
                                } else {
                                    if (navigationItem.rightBarButtonItem != nil) {
                                        navigationItem.setRightBarButtonItem(nil, animated: true)
                                    }
                                }
                            } else {
                                if (navigationItem.rightBarButtonItem != nil) {
                                    navigationItem.setRightBarButtonItem(nil, animated: true)
                                }
                            }
                        } else {
                            // Different series than the one playing.
                            setPlayingPausedButton()
                        }
                    } else {
                        // Only master view controller is present, not detail view controller
                        setPlayingPausedButton()
                    }
                } else {
                    // iPhone
                    setPlayingPausedButton()
                }
            } else {
                // Showing About
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

        if globals.searchActive && !globals.searchButtonClicked {
            searchBar.becomeFirstResponder()
        }
        
        //Unreliable
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible //iPad only

        setupPlayingPausedButton()
        
        //Solves icon sizing problem in split screen multitasking.
        collectionView.reloadData()
    }
    
    func collectionView(_: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var size:CGFloat = 0.0

        var index = 1
        
        let measure = min(view.bounds.height,view.bounds.width)
        
        repeat {
            size = (measure - CGFloat(10*(index+1)))/CGFloat(index)
            index += 1
        } while (size > measure/1.5)

//        print("Size: \(size)")
//        print("\(UIDevice.currentDevice().model)")
        
        return CGSizeMake(size, size)
    }
    
    func about()
    {
        performSegueWithIdentifier(Constants.Show_About, sender: self)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) { //  && (self.view.window != nil)
                self.collectionView.reloadData()
            }
            
            //Not quite what we want.  What we want is for the list to "look" the same.
            self.scrollToSeries(self.seriesSelected)
            
            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                self.setupTitle()
                
                //Solves icon sizing problem in split screen multitasking.
                self.collectionView.reloadData()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if (UIApplication.sharedApplication().applicationIconBadgeNumber > 0) {
            sermonUpdateAvailable()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (splitViewController == nil) {
            navigationController?.toolbarHidden = true
        }
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
            case Constants.Show_Settings:
                if let svc = destination as? SettingsViewController {
                    svc.modalPresentationStyle = .Popover
                    svc.popoverPresentationController?.delegate = self
                    svc.popoverPresentationController?.barButtonItem = toolbarItems?[5]
                }
                break
                
            case Constants.Show_About:
                //The block below only matters on an iPad
                globals.showingAbout = true
                setupPlayingPausedButton()
                break
                
            case Constants.Show_Series:
//                println("ShowSeries")
                if (globals.gotoNowPlaying) {
                    //This pushes a NEW MediaViewController.
                    
                    seriesSelected = globals.sermonPlaying?.series
                    
                    if let dvc = destination as? MediaViewController {
                        dvc.seriesSelected = globals.sermonPlaying?.series
                        dvc.sermonSelected = globals.sermonPlaying
                    }

                    globals.gotoNowPlaying = !globals.gotoNowPlaying
                } else {
                    if let myCell = sender as? MediaCollectionViewCell {
                        seriesSelected = myCell.series
                    }

                    if (globals.seriesSelected != nil) {
                        if (splitViewController != nil) && (!splitViewController!.collapsed) {
                            setupPlayingPausedButton()
                        }
                    }
                    
                    if let dvc = destination as? MediaViewController {
                        dvc.seriesSelected = globals.seriesSelected
                        dvc.sermonSelected = nil
                    }
                }
                break
                
            default:
                break
            }
        }

    }
    
    func gotoNowPlaying()
    {
//        println("gotoNowPlaying")
        
        globals.gotoNowPlaying = true
        
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
        return globals.activeSeries != nil ? globals.activeSeries!.count : 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> MediaCollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.SERIES_CELL_IDENTIFIER, forIndexPath: indexPath) as! MediaCollectionViewCell
    
        // Configure the cell
        cell.series = globals.activeSeries?[indexPath.row]

        return cell
    }

    // MARK: UICollectionViewDelegate
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        println("didSelect")

        if let cell: MediaCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as? MediaCollectionViewCell {
            seriesSelected = cell.series
            collectionView.reloadData()
        } else {
            
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        println("didDeselect")

//        if let cell: MediaCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as? MediaCollectionViewCell {
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
