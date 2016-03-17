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

class MyCollectionViewController: UIViewController, UISplitViewControllerDelegate, UICollectionViewDelegate, UISearchBarDelegate, NSURLSessionDownloadDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

//    var endObserver: AnyObject?

    var refreshControl:UIRefreshControl?

    var seriesSelected:Series? {
        didSet {
//            Globals.seriesSelected = seriesSelected
            if (seriesSelected != nil) {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject("\(seriesSelected!.id)", forKey: Constants.SERIES_SELECTED)
                defaults.synchronize()
     
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
            } else {
                print("MyCollectionViewController:seriesSelected nil")
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
            if (Globals.sermonPlaying != nil) {
                if (Globals.playerPaused) {
                    Globals.mpPlayer?.play()
                } else {
                    Globals.mpPlayer?.pause()
                    updateCurrentTimeExact()
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
//                if (Globals.sorting != option) {
//                    Globals.sorting = option
//                    
//                    Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)
//                    self.collectionView.reloadData()
//                    
//                    //Moving the list can be very disruptive
//                    //                selectOrScrollToSermon(selectedSermon, select: true, scroll: false, position: UITableViewScrollPosition.None)
//                }
//            })
//            if (Globals.sorting == option) {
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
            Globals.sorting = strings[index]
            collectionView.reloadData()
            break
            
        case .selectingFiltering:
            if (Globals.filter != strings[index]) {
                self.searchBar.placeholder = strings[index]
                
                if (strings[index] == Constants.All) {
                    Globals.showing = .all
                    Globals.filter = nil
                } else {
                    Globals.showing = .filtered
                    Globals.filter = strings[index]
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
                popover.strings = booksFromSeries(Globals.series)
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
//        if var books = booksFromSeries(Globals.series) {
//            books.append(Constants.All)
//            for book in books {
//                alertTitle = book
//                action = UIAlertAction(title: alertTitle, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    if (Globals.filter != book) {
//                        self.searchBar.placeholder = book
//                        
//                        if (book == Constants.All) {
//                            Globals.showing = .all
//                            Globals.filter = nil
//                        } else {
//                            Globals.showing = .filtered
//                            Globals.filter = book
//                        }
//                        
//                        Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)
//                        self.collectionView.reloadData()
//                        
//                        let indexPath = NSIndexPath(forItem:0,inSection:0)
//                        self.collectionView.scrollToItemAtIndexPath(indexPath,atScrollPosition:UICollectionViewScrollPosition.CenteredVertically, animated: true)
//                    }
//                })
//                
//                if (Globals.showing == .filtered) && (Globals.filter == book) {
//                    action.enabled = false
//                }
//                if (Globals.showing == .all) && (Globals.filter == nil) && (book == Constants.All) {
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
        let sortingButton = UIBarButtonItem(title: Constants.Sort, style: UIBarButtonItemStyle.Plain, target: self, action: "sorting:")
        let filterButton = UIBarButtonItem(title: Constants.Filter, style: UIBarButtonItemStyle.Plain, target: self, action: "filtering:")
        let settingsButton = UIBarButtonItem(title: Constants.Settings, style: UIBarButtonItemStyle.Plain, target: self, action: "settings:")
        
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
    
    func showUpdate(message message:String?,title:String?)
    {
        //        let application = UIApplication.sharedApplication()
        //        application.applicationIconBadgeNumber++
        //        let alert = UIAlertView(title: message, message: title, delegate: self, cancelButtonTitle: "OK")
        //        alert.show()
        
        let alert = UIAlertController(title:message,
            message: title,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let updateAction = UIAlertAction(title: "Update Now", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.handleRefresh(self.refreshControl!)
        })
        alert.addAction(updateAction)
        
//        if (!Reachability.isConnectedToNetwork()) {
//            updateAction.enabled = false
//        }
        
        let laterAction = UIAlertAction(title: "Update Later", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            UIApplication.sharedApplication().applicationIconBadgeNumber++
        })
        alert.addAction(laterAction)
        
        let cancelAction = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            UIApplication.sharedApplication().applicationIconBadgeNumber++
        })
        alert.addAction(cancelAction)
        
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        alert.popoverPresentationController?.sourceView = self.searchBar
        alert.popoverPresentationController?.sourceRect = self.searchBar.frame
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func sermonUpdateAvailable()
    {
        //        let application = UIApplication.sharedApplication()
        //        application.applicationIconBadgeNumber++
        //        let alert = UIAlertView(title: message, message: title, delegate: self, cancelButtonTitle: "OK")
        //        alert.show()
        
        var title:String?
        
        switch UIApplication.sharedApplication().applicationIconBadgeNumber {
        case 0:
            // Error
            return
            
        case 1:
            title = "Sermon Update Available"
            break
            
        default:
            title = "Sermon Updates Available"
            break
        }
        
        let alert = UIAlertController(title:title,
            message: nil,
            preferredStyle: UIAlertControllerStyle.ActionSheet)

        let updateAction = UIAlertAction(title: "Update Now", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.handleRefresh(self.refreshControl!)
        })
        alert.addAction(updateAction)
        
//        if (!Reachability.isConnectedToNetwork()) {
//            updateAction.enabled = false
//        }
        
        let laterAction = UIAlertAction(title: "Update Later", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            
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
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool
    {
        return !Globals.loading && !Globals.refreshing && (Globals.series != nil)
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        println("Text changed: \(searchText)")
        
        Globals.searchButtonClicked = false
        
        Globals.searchText = searchBar.text
        
        collectionView!.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        Globals.searchButtonClicked = false

        if (!Globals.searchActive) {
            Globals.searchActive = true
            searchBar.showsCancelButton = true
            
            Globals.searchText = searchBar.text
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        println("Search clicked!")
        Globals.searchButtonClicked = true
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        println("Cancel clicked!")
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil

        Globals.searchText = nil
        Globals.searchSeries = nil
        Globals.searchActive = false
        
        collectionView!.reloadData()
    }
    
    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
        //        print("searchBarResultsListButtonClicked")
        
        if !Globals.loading && !Globals.refreshing && (Globals.series != nil) && (self.storyboard != nil) {
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
//            popover?.strings = Globals.sermons.all?.sermonTags
//            
//            popover?.strings?.append(Constants.All)
//            
//            if (popover != nil) {
//                presentViewController(popover!, animated: true, completion: nil)
//            }
        }
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
            updateCurrentTimeExact()
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
        
        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
        
        let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
        let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
        
//        print("\(loadstate)")
//        print("\(playable)")
//        print("\(playthrough)")

        if (playable || playthrough) {
            print("MyCVC.mpPlayerLoadStateDidChange.MPMovieLoadState.Playable")
            //should be called only once, only for  first time audio load.
            if(!Globals.sermonLoaded) {
//                print("\(currentTime!)")
//                print("\(NSTimeInterval(currentTime!))")
   
                if (Globals.sermonPlaying != nil) && Globals.sermonPlaying!.hasCurrentTime() {
                    Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)
                } else {
                    Globals.sermonPlaying?.currentTime = Constants.ZERO
                    Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                }
                
                Globals.sermonLoaded = true
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        } else {
            print("MyCVC.mpPlayerLoadStateDidChange.MPMovieLoadState.Playthrough NOT OK")
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
    
    func scrollToSeries(series:Series?)
    {
        if (seriesSelected != nil) && (Globals.activeSeries?.indexOf(series!) != nil) {
            let indexPath = NSIndexPath(forItem: Globals.activeSeries!.indexOf(series!)!, inSection: 0)
            
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
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
        }
        
//        var mycvc:MyCollectionViewController?
//        var myvc:MyViewController?
//        
//        if let svc = self.splitViewController {
//            //iPad
//            if let nvc = svc.viewControllers[0] as? UINavigationController {
//                mycvc = nvc.visibleViewController as? MyCollectionViewController
//            }
//            if let nvc = svc.viewControllers[svc.viewControllers.count - 1] as? UINavigationController {
//                myvc = nvc.visibleViewController as? MyViewController
//            }
//        } else {
//            mycvc = self.navigationController?.visibleViewController as? MyCollectionViewController
//            myvc = self.navigationController?.visibleViewController as? MyViewController
//        }
//        
//        mycvc?.seriesSelected = seriesSelected
//
//        if (mycvc != nil) {
//            mycvc?.setupSearchBar()
//            mycvc?.collectionView.reloadData()
//            mycvc?.enableBarButtons()
//            mycvc?.setupTitle()
//            mycvc?.setupPlayingPausedButton()
//            
//            if (mycvc!.seriesSelected != nil) && (Globals.activeSeries?.indexOf(mycvc!.seriesSelected!) != nil) {
////                print("\(Globals.activeSeries!.indexOf(mycvc!.seriesSelected!))")
//                let indexPath = NSIndexPath(forItem: Globals.activeSeries!.indexOf(mycvc!.seriesSelected!)!, inSection: 0)
//                mycvc?.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
//            }
//        }
//
//        if (myvc != nil) {
//            myvc?.seriesSelected = Globals.seriesSelected
//            myvc?.sermonSelected = Globals.sermonSelected
//
//            myvc?.updateUI()
//            
//            myvc?.scrollToSermon(myvc?.sermonSelected,select:true,position:UITableViewScrollPosition.Top)
//        }
//
    }
    
    func loadSeries(completion: (() -> Void)?)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            Globals.loading = true

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

//            var oldSermonCount = 0
//            var newSermonCount = 0
            
//            print("\(Globals.series?.count)")

            if Globals.series != nil {
                let old = Set(Globals.series!.map({ (series:Series) -> Int in
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
                    for oldSeries in Globals.series! {
                        if (newSeriesIndex[oldSeries.id]!.show! - oldSeries.show!) != 0 {
                            sermonsNewToUser[oldSeries.id] = newSeriesIndex[oldSeries.id]!.show! - oldSeries.show!
                        }
                    }
                }
            }
            
            Globals.series = newSeries
            
            self.seriesSelected = Globals.seriesSelected

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.Loading_Defaults
            })
            loadDefaults()

            //Handled in didSet's when defaults are loaded.
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.navigationItem.title = Constants.Sorting
//            })
//            Globals.activeSeries = sortSeries(Globals.activeSeries,sorting: Globals.sorting)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.Setting_up_Player
                self.setupSermonPlaying()
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.TWU_LONG
                self.setupViews()
            })
            
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var message:String?
                    
                    if (seriesNewToUser != nil) && (seriesNewToUser!.count > 0) {
                        if (Globals.filter == nil) {
                            if (Globals.sorting != Constants.Newest_to_Oldest) && (Globals.sorting != Constants.Oldest_to_Newest) {
                                if (seriesNewToUser!.count == 1) {
                                    message = "Change sorting to Newest to Oldest or Oldest to Newest to see the new sermon series \"\(seriesNewToUser!.first!.title)\" at the beginning or end of the list."
                                }
                                if (seriesNewToUser!.count > 1) {
                                    message = "Change sorting to Newest to Oldest or Oldest to Newest to see the \(seriesNewToUser!.count) new sermon series at the beginning or end of the list."
                                }
                            }
                            if (Globals.sorting == Constants.Newest_to_Oldest) {
                                if (seriesNewToUser!.count == 1) {
                                    message = "The new sermon series \"\(seriesNewToUser!.first!.title)\" is at the beginning of the list."
                                }
                                if (seriesNewToUser!.count > 1) {
                                    message = "There are \(seriesNewToUser!.count) new sermon series at the beginning of the list."
                                }
                            }
                            if (Globals.sorting == Constants.Oldest_to_Newest) {
                                if (seriesNewToUser!.count == 1) {
                                    message = "The new sermon series \"\(seriesNewToUser!.first!.title)\" is at the end of the list."
                                }
                                if (seriesNewToUser!.count > 1) {
                                    message = "There are \(seriesNewToUser!.count) new sermon series at the end of the list."
                                }
                            }
                        } else {
                            if (seriesNewToUser!.count == 1) {
                                message = "The new sermon series \"\(seriesNewToUser!.first!.title)\" has been added.  Select All under Filter and Newest to Oldest or Oldest to Newest under Sort to see the new sermon series at the beginning or end of the list."
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
                                    message = message! + "to the series \(newSeriesIndex[sermonsNewToUser.keys.first!]!.title)."
                                }
                            } else
                            if sermonsNewToUser.keys.count > 1 {
                                var seriesCount = 0
                                var sermonCount = 0
                                
                                for (_,value) in sermonsNewToUser {
                                    seriesCount++
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

            Globals.loading = false
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
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                
                updateCurrentTimeExact()
                
                Globals.mpPlayer?.view.hidden = true
                Globals.mpPlayer?.view.removeFromSuperview()
                
                self.loadSeries() {
                    self.refreshControl?.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                    
                    Globals.refreshing = false
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
                
                Globals.refreshing = false
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
        Globals.refreshing = true

        cancelAllDownloads()
        
        self.searchBar.placeholder = nil
//        Globals.filter = nil
//        Globals.activeSeries = nil
//        collectionView.reloadData()
        
        if splitViewController != nil {
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
        }
        
//        if let svc = self.splitViewController {
//            //iPad
//
//            // Instead of testing for collapsed:
//            //                if let nvc = svc.viewControllers[svc.viewControllers.count - 1] as? UINavigationController {
//            
//            if (svc.collapsed) {
//                if let nvc = svc.viewControllers[0] as? UINavigationController {
//                    if let myvc = nvc.topViewController as? MyViewController {
//                        myvc.seriesSelected = nil
//                        myvc.sermonSelected = nil
//                        myvc.updateUI()
//                    }
//                }
//            } else {
//                if let nvc = svc.viewControllers[1] as? UINavigationController {
//                    if let myvc = nvc.topViewController as? MyViewController {
//                        myvc.seriesSelected = nil
//                        myvc.sermonSelected = nil
//                        myvc.updateUI()
//                    }
//                }
//            }
//        }
        
        disableBarButtons()
        
        downloadJSON()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Globals.series == nil {
            loadSeries(nil)
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setupPlayingPausedButton", name: Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)

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
        if (Globals.sermonPlaying != nil) {
            var title:String?
            
            if (Globals.playerPaused) {
                title = Constants.Paused
            } else {
                title = Constants.Playing
            }
            
            var playingPausedButton = navigationItem.rightBarButtonItem
            
            if (playingPausedButton == nil) {
                playingPausedButton = UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.Plain, target: self, action: "gotoNowPlaying")
            }
            
            playingPausedButton!.title = title
            
            navigationItem.setRightBarButtonItem(playingPausedButton, animated: true)
        } else {
            navigationItem.setRightBarButtonItem(nil, animated: true)
        }
    }

    func setupPlayingPausedButton()
    {
        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) {
            if (!Globals.showingAbout) {
                if (splitViewController != nil) {
                    // iPad
                    if (!splitViewController!.collapsed) {
                        // Master and detail view controllers are both present
//                        print("seriesSelected: \(seriesSelected)")
//                        print("Globals.sermonPlaying?.series: \(Globals.sermonPlaying?.series)")
                        if (seriesSelected == Globals.sermonPlaying?.series) {
                            if let sermonSelected = seriesSelected?.sermonSelected {
                                if (sermonSelected != Globals.sermonPlaying) {
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

        if Globals.searchActive && !Globals.searchButtonClicked {
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
            index++
        } while (size > measure/1.5)

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
    
    func seekingTimer()
    {
        setupPlayingInfoCenter()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        print("remoteControlReceivedWithEvent")
        
        switch event!.subtype {
        case UIEventSubtype.MotionShake:
            print("RemoteControlShake")
            break
            
        case UIEventSubtype.None:
            print("RemoteControlNone")
            break
            
        case UIEventSubtype.RemoteControlStop:
            print("RemoteControlStop")
            Globals.mpPlayer?.stop()
            Globals.playerPaused = true
            break
            
        case UIEventSubtype.RemoteControlPlay:
            print("RemoteControlPlay")
            Globals.mpPlayer?.play()
            Globals.playerPaused = false
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlPause:
            print("RemoteControlPause")
            Globals.mpPlayer?.pause()
            Globals.playerPaused = true
            updateCurrentTimeExact()
            break
            
        case UIEventSubtype.RemoteControlTogglePlayPause:
            print("RemoteControlTogglePlayPause")
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
            break
            
        case UIEventSubtype.RemoteControlPreviousTrack:
            print("RemoteControlPreviousTrack")
            if (Globals.mpPlayer?.currentPlaybackTime == 0) {
                // Would like it to skip to the prior sermon in the series if there is one.
            } else {
                Globals.mpPlayer?.currentPlaybackTime = 0
            }
            break
            
        case UIEventSubtype.RemoteControlNextTrack:
            print("RemoteControlNextTrack")
            Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
            break
            
            //The lock screen time elapsed/remaining don't track well with seeking
            //But at least this has them moving in the right direction.
            
        case UIEventSubtype.RemoteControlBeginSeekingBackward:
            print("RemoteControlBeginSeekingBackward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingBackward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingBackward:
            print("RemoteControlEndSeekingBackward")
            Globals.mpPlayer?.endSeeking()
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlBeginSeekingForward:
            print("RemoteControlBeginSeekingForward")
            Globals.mpPlayer?.beginSeekingForward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingForward:
            print("RemoteControlEndSeekingForward")
            Globals.mpPlayer?.endSeeking()
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
        }

        if (splitViewController != nil) {
            if (!splitViewController!.collapsed) {
                if let nvc = splitViewController?.viewControllers[1] as? UINavigationController {
                    if let myvc = nvc.topViewController as? MyViewController {
                        myvc.setupPlayPauseButton()
                    }
                }
            }
        }
        setupPlayingPausedButton()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
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
        
//        if Globals.series == nil {
//            disableBarButtons()
//            loadSeries(nil)
//        }

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
            case Constants.Show_Settings:
                if let svc = destination as? MySettingsViewController {
                    svc.modalPresentationStyle = .Popover
                    svc.popoverPresentationController?.delegate = self
                    svc.popoverPresentationController?.barButtonItem = toolbarItems?[5]
                }
                break
                
            case Constants.Show_About:
                //The block below only matters on an iPad
                Globals.showingAbout = true
                setupPlayingPausedButton()
                break
                
            case Constants.Show_Series:
//                println("ShowSeries")
                if (Globals.gotoNowPlaying) {
                    //This pushes a NEW MyViewController.
                    
                    seriesSelected = Globals.sermonPlaying?.series
                    
                    if let dvc = destination as? MyViewController {
                        dvc.seriesSelected = Globals.sermonPlaying?.series
                        dvc.sermonSelected = Globals.sermonPlaying
                    }

                    Globals.gotoNowPlaying = !Globals.gotoNowPlaying
//                    let indexPath = NSIndexPath(forItem: Globals.activeSeries!.indexOf(seriesSelected!)!, inSection: 0)
//                    collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
                } else {
                    if let myCell = sender as? MyCollectionViewCell {
                        seriesSelected = myCell.series
                    }

                    if (Globals.seriesSelected != nil) {
                        if (splitViewController != nil) && (!splitViewController!.collapsed) {
                            setupPlayingPausedButton()
                        }
                    }
                    
                    if let dvc = destination as? MyViewController {
                        dvc.seriesSelected = Globals.seriesSelected
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

        if let cell: MyCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as? MyCollectionViewCell {
            seriesSelected = cell.series
            collectionView.reloadData()
        } else {
            
        }
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
