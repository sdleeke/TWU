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

extension MediaCollectionViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension MediaCollectionViewController : UICollectionViewDataSource
{
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in:UICollectionView) -> Int
    {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        //#warning Incomplete method implementation -- Return the number of items in the section
        //return series[section].count
        return globals.activeSeries?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.IDENTIFIER.SERIES_CELL, for: indexPath) as? MediaCollectionViewCell {
            // Configure the cell
            cell.series = globals.activeSeries?[indexPath.row]
            
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
}

extension MediaCollectionViewController : UICollectionViewDelegate
{
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if let cell: MediaCollectionViewCell = collectionView.cellForItem(at: indexPath) as? MediaCollectionViewCell {
            seriesSelected = cell.series
            collectionView.reloadData()
        } else {
            
        }
    }
}

extension MediaCollectionViewController : UISearchBarDelegate
{
    // MARK: UISearchBarDelegate
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        return !globals.isLoading && !globals.isRefreshing && (globals.series != nil)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        searchBar.showsCancelButton = true
        
        globals.searchButtonClicked = false
        
        globals.searchActive = true

        globals.updateSearchResults()
        
        collectionView?.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        globals.searchButtonClicked = true
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        globals.searchButtonClicked = true
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        globals.searchButtonClicked = false
        globals.searchText = searchBar.text
        globals.updateSearchResults()
        
        collectionView?.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.text = nil
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
        globals.searchText = nil
        globals.searchSeries = nil
        globals.searchActive = false
        
        collectionView?.reloadData()
    }
}

extension MediaCollectionViewController : UIPopoverPresentationControllerDelegate
{
    // MARK: UIPopoverPresentationControllerDelegate
    
}

extension MediaCollectionViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate

    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose) // , sermon:Sermon?
    {
        guard Thread.isMainThread else {
            return
        }
        
        dismiss(animated: true, completion: nil)
        
        switch purpose {
        case .selectingSorting:
            globals.sorting = strings[index]
            collectionView.reloadData()
            break
            
        case .selectingFiltering:
            if (globals.filter != strings[index]) {
                searchBar.placeholder = strings[index]
                
                if (strings[index] == Constants.All) {
                    globals.showing = .all
                    globals.filter = nil
                } else {
                    globals.showing = .filtered
                    globals.filter = strings[index]
                }
                
                self.collectionView.reloadData()
                
                if globals.activeSeries != nil {
                    let indexPath = IndexPath(item:0,section:0)
                    collectionView.scrollToItem(at: indexPath,at:UICollectionViewScrollPosition.centeredVertically, animated: true)
                }
            }
            break
            
        case .selectingShow:
            break
            
        default:
            break
        }
    }
}

class MediaCollectionViewController: UIViewController
{
    var refreshControl:UIRefreshControl?

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var aboutButton: UIBarButtonItem!
    
    var seriesSelected:Series? {
        willSet {
            
        }
        didSet {
            guard let seriesSelected = seriesSelected else {
                print("MediaCollectionViewController:seriesSelected nil")
                return
            }

            let defaults = UserDefaults.standard
            defaults.set("\(seriesSelected.id)", forKey: Constants.SETTINGS.SELECTED.SERIES)
            defaults.synchronize()
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAYING_PAUSED), object: nil)
            }
        }
    }

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var session:URLSession? // Used for JSON

    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            globals.motionEnded(motion, event: event)
        }
    }

    func sorting(_ button:UIBarButtonItem?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        guard let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController else {
            return
        }
        
        guard let popover = navigationController.viewControllers[0] as? PopoverTableViewController else {
            return
        }
        
        navigationController.modalPresentationStyle = .popover
        
        navigationController.popoverPresentationController?.permittedArrowDirections = .down
        navigationController.popoverPresentationController?.delegate = self
        
        navigationController.popoverPresentationController?.barButtonItem = button
        
        popover.navigationItem.title = Constants.Sorting_Options_Title
        
        popover.delegate = self
        
        popover.purpose = .selectingSorting
        popover.strings = Constants.Sorting.Options
        
        present(navigationController, animated: true, completion: nil)
    }
    
    func filtering(_ button:UIBarButtonItem?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        guard let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController else {
            return
        }
        
        guard let popover = navigationController.viewControllers[0] as? PopoverTableViewController else {
            return
        }
        
        navigationController.modalPresentationStyle = .popover
        
        navigationController.popoverPresentationController?.permittedArrowDirections = .down
        navigationController.popoverPresentationController?.delegate = self
        
        navigationController.popoverPresentationController?.barButtonItem = button
        
        popover.navigationItem.title = Constants.Filtering_Options_Title
        
        popover.delegate = self
        
        popover.purpose = .selectingFiltering
        popover.strings = booksFromSeries(globals.series)
        popover.strings?.insert(Constants.All, at: 0)
        
        present(navigationController, animated: true, completion: nil)
    }
    
    func settings(_ button:UIBarButtonItem?)
    {
        dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: Constants.SEGUE.SHOW_SETTINGS, sender: nil)
    }
    
    fileprivate func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Sort, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaCollectionViewController.sorting(_:)))
        
        let filterButton = UIBarButtonItem(title: Constants.Filter, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaCollectionViewController.filtering(_:)))
        
        let settingsButton = UIBarButtonItem(title: Constants.Settings, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaCollectionViewController.settings(_:)))
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        var barButtons = [UIBarButtonItem]()
        
        barButtons.append(spaceButton)
        
        barButtons.append(sortingButton)
        
        barButtons.append(spaceButton)

        barButtons.append(filterButton)
        
        barButtons.append(spaceButton)
        
        barButtons.append(settingsButton)
        
        barButtons.append(spaceButton)
        
        navigationController?.toolbar.isTranslucent = false
        
        if navigationController?.visibleViewController == self {
            navigationController?.isToolbarHidden = false
        }
        
        setToolbarItems(barButtons, animated: true)
    }
    
    fileprivate func setupSearchBar()
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
        guard Thread.isMainThread else {
            return
        }
        
        if (!globals.isLoading && !globals.isRefreshing) {
            self.navigationItem.title = Constants.TWU.LONG
        }
    }
    
    func scrollToSeries(_ series:Series?)
    {
        guard seriesSelected != nil else {
            return
        }
        
        guard let series = series else {
            return
        }
        
        if let index = globals.activeSeries?.index(of: series) {
            let indexPath = IndexPath(item: index, section: 0)
            
            //Without this background/main dispatching there isn't time to scroll after a reload.
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                Thread.onMainThread {
                    self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
                }
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

        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            }
        }
    }
    
    func seriesFromSeriesDicts(_ seriesDicts:[[String:String]]?) -> [Series]?
    {
        return seriesDicts?.filter({ (seriesDict:[String:String]) -> Bool in
            let series = Series(seriesDict: seriesDict)
            return series.show != 0
        }).map({ (seriesDict:[String:String]) -> Series in
            return Series(seriesDict: seriesDict)
        })
    }
    
    func removeJSONFromFileSystemDirectory()
    {
        if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(Constants.JSON.SERIES) {
            do {
                try FileManager.default.removeItem(atPath: jsonFileSystemURL.path)
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                print("failed to copy sermons.json")
            }
        }
    }
    
    func jsonToFileSystem()
    {
        //Get documents directory URL
        guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(Constants.JSON.SERIES) else {
            return
        }
        
        let fileManager = FileManager.default
        
        // Check if file exist
        if (!fileManager.fileExists(atPath: jsonFileSystemURL.path)){
//            downloadJSON()
        }
    }
    
    func jsonFromFileSystem(filename:String?) -> Any?
    {
        guard let filename = filename else {
            return nil
        }
        
        guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: jsonFileSystemURL)
            print("able to read json from the URL.")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                return nil
            }
        } catch let error as NSError {
            print("Network unavailable: json could not be read from the file system.")
            NSLog(error.localizedDescription)
            return nil
        }
    }

    func jsonFromURL(urlString:String,filename:String) -> Any?
    {
        guard let reachability = globals.reachability, reachability.isReachable, let url = URL(string: urlString) else {
            print("json not reachable.")
            return jsonFromFileSystem(filename: filename)
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("able to read json from the URL.")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                do {
                    if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
                        try data.write(to: jsonFileSystemURL)
                    }
    
                    print("able to write json to the file system")
                } catch let error as NSError {
                    print("unable to write json to the file system.")
                    
                    NSLog(error.localizedDescription)
                }
                
                return json
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                return jsonFromFileSystem(filename: filename)
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            return jsonFromFileSystem(filename: filename)
        }
    }
    
    func loadSeriesDicts() -> [[String:String]]?
    {
        guard let json = jsonFromURL(urlString: Constants.JSON.URL,filename: Constants.JSON.SERIES) as? [String:Any] else {
            print("could not get json from file, make sure that file contains valid json.")
            return nil
        }
        
        var seriesDicts = [[String:String]]()
        
        if let series = json[Constants.JSON.ARRAY_KEY] as? [[String:String]] {
            for i in 0..<series.count {
                var dict = [String:String]()
                
                for (key,value) in series[i] {
                    dict["\(key)"] = "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
                
                seriesDicts.append(dict)
            }
        }
        
        return seriesDicts.count > 0 ? seriesDicts : nil
    }
    
    func loadSeries(_ completion: (() -> Void)?)
    {
        globals.isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMainThread {
                if !globals.isRefreshing {
                    self.view.bringSubview(toFront: self.activityIndicator)
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                }
                self.navigationItem.title = Constants.Titles.Loading_Series
            }
            
            if let seriesDicts = self.loadSeriesDicts() {
                globals.series = self.seriesFromSeriesDicts(seriesDicts)
            }
            
            self.seriesSelected = globals.seriesSelected

            Thread.onMainThread {
                self.navigationItem.title = Constants.Titles.Loading_Settings
            }
            globals.loadSettings()

            Thread.onMainThread {
                self.navigationItem.title = Constants.Titles.Setting_up_Player
                if (globals.mediaPlayer.playing != nil) {
                    globals.mediaPlayer.playOnLoad = false
                    globals.mediaPlayer.setup(globals.mediaPlayer.playing)
                }

                self.navigationItem.title = Constants.TWU.LONG
                self.setupViews()

                if globals.isRefreshing {
                    self.refreshControl?.endRefreshing()
                    globals.isRefreshing = false
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }

                completion?()
            }

            globals.isLoading = false
        })
    }
    
    func disableToolBarButtons()
    {
        if let barButtons = toolbarItems {
            for barButton in barButtons {
                barButton.isEnabled = false
            }
        }
    }
    
    func disableBarButtons()
    {
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        if (globals.series != nil) {
            if let barButtons = toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        navigationItem.leftBarButtonItem?.isEnabled = true

        if (globals.series != nil) {
            navigationItem.rightBarButtonItem?.isEnabled = true
            enableToolBarButtons()
        }
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        guard Thread.isMainThread else {
            return
        }
        
        globals.mediaPlayer.unobserve()
        
        globals.mediaPlayer.pause()

        globals.cancelAllDownloads()
        
        globals.searchActive = false
        searchBar.placeholder = nil
        
        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }
        
        disableBarButtons()

        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
        globals = Globals()
        
        Thread.onMainThread {
            globals.alertTimer = Timer.scheduledTimer(timeInterval: 1.0, target: globals, selector: #selector(Globals.alertViewer), userInfo: nil, repeats: true)
        }
        
        globals.splitViewController = splitViewController
        globals.splitViewController.delegate = splitViewController?.delegate
        globals.splitViewController.preferredDisplayMode = .allVisible
        
        collectionView?.reloadData()
        
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = false
            view.bringSubview(toFront: logo)
        }
        
        globals.isRefreshing = true
        enableBarButtons()
        
        loadSeries()
        {
            guard globals.series == nil else {
                self.logo.isHidden = true
                self.collectionView.reloadData()
                self.scrollToSeries(self.seriesSelected)
                return
            }

            let alert = UIAlertController(title: "No media available.",
                                          message: "Please check your network connection and try again.",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in

            })
            alert.addAction(action)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateUI()
    {
        // TO DO: This needs to be a real updateUI() not just a reload on the collectionView.  E.g. Each button needs to be handled individually.
        collectionView.reloadData()
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(MediaCollectionViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaCollectionViewController.showingAboutDidChange), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOWING_ABOUT_CHANGED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaCollectionViewController.willEnterForeground), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaCollectionViewController.didBecomeActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaCollectionViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SERIES_UPDATE_UI), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaCollectionViewController.setupPlayingPausedButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAYING_PAUSED), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // globals.series loaded in didBecomeActive.

        addNotifications()
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible //iPad only
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(MediaCollectionViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)

        if let refreshControl = refreshControl {
            collectionView.addSubview(refreshControl)
        }
        
        collectionView.alwaysBounceVertical = true

        setupPlayingPausedButton()
        
        collectionView?.allowsSelection = true

        if #available(iOS 10.0, *) {
            collectionView?.isPrefetchingEnabled = false
        } else {
            // Fallback on earlier versions
        }
        
        setupSortingAndGroupingOptions()
    }
    
    func setPlayingPausedButton()
    {
        guard globals.mediaPlayer.playing != nil else {
            navigationItem.setRightBarButton(nil, animated: true)
            return
        }
        
        var title:String?
        
        if let state = globals.mediaPlayer.state {
            switch state {
            case .paused:
                title = Constants.Paused
                break
                
            case .playing:
                title = Constants.Playing
                break
                
            default:
                title = Constants.None
                break
            }
        }
        
        var playingPausedButton = navigationItem.rightBarButtonItem
        
        if (playingPausedButton == nil) {
            playingPausedButton = UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaCollectionViewController.gotoNowPlaying))
        }
        
        playingPausedButton?.title = title
        
        navigationItem.setRightBarButton(playingPausedButton, animated: true)
    }

    func setupPlayingPausedButton()
    {
        guard (globals.mediaPlayer.player != nil) && (globals.mediaPlayer.playing != nil) else {
            if (navigationItem.rightBarButtonItem != nil) {
                navigationItem.setRightBarButton(nil, animated: true)
            }
            return
        }

        guard (!globals.showingAbout) else {
            // Showing About
            setPlayingPausedButton()
            return
        }
        
        guard let isCollapsed = splitViewController?.isCollapsed, !isCollapsed else {
            // iPhone
            setPlayingPausedButton()
            return
        }
        
        guard (seriesSelected == globals.mediaPlayer.playing?.series) else {
            // iPhone
            setPlayingPausedButton()
            return
        }
        
        if let sermonSelected = seriesSelected?.sermonSelected {
            if (sermonSelected != globals.mediaPlayer.playing) {
                setPlayingPausedButton()
            } else {
                if (navigationItem.rightBarButtonItem != nil) {
                    navigationItem.setRightBarButton(nil, animated: true)
                }
            }
        } else {
            if (navigationItem.rightBarButtonItem != nil) {
                navigationItem.setRightBarButton(nil, animated: true)
            }
        }
    }
    
    func deviceOrientationDidChange()
    {
        if navigationController?.visibleViewController == self {
            navigationController?.isToolbarHidden = false
        }
    }
    
    func showingAboutDidChange()
    {
        aboutButton.isEnabled = !globals.showingAbout
    }
    
    func willEnterForeground()
    {
        
    }
    
    func didBecomeActive()
    {
        guard !globals.isLoading, globals.series == nil else {
            return
        }
        
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = false
            view.bringSubview(toFront: logo)
        }
        
        loadSeries()
        {
            guard globals.series == nil else {
                self.logo.isHidden = true
                self.collectionView.reloadData()
                self.scrollToSeries(self.seriesSelected)
                return
            }
            
            let alert = UIAlertController(title: "No media available.",
                                          message: "Please check your network connection and try again.",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        logo.isHidden = true

        if globals.series == nil {
            disableBarButtons()
            enableBarButtons()

            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
                logo.isHidden = false
                view.bringSubview(toFront: logo)
            }
        }

        navigationController?.isToolbarHidden = false

        if globals.searchActive && !globals.searchButtonClicked {
            searchBar.becomeFirstResponder()
        }
        
        addNotifications()
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible //iPad only

        setupPlayingPausedButton()
        
        //Solves icon sizing problem in split screen multitasking.
        collectionView.reloadData()
    }
    
    func collectionView(_: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    {
        var minSize:CGFloat = 0.0
        var maxSize:CGFloat = 0.0
        
        // We want at least two full icons showing in either direction.
        
        var minIndex = 2
        var maxIndex = 2
        
        let minMeasure = min(view.bounds.height,view.bounds.width)
        let maxMeasure = max(view.bounds.height,view.bounds.width)
        
        repeat {
            minSize = (minMeasure - CGFloat(10*(minIndex+1)))/CGFloat(minIndex)
            minIndex += 1
        } while minSize > minMeasure
        
        repeat {
            maxSize = (maxMeasure - CGFloat(10*(maxIndex+1)))/CGFloat(maxIndex)
            maxIndex += 1
        } while maxSize > maxMeasure/(maxMeasure / minSize)
        
        var size:CGFloat = 0

        // These get the gap right between the icons.
        
        if minMeasure == view.bounds.height {
            size = min(minSize,maxSize)
        }
        
        if minMeasure == view.bounds.width {
            size = max(minSize,maxSize)
        }

        return CGSize(width: size,height: size)
    }
    
    func about()
    {
        guard globals.showingAbout else {
            return
        }
        
        performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT, sender: self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.collectionView.reloadData()
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setupTitle()

            //Solves icon sizing problem in split screen multitasking.
            self.collectionView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            navigationController?.isToolbarHidden = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            destination = visibleViewController
        }
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.SEGUE.SHOW_SETTINGS:
                if let svc = destination as? SettingsViewController {
                    svc.modalPresentationStyle = .popover
                    svc.popoverPresentationController?.delegate = self
                    svc.popoverPresentationController?.barButtonItem = toolbarItems?[5]
                }
                break
                
            case Constants.SEGUE.SHOW_ABOUT:
                //The block below only matters on an iPad
                globals.showingAbout = true
                setupPlayingPausedButton()
                break
                
            case Constants.SEGUE.SHOW_SERIES:
                if (globals.gotoNowPlaying) {
                    //This pushes a NEW MediaViewController.
                    
                    seriesSelected = globals.mediaPlayer.playing?.series
                    
                    if let dvc = destination as? MediaViewController {
                        dvc.seriesSelected = globals.mediaPlayer.playing?.series
                        dvc.sermonSelected = globals.mediaPlayer.playing
                    }

                    globals.gotoNowPlaying = !globals.gotoNowPlaying
                } else {
                    if let myCell = sender as? MediaCollectionViewCell {
                        seriesSelected = myCell.series
                    }

                    if (seriesSelected != nil) {
                        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
                            setupPlayingPausedButton()
                        }
                    }
                    
                    if let dvc = destination as? MediaViewController {
                        dvc.seriesSelected = seriesSelected
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
        globals.gotoNowPlaying = true
        
        performSegue(withIdentifier: Constants.SEGUE.SHOW_SERIES, sender: self)
    }
}
