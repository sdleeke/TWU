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
        return Globals.shared.activeSeries?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.IDENTIFIER.SERIES_CELL, for: indexPath) as? MediaCollectionViewCell {
            // Configure the cell
            cell.series = Globals.shared.activeSeries?[indexPath.row]
            
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

extension MediaCollectionViewController : UICollectionViewDelegateFlowLayout
{
    func collectionView(_: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt: IndexPath) -> CGSize
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
}

extension MediaCollectionViewController : UISearchBarDelegate
{
    // MARK: UISearchBarDelegate
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        return !Globals.shared.isLoading && !Globals.shared.isRefreshing && (Globals.shared.series != nil)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        searchBar.showsCancelButton = true
        
        Globals.shared.searchButtonClicked = false
        
        Globals.shared.searchActive = true

        Globals.shared.updateSearchResults()
        
        collectionView?.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        Globals.shared.searchButtonClicked = true
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        Globals.shared.searchButtonClicked = true
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        Globals.shared.searchButtonClicked = false
        Globals.shared.searchText = searchBar.text
        Globals.shared.updateSearchResults()
        
        collectionView?.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.text = nil
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
        Globals.shared.searchText = nil
        Globals.shared.searchSeries = nil
        Globals.shared.searchActive = false
        
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
            Globals.shared.sorting = strings[index]
            collectionView.reloadData()
            break
            
        case .selectingFiltering:
            if (Globals.shared.filter != strings[index]) {
                searchBar.placeholder = strings[index]
                
                if (strings[index] == Constants.All) {
                    Globals.shared.showing = .all
                    Globals.shared.filter = nil
                } else {
                    Globals.shared.showing = .filtered
                    Globals.shared.filter = strings[index]
                }
                
                self.collectionView.reloadData()
                
                if Globals.shared.activeSeries != nil {
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
            defaults.set(seriesSelected.name, forKey: Constants.SETTINGS.SELECTED.SERIES)
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
            Globals.shared.motionEnded(motion, event: event)
        }
    }

    @objc func sorting(_ button:UIBarButtonItem?)
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
    
    @objc func filtering(_ button:UIBarButtonItem?)
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
        popover.strings = booksFromSeries(Globals.shared.series)
        popover.strings?.insert(Constants.All, at: 0)
        
        present(navigationController, animated: true, completion: nil)
    }
    
    @objc func settings(_ button:UIBarButtonItem?)
    {
        dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: Constants.SEGUE.SHOW_SETTINGS, sender: nil)
    }
    
    fileprivate func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Sort, style: UIBarButtonItemStyle.plain, target: self, action: #selector(sorting(_:)))
        
        let filterButton = UIBarButtonItem(title: Constants.Filter, style: UIBarButtonItemStyle.plain, target: self, action: #selector(filtering(_:)))
        
        let settingsButton = UIBarButtonItem(title: Constants.Settings, style: UIBarButtonItemStyle.plain, target: self, action: #selector(settings(_:)))
        
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
        switch Globals.shared.showing {
        case .all:
            searchBar.placeholder = Constants.All
            break
        case .filtered:
            searchBar.placeholder = Globals.shared.filter
            break
        }
    }
    
    func setupTitle()
    {
        guard Thread.isMainThread else {
            return
        }
        
        if (!Globals.shared.isLoading && !Globals.shared.isRefreshing) {
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
        
        if let index = Globals.shared.activeSeries?.index(of: series) {
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
    
    func seriesFromSeriesDicts(_ seriesDicts:[[String:Any]]?) -> [Series]?
    {
        return seriesDicts?.filter({ (seriesDict:[String:Any]) -> Bool in
            let series = Series(seriesDict: seriesDict)
            return series.sermons?.count > 0 // .show != 0
        }).map({ (seriesDict:[String:Any]) -> Series in
            let series = Series(seriesDict: seriesDict)

            DispatchQueue.global(qos: .background).async { () -> Void in
                series.coverArt { (image:UIImage?) in
                    guard let name = series.coverArtURL?.lastPathComponent else {
                        return
                    }
                    
                    Globals.shared.images[name] = image
                }
            }

            return series
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

    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = DispatchQueue(label: "JSON")
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    func jsonFromURL(urlString:String,filename:String) -> Any?
    {
        guard Globals.shared.reachability.isReachable, let url = URL(string: urlString) else { // let reachability = Globals.shared.reachability, 
            print("json not reachable.")
            return jsonFromFileSystem(filename: filename)
        }
        
        if Globals.shared.format == Constants.JSON.URL, let json = jsonFromFileSystem(filename: filename) {
            operationQueue.addOperation {
                do {
                    let data = try Data(contentsOf: url)
                    print("able to read json from the URL.")
                    
                    do {
                        if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
                            try data.write(to: jsonFileSystemURL)
                        }
                        Globals.shared.format = Constants.JSON.URL
                        print("able to write json to the file system")
                    } catch let error as NSError {
                        print("unable to write json to the file system.")
                        NSLog(error.localizedDescription)
                    }
                } catch let error {
                    NSLog(error.localizedDescription)
                }
            }

            return json
        } else {
            do {
                let data = try Data(contentsOf: url)
                print("able to read json from the URL.")
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    do {
                        if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
                            try data.write(to: jsonFileSystemURL)
                        }
                        Globals.shared.format = Constants.JSON.URL
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
    }
    
    func loadSeriesDicts() -> [[String:Any]]?
    {
        guard let json = jsonFromURL(urlString: Constants.JSON.URL,filename: Constants.JSON.SERIES) as? [String:Any] else {
            print("could not get json from file, make sure that file contains valid json.")
            return nil
        }
        
        if let meta = json[Constants.JSON.KEYS.META] as? [String:Any] {
            Globals.shared.meta = meta
        }
        
        var seriesDicts = [[String:Any]]()
        
        var key : String
        
        switch Constants.JSON.URL {
        case Constants.JSON.URLS.MEDIALIST_PHP:
            key = Constants.JSON.KEYS.SERIES
            break
            
        default:
            key = Constants.JSON.KEYS.DATA
            break
        }
        
        if let series = json[key] as? [[String:Any]] {
            for i in 0..<series.count {
                var dict = [String:Any]()
                
                for (key,value) in series[i] {
                    dict[key] = value // "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }

                print(dict)
                
                seriesDicts.append(dict)
            }
        }
        
        return seriesDicts.count > 0 ? seriesDicts : nil
    }
    
    func loadSeries(_ completion: (() -> Void)?)
    {
        Globals.shared.isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMainThread {
                if !Globals.shared.isRefreshing {
                    self.view.bringSubview(toFront: self.activityIndicator)
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                }
                self.navigationItem.title = Constants.Titles.Loading_Series
            }
            
            if let seriesDicts = self.loadSeriesDicts() {
                Globals.shared.series = self.seriesFromSeriesDicts(seriesDicts)
            }
            
            self.seriesSelected = Globals.shared.seriesSelected

            Thread.onMainThread {
                self.navigationItem.title = Constants.Titles.Loading_Settings
            }
            Globals.shared.loadSettings()
            
            Thread.sleep(forTimeInterval: 1.0)
            
            Thread.onMainThread {
                self.navigationItem.title = Constants.Titles.Setting_up_Player
                if (Globals.shared.mediaPlayer.playing != nil) {
                    Globals.shared.mediaPlayer.playOnLoad = false
                    Globals.shared.mediaPlayer.setup(Globals.shared.mediaPlayer.playing)
                }

                self.navigationItem.title = Constants.TWU.LONG
                self.setupViews()

                if Globals.shared.isRefreshing {
                    self.refreshControl?.endRefreshing()
                    Globals.shared.isRefreshing = false
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }

                completion?()
            }

            Globals.shared.isLoading = false
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
        if (Globals.shared.series != nil) {
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

        if (Globals.shared.series != nil) {
            navigationItem.rightBarButtonItem?.isEnabled = true
            enableToolBarButtons()
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        guard Thread.isMainThread else {
            return
        }
        
        Globals.shared.mediaPlayer.unobserve()
        
        Globals.shared.mediaPlayer.pause()

        Globals.shared.cancelAllDownloads()
        
        Globals.shared.searchActive = false
        searchBar.placeholder = nil
        
        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }
        
        disableBarButtons()

        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
//        globals = Globals()
        
        Globals.shared.series = nil

//        Globals.shared.splitViewController = splitViewController
//        Globals.shared.splitViewController.delegate = splitViewController?.delegate
//        Globals.shared.splitViewController.preferredDisplayMode = .allVisible
        
        collectionView?.reloadData()
        
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = false
            view.bringSubview(toFront: logo)
        }
        
        Globals.shared.isRefreshing = true
        enableBarButtons()
        
        loadSeries()
        {
            guard Globals.shared.series == nil else {
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
    
    @objc func updateUI()
    {
        // TO DO: This needs to be a real updateUI() not just a reload on the collectionView.  E.g. Each button needs to be handled individually.
        collectionView.reloadData()
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showingAboutDidChange), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOWING_ABOUT_CHANGED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SERIES_UPDATE_UI), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupPlayingPausedButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAYING_PAUSED), object: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Globals.shared.series loaded in didBecomeActive.

        addNotifications()
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible //iPad only
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControlEvents.valueChanged)

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
        guard Globals.shared.mediaPlayer.playing != nil else {
            navigationItem.setRightBarButton(nil, animated: true)
            return
        }
        
        var title:String?
        
        if let state = Globals.shared.mediaPlayer.state {
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
            playingPausedButton = UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.plain, target: self, action: #selector(gotoNowPlaying))
        }
        
        playingPausedButton?.title = title
        
        navigationItem.setRightBarButton(playingPausedButton, animated: true)
    }

    @objc func setupPlayingPausedButton()
    {
        guard (Globals.shared.mediaPlayer.player != nil) && (Globals.shared.mediaPlayer.playing != nil) else {
            if (navigationItem.rightBarButtonItem != nil) {
                navigationItem.setRightBarButton(nil, animated: true)
            }
            return
        }

        guard (!Globals.shared.showingAbout) else {
            // Showing About
            setPlayingPausedButton()
            return
        }
        
        guard let isCollapsed = splitViewController?.isCollapsed, !isCollapsed else {
            // iPhone
            setPlayingPausedButton()
            return
        }
        
        guard (seriesSelected == Globals.shared.mediaPlayer.playing?.series) else {
            // iPhone
            setPlayingPausedButton()
            return
        }
        
        if let sermonSelected = seriesSelected?.sermonSelected {
            if (sermonSelected != Globals.shared.mediaPlayer.playing) {
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
    
    @objc func deviceOrientationDidChange()
    {
        if navigationController?.visibleViewController == self {
            navigationController?.isToolbarHidden = false
        }
    }
    
    @objc func showingAboutDidChange()
    {
        aboutButton.isEnabled = !Globals.shared.showingAbout
    }
    
    @objc func willEnterForeground()
    {
        
    }
    
    @objc func didBecomeActive()
    {
        guard !Globals.shared.isLoading, Globals.shared.series == nil else {
            return
        }
        
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = false
            view.bringSubview(toFront: logo)
        }
        
        loadSeries()
        {
            guard Globals.shared.series == nil else {
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

        if Globals.shared.series == nil {
            disableBarButtons()
            enableBarButtons()

            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
                logo.isHidden = false
                view.bringSubview(toFront: logo)
            }
        }

        navigationController?.isToolbarHidden = false

        if Globals.shared.searchActive && !Globals.shared.searchButtonClicked {
            searchBar.becomeFirstResponder()
        }
        
        addNotifications()
        
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible //iPad only

        setupPlayingPausedButton()
        
        //Solves icon sizing problem in split screen multitasking.
        collectionView.reloadData()
    }
    
    func about()
    {
        guard Globals.shared.showingAbout else {
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
                Globals.shared.showingAbout = true
                setupPlayingPausedButton()
                break
                
            case Constants.SEGUE.SHOW_SERIES:
                if (Globals.shared.gotoNowPlaying) {
                    //This pushes a NEW MediaViewController.
                    
                    seriesSelected = Globals.shared.mediaPlayer.playing?.series
                    
                    if let dvc = destination as? MediaViewController {
                        dvc.seriesSelected = Globals.shared.mediaPlayer.playing?.series
                        dvc.sermonSelected = Globals.shared.mediaPlayer.playing
                    }

                    Globals.shared.gotoNowPlaying = !Globals.shared.gotoNowPlaying
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
    
    @objc func gotoNowPlaying()
    {
        Globals.shared.gotoNowPlaying = true
        
        performSegue(withIdentifier: Constants.SEGUE.SHOW_SERIES, sender: self)
    }
}
