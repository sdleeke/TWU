//
//  MyCollectionViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation

class MyCollectionViewController: UIViewController, UISplitViewControllerDelegate, UICollectionViewDelegate, UISearchBarDelegate {

//    var endObserver: AnyObject?

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
//    var resultSearchController:UISearchController?

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateUserDefaultsCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
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
//                if (Globals.showing == .filtered) && (Globals.filter == book) {
//                    alertTitle = Constants.CHECKMARK + Constants.SINGLE_SPACE_STRING + alertTitle
//                }
//                if (Globals.showing == .all) && (Globals.filter == nil) && (book == Constants.All) {
//                    alertTitle = Constants.CHECKMARK + Constants.SINGLE_SPACE_STRING + alertTitle
//                }
                action = UIAlertAction(title: alertTitle, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    if (Globals.filter != book) {
                        let defaults = NSUserDefaults.standardUserDefaults()
                        defaults.setObject(book,forKey: Constants.FILTER)
                        defaults.synchronize()
                        
                        //                sortAndGroupSermons()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible //iPad only
        
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
