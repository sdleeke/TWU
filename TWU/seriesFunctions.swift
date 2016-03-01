//
//  seriesFunctions.swift
//  TWU
//
//  Created by Steve Leeke on 8/31/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

extension NSDate
{
    convenience
    init(dateString:String) {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "MM/dd/yyyy"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let d = dateStringFormatter.dateFromString(dateString)!
        self.init(timeInterval:0, sinceDate:d)
    }
    
    func isNewerThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isNewer = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
        {
            isNewer = true
        }
        
        //Return Result
        return isNewer
    }
    
    
    func isOlderThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isOlder = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
        {
            isOlder = true
        }
        
        //Return Result
        return isOlder
    }
    
    
    // Claims to be a redeclaration, but I can't find the other.
    //    func isEqualToDate(dateToCompare : NSDate) -> Bool
    //    {
    //        //Declare Variables
    //        var isEqualTo = false
    //
    //        //Compare Values
    //        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame
    //        {
    //            isEqualTo = true
    //        }
    //
    //        //Return Result
    //        return isEqualTo
    //    }
    
    
    
    func addDays(daysToAdd : Int) -> NSDate
    {
        let secondsInDays : NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    
    func addHours(hoursToAdd : Int) -> NSDate
    {
        let secondsInHours : NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}

func documentsURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
}

func cachesURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first
}

func sortSeries(series:[Series]?,sorting:String?) -> [Series]?
{
    var results:[Series]?
    
    switch sorting! {
    case Constants.Title_AZ:
        results = series?.sort() { $0.titleSort < $1.titleSort }
        break
    case Constants.Title_ZA:
        results = series?.sort() { $0.titleSort > $1.titleSort }
        break
    case Constants.Newest_to_Oldest:
        results = series?.sort() { $0.id > $1.id }
        break
    case Constants.Oldest_to_Newest:
        results = series?.sort() { $0.id < $1.id }
        break
    default:
        break
    }
    
    return results
}

func bookNumberInBible(book:String?) -> Int?
{
    if (book != nil) {
        if let index = Constants.OLD_TESTAMENT.indexOf(book!) {
            return index
        }
        
        if let index = Constants.NEW_TESTAMENT.indexOf(book!) {
            return Constants.OLD_TESTAMENT.count + index
        }
        
        return Constants.OLD_TESTAMENT.count + Constants.NEW_TESTAMENT.count+1 // Not in the Bible.  E.g. Selected Scriptures
    } else {
        return nil
    }
}

func booksFromSeries(series:[Series]?) -> [String]?
{
//    var bookSet = Set<String>()
//    var bookArray = [String]()
    
    return Array(Set(series!.filter({ (series:Series) -> Bool in
        return series.book != nil
    }).map { (series:Series) -> String in
        return series.book!
    })).sort({ bookNumberInBible($0) < bookNumberInBible($1) })
    
//    if (series != nil) {
//        for singleSeries in series! {
//            if (singleSeries.book != nil) {
//                bookSet.insert(singleSeries.book!)
//            }
//        }
//        
//        for book in bookSet {
//            bookArray.append(book)
//        }
//        
//        bookArray.sortInPlace() { bookNumberInBible($0) < bookNumberInBible($1) }
//    }
//    
//    return bookArray.count > 0 ? bookArray : nil
}

func loadDefaults()
{
    loadSermonSettings()

    let defaults = NSUserDefaults.standardUserDefaults()
    
    if let sorting = defaults.stringForKey(Constants.SORTING) {
        Globals.sorting = sorting
    }
    
    if let filter = defaults.stringForKey(Constants.FILTER) {
        if (filter == Constants.All) {
            Globals.filter = nil
            Globals.showing = .all
        } else {
            Globals.filter = filter
            Globals.showing = .filtered
        }
    }
    
//    if let seriesSelectedStr = defaults.stringForKey(Constants.SERIES_SELECTED) {
//        if let seriesSelected = Int(seriesSelectedStr) {
//            if let index = Globals.series?.indexOf({ (series) -> Bool in
//                return series.id == seriesSelected
//            }) {
//                Globals.seriesSelected = Globals.series?[index]
//                
//                if let sermonSelectedIndexStr = defaults.stringForKey(Constants.SERMON_SELECTED_INDEX) {
//                    if let sermonSelectedIndex = Int(sermonSelectedIndexStr) {
//                        if (sermonSelectedIndex > (Globals.seriesSelected!.show! - 1)) {
//                            defaults.removeObjectForKey(Constants.SERMON_SELECTED_INDEX)
//                        } else {
//                            Globals.sermonSelected = Globals.seriesSelected?.sermons?[sermonSelectedIndex]
//                        }
//                    }
//                }
//            } else {
//                defaults.removeObjectForKey(Constants.SERIES_SELECTED)
//            }
//        }
//    }
    
    if let seriesPlayingIDStr = defaults.stringForKey(Constants.SERIES_PLAYING) {
        if let seriesPlayingID = Int(seriesPlayingIDStr) {
            if let index = Globals.series?.indexOf({ (series) -> Bool in
                return series.id == seriesPlayingID
            }) {
                let seriesPlaying = Globals.series?[index]
                
                if let sermonPlayingIndexStr = defaults.stringForKey(Constants.SERMON_PLAYING_INDEX) {
                    if let sermonPlayingIndex = Int(sermonPlayingIndexStr) {
                        if seriesPlaying?.show != nil {
                            if (sermonPlayingIndex > (seriesPlaying!.show! - 1)) {
                                Globals.sermonPlaying = nil
                            } else {
                                Globals.sermonPlaying = seriesPlaying?.sermons?[sermonPlayingIndex]
                            }
                        } else {
                            Globals.sermonPlaying = seriesPlaying?.sermons?[sermonPlayingIndex]
                        }
                    }
                }
            } else {
                defaults.removeObjectForKey(Constants.SERIES_PLAYING)
            }
        }
    }
}

func networkUnavailable(message:String?)
{
    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
        UIApplication.sharedApplication().keyWindow?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        
        let alert = UIAlertController(title:Constants.Network_Error,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
//        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
}

func removeSliderObserver() {
    if (Globals.sliderObserver != nil) {
        Globals.sliderObserver!.invalidate()
        Globals.sliderObserver = nil
    }
}

func saveSermonSettingsBackground()
{
    print("saveSermonSettingsBackground")
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
        saveSermonSettings()
    }
}

func saveSermonSettings()
{
    print("saveSermonSettings")
    let defaults = NSUserDefaults.standardUserDefaults()
    //    print("\(Globals.sermonSettings)")
    defaults.setObject(Globals.sermonSettings,forKey: Constants.SERMON_SETTINGS_KEY)
    defaults.synchronize()
}

func loadSermonSettings()
{
    let defaults = NSUserDefaults.standardUserDefaults()
    
    if let settingsDictionary = defaults.dictionaryForKey(Constants.SERMON_SETTINGS_KEY) {
        //        print("\(settingsDictionary)")
        Globals.sermonSettings = settingsDictionary as? [String:[String:String]]
    }
    
    if (Globals.sermonSettings == nil) {
        Globals.sermonSettings = [String:[String:String]]()
    }
    
    //    print("\(Globals.sermonSettings)")
}

func updateCurrentTimeWhilePlaying()
{
    //        assert(Globals.player?.currentItem != nil,"Globals.player?.currentItem should not be nil if we're trying to update the currentTime in userDefaults")
    assert(Globals.mpPlayer != nil,"Globals.mpPlayer should not be nil if we're trying to update the currentTime in userDefaults")
    
    if (Globals.mpPlayer != nil) {
        //            let timeNow = Int64(Globals.player!.currentTime().value) / Int64(Globals.player!.currentTime().timescale)
        
        var timeNow = 0
        
        if (Globals.mpPlayer?.playbackState == .Playing) {
            if (Globals.mpPlayer!.currentPlaybackTime > 0) && (Globals.mpPlayer!.currentPlaybackTime <= Globals.mpPlayer!.duration) {
                timeNow = Int(Globals.mpPlayer!.currentPlaybackTime)
            }
            
            if ((timeNow > 0) && (timeNow % 10) == 0) {
//                println("\(timeNow.description)")
                Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.currentPlaybackTime.description
            }
        }
    }
}

func updateCurrentTimeExact()
{
    if (Globals.mpPlayer != nil) {
        updateCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
    }
}

func updateCurrentTimeExact(seekToTime:Float)
{
    if (seekToTime >= 0) {
        Globals.sermonPlaying?.currentTime = seekToTime.description
    }
}

//func playNewSermon(sermon:Sermon?)
//{
//    // This is independent of any UI.
//    
//    Globals.sermonPlaying = sermon
//    Globals.playerPaused = false
//
//    Globals.mpPlayer?.stop()
//    
//    setupSeriesAndSermonPlayingUserDefaults()
//
//    removeSliderObserver()
//        
//    //This guarantees a fresh start.
//    Globals.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
//    
//    Globals.mpPlayer?.shouldAutoplay = false
//    Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
//    Globals.mpPlayer?.prepareToPlay()
//    
//    // This stops the spinner spinning once the audio starts
//    Globals.sermonLoaded = false
//    NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
//    
//    setupPlayingInfoCenter()
//}

func setupPlayer(sermon:Sermon?)
{
    if (sermon != nil) {
        Globals.sermonLoaded = false
        
        Globals.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
        
        Globals.mpPlayer?.shouldAutoplay = false
        Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
        Globals.mpPlayer?.prepareToPlay()
        
        setupPlayingInfoCenter()
        
        Globals.playerPaused = true
    }
}

func removeTempFiles()
{
    // Clean up temp directory for cancelled downloads
    let fileManager = NSFileManager.defaultManager()
    let path = NSTemporaryDirectory()
    do {
        let array = try fileManager.contentsOfDirectoryAtPath(path)
        
        for name in array {
            if (name.rangeOfString(Constants.TMP_FILE_EXTENSION)?.endIndex == name.endIndex) {
                print("Deleting: \(name)")
                try fileManager.removeItemAtPath(path + name)
            }
        }
    } catch _ {
    }
}

func stringWithoutPrefixes(fromString:String?) -> String?
{
    var sortString = fromString
    
    let quote:String = "\""
    let prefixes = ["A ","An ","And ","The "]
    
    if (fromString?.endIndex >= quote.endIndex) && (fromString?.substringToIndex(quote.endIndex) == quote) {
        sortString = fromString!.substringFromIndex(quote.endIndex)
    }
    
    for prefix in prefixes {
        if (fromString?.endIndex >= prefix.endIndex) && (fromString?.substringToIndex(prefix.endIndex) == prefix) {
            sortString = fromString!.substringFromIndex(prefix.endIndex)
            break
        }
    }

//    if (fromString?.substringToIndex(a.endIndex) == a) {
//        sortString = fromString!.substringFromIndex(a.endIndex)
//    } else
//        if (fromString?.substringToIndex(an.endIndex) == an) {
//            sortString = fromString!.substringFromIndex(an.endIndex)
//        } else
//            if (fromString?.substringToIndex(the.endIndex) == the) {
//                sortString = fromString!.substringFromIndex(the.endIndex)
//                //        print("\(titleSort)")
//    }
    
    return sortString
}

func seriesFromSeriesDicts(seriesDicts:[[String:String]]?) -> [Series]?
{
    return seriesDicts?.map({ (seriesDict:[String:String]) -> Series in
        return Series(seriesDict: seriesDict)
    })
//
//    if seriesDicts != nil {
//        //    print("\(Globals.seriesDicts.count)")
//        var seriesArray = [Series]()
//        
//        for seriesDict in seriesDicts! {
//            let series = Series()
//            
//            //        print("\(seriesDict)")
//            series.dict = seriesDict
//            
//            //        print("\(sermon)")
//            
//            var sermons = [Sermon]()
//            for i in 0..<series.numberOfSermons {
//                let sermon = Sermon(series: series,id:series.startingIndex+i)
//                sermons.append(sermon)
//            }
//            series.sermons = sermons
//            
//            seriesArray.append(series)
//        }
//        
//        return seriesArray.count > 0 ? seriesArray : nil
//    } else {
//        return nil
//    }
}

func jsonDataFromBundle() -> JSON
{
    if let path = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: "json") {
        do {
            let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from file, make sure that file contains valid json.")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } else {
        print("Invalid filename/path.")
    }
    
    return nil
}

func jsonToFileSystem()
{
    let fileManager = NSFileManager.defaultManager()
    
    //Get documents directory URL
    let jsonFileSystemURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERIES_JSON)
    
    let jsonBundlePath = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: "json")
    
    // Check if file exist
    if (!fileManager.fileExistsAtPath(jsonFileSystemURL!.path!)){
        if (jsonBundlePath != nil) {
            do {
                // Copy File From Bundle To Documents Directory
                try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonFileSystemURL!.path!)
            } catch _ {
                print("failed to copy sermons.json")
            }
        }
    } else {
        // Which is newer, the bundle file or the file in the Documents folder?
        do {
            let jsonBundleAttributes = try fileManager.attributesOfItemAtPath(jsonBundlePath!)
            
            let jsonFileSystemAttributes = try fileManager.attributesOfItemAtPath(jsonFileSystemURL!.path!)
            
            let jsonBundleModDate = jsonBundleAttributes[NSFileModificationDate] as! NSDate
            let jsonFileSystemModDate = jsonFileSystemAttributes[NSFileModificationDate] as! NSDate
            
            if (jsonBundleModDate.isOlderThanDate(jsonFileSystemModDate)) {
                //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                print("JSON in Documents is newer than JSON in bundle")
            }
            
            if (jsonBundleModDate.isEqualToDate(jsonFileSystemModDate)) {
                let jsonBundleFileSize = jsonBundleAttributes[NSFileSize] as! Int
                let jsonFileSystemFileSize = jsonFileSystemAttributes[NSFileSize] as! Int
                
                if (jsonBundleFileSize != jsonFileSystemFileSize) {
                    print("Same dates different file sizes")
                    //We have a problem.
                } else {
                    print("Same dates same file sizes")
                    //Do nothing, they are the same.
                }
            }
            
            if (jsonBundleModDate.isNewerThanDate(jsonFileSystemModDate)) {
                print("JSON in bundle is newer than JSON in Documents")
                //copy the bundle into Documents directory
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.removeItemAtPath(jsonFileSystemURL!.path!)
                    try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonFileSystemURL!.path!)
                } catch _ {
                    print("failed to copy sermons.json")
                }
            }
        } catch _ {
            
        }
        
    }
}

func jsonDataFromFileSystem() -> JSON
{
    if let url = cachesURL()?.URLByAppendingPathComponent(Constants.SERIES_JSON) {
        do {
            let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe)
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from file, make sure that file contains valid json.")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } else {
        print("Invalid filename/path.")
    }
    
    return nil
}

func loadSeriesDictsFromJSON() -> [[String:String]]?
{
    jsonToFileSystem()
    
    let json = jsonDataFromFileSystem()
    
    if json != nil {
        //                print("json:\(json)")
        
        var seriesDicts = [[String:String]]()
        
        let series = json[Constants.JSON_ARRAY_KEY]
        
        for i in 0..<series.count {
            //                    print("sermon: \(series[i])")
            
            var dict = [String:String]()
        
            for (key,value) in series[i] {
                dict["\(key)"] = "\(value)"
            }
            
            seriesDicts.append(dict)
        }
        
        return seriesDicts.count > 0 ? seriesDicts : nil
    } else {
        print("could not get json from file, make sure that file contains valid json.")
    }
    
    return nil
}

func addAccessoryEvents()
{
    MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        print("RemoteControlPause")
        Globals.mpPlayer?.pause()
        Globals.playerPaused = true
        updateCurrentTimeExact()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().stopCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().stopCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        print("RemoteControlPlay")
        Globals.mpPlayer?.play()
        Globals.playerPaused = false
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        print("RemoteControlTogglePlayPause")
        if (Globals.playerPaused) {
            Globals.mpPlayer?.play()
        } else {
            Globals.mpPlayer?.pause()
            updateCurrentTimeExact()
        }
        Globals.playerPaused = !Globals.playerPaused
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.beginSeekingBackward()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.beginSeekingForward()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.currentPlaybackTime -= NSTimeInterval(15)
        updateCurrentTimeExact()
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }

    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.currentPlaybackTime += NSTimeInterval(15)
        updateCurrentTimeExact()
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = false
    
    MPRemoteCommandCenter.sharedCommandCenter().changePlaybackRateCommand.enabled = false
    
    MPRemoteCommandCenter.sharedCommandCenter().ratingCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().likeCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().dislikeCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().bookmarkCommand.enabled = false
}

func setupPlayingInfoCenter()
{
    if (Globals.sermonPlaying != nil) {
        var sermonInfo = [String:AnyObject]()
        
        sermonInfo.updateValue(Globals.sermonPlaying!.series!.title + " (Part \(Globals.sermonPlaying!.index + 1))",    forKey: MPMediaItemPropertyTitle)
        sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyArtist)
        
        sermonInfo.updateValue(Globals.sermonPlaying!.series!.title,                                                forKey: MPMediaItemPropertyAlbumTitle)
        sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyAlbumArtist)
        sermonInfo.updateValue(MPMediaItemArtwork(image: Globals.sermonPlaying!.series!.getArt()!),                        forKey: MPMediaItemPropertyArtwork)
        
        sermonInfo.updateValue(Globals.sermonPlaying!.index + 1,                                                forKey: MPMediaItemPropertyAlbumTrackNumber)
        sermonInfo.updateValue(Globals.sermonPlaying!.series!.numberOfSermons,                                      forKey: MPMediaItemPropertyAlbumTrackCount)
        
        if (Globals.mpPlayer != nil) {
            sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.duration),                                forKey: MPMediaItemPropertyPlaybackDuration)
            sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.currentPlaybackTime),                     forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
            
            sermonInfo.updateValue(NSNumber(float:Globals.mpPlayer!.currentPlaybackRate),                       forKey: MPNowPlayingInfoPropertyPlaybackRate)
        }
        
        //    println("\(sermonInfo.count)")
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
    }
}


