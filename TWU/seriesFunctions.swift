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

func documentsURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
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
    var bookSet = Set<String>()
    var bookArray = [String]()
    
    if (series != nil) {
        for singleSeries in series! {
            if (singleSeries.book != nil) {
                bookSet.insert(singleSeries.book!)
            }
        }
        
        for book in bookSet {
            bookArray.append(book)
        }
        
        bookArray.sortInPlace() { bookNumberInBible($0) < bookNumberInBible($1) }
    }
    
    return bookArray.count > 0 ? bookArray : nil
}

func loadDefaults()
{
    let defaults = NSUserDefaults.standardUserDefaults()
    
    if let sorting = defaults.stringForKey(Constants.SORTING) {
        Globals.sorting = sorting
    }
    
    if let filter = defaults.stringForKey(Constants.FILTER) {
        Globals.filter = filter
        if (filter == Constants.All) {
            Globals.filter = nil
            Globals.showing = .all
        } else {
            Globals.showing = .filtered
        }
    }
    
    if let seriesSelectedStr = defaults.stringForKey(Constants.SERIES_SELECTED) {
        if let seriesSelected = Int(seriesSelectedStr) {
            if let index = Globals.series?.indexOf({ (series) -> Bool in
                return series.id == seriesSelected
            }) {
                Globals.seriesSelected = Globals.series?[index]
                
                if let sermonSelectedIndexStr = defaults.stringForKey(Constants.SERMON_SELECTED_INDEX) {
                    if let sermonSelectedIndex = Int(sermonSelectedIndexStr) {
                        Globals.sermonSelected = Globals.seriesSelected?.sermons?[sermonSelectedIndex]
                    }
                }
            }
        }
    }
    
    if let seriesPlayingIDStr = defaults.stringForKey(Constants.SERIES_PLAYING) {
        if let seriesPlayingID = Int(seriesPlayingIDStr) {
            if let index = Globals.series?.indexOf({ (series) -> Bool in
                return series.id == seriesPlayingID
            }) {
                let seriesPlaying = Globals.series?[index]
                
                if let sermonPlayingIndexStr = defaults.stringForKey(Constants.SERMON_PLAYING_INDEX) {
                    if let sermonPlayingIndex = Int(sermonPlayingIndexStr) {
                        Globals.sermonPlaying = seriesPlaying?.sermons?[sermonPlayingIndex]
                    }
                }
            }
        }
    }
}


func setupPlayer(sermon:Sermon?)
{
    if (sermon != nil) {
        var sermonURL:String?
        var url:NSURL?
        
        let filename = String(format: Constants.FILENAME_FORMAT, sermon!.series!.startingIndex + sermon!.index)
        url = documentsURL()?.URLByAppendingPathComponent(filename)
        // Check if file exist
        if (!NSFileManager.defaultManager().fileExistsAtPath(url!.path!)){
            sermonURL = "\(Constants.BASE_AUDIO_URL)\(filename)"
            //        println("playNewSermon: \(sermonURL)")
            url = NSURL(string:sermonURL!)
            if (!Reachability.isConnectedToNetwork() || !UIApplication.sharedApplication().canOpenURL(url!)) {
                url = nil
            }
        }
        
        if (url != nil) {
            Globals.mpPlayer = MPMoviePlayerController(contentURL: url)
            
            Globals.mpPlayer?.shouldAutoplay = false
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
            Globals.mpPlayer?.prepareToPlay()
            
            setupPlayingInfoCenter()
            
            Globals.playerPaused = true
            Globals.sermonLoaded = false
        } else {
            Globals.sermonLoaded = true
        }
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

func stringWithoutLeadingTheOrAOrAn(fromString:String?) -> String?
{
    let a:String = "A "
    let an:String = "An "
    let the:String = "The "
    
    var sortString = fromString
    
    if (fromString?.substringToIndex(a.endIndex) == a) {
        sortString = fromString!.substringFromIndex(a.endIndex)
    } else
        if (fromString?.substringToIndex(an.endIndex) == an) {
            sortString = fromString!.substringFromIndex(an.endIndex)
        } else
            if (fromString?.substringToIndex(the.endIndex) == the) {
                sortString = fromString!.substringFromIndex(the.endIndex)
                //        print("\(titleSort)")
    }
    
    return sortString
}

func seriesFromSeriesDicts(seriesDicts:[[String:String]]?) -> [Series]?
{
    if seriesDicts != nil {
        //    print("\(Globals.seriesDicts.count)")
        var seriesArray = [Series]()
        
        for seriesDict in seriesDicts! {
            let series = Series()
            
            //        print("\(seriesDict)")
            series.dict = seriesDict
            
            //        print("\(sermon)")
            
            var sermons = [Sermon]()
            for i in 0..<series.numberOfSermons {
                let sermon = Sermon(series: series,id:series.startingIndex+i)
                //            if sermon.isDownloaded() {
                //                sermon.download.state = .downloaded
                //            }
                sermons.append(sermon)
            }
            series.sermons = sermons
            
            //        series.bookFromScripture()
            //        series.titleSort = stringWithoutLeadingTheOrAOrAn(series.title)?.lowercaseString
            
            seriesArray.append(series)
        }
        
        return seriesArray.count > 0 ? seriesArray : nil
    } else {
        return nil
    }
}

func jsonDataFromURL() -> JSON
{
    if let url = NSURL(string: Constants.JSON_URL_PREFIX + "cbc.sermons.json") {
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

func loadSeriesDictsFromJSON() -> [[String:String]]?
{
    //    var json = jsonDataFromURL()
    //    if (json == nil) {
    //        json = jsonDataFromBundle()
    //    }
    
    let json = jsonDataFromBundle()
    
    if json != JSON.null {
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
        updateUserDefaultsCurrentTimeExact()
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
            updateUserDefaultsCurrentTimeExact()
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
        updateUserDefaultsCurrentTimeExact()
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }

    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.currentPlaybackTime += NSTimeInterval(15)
        updateUserDefaultsCurrentTimeExact()
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

func remoteControlEvent(event: UIEvent) {
    print("remoteControlReceivedWithEvent")
    
    switch event.subtype {
    case UIEventSubtype.MotionShake:
        print("RemoteControlEvent.MotionShake")
        break
        
    case UIEventSubtype.None:
        print("RemoteControlEvent.None")
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
        updateUserDefaultsCurrentTimeExact()
        break
        
    case UIEventSubtype.RemoteControlTogglePlayPause:
        print("RemoteControlTogglePlayPause")
        if (Globals.playerPaused) {
            Globals.mpPlayer?.play()
        } else {
            Globals.mpPlayer?.pause()
            updateUserDefaultsCurrentTimeExact()
        }
        Globals.playerPaused = !Globals.playerPaused
        break
        
    case UIEventSubtype.RemoteControlPreviousTrack:
        print("RemoteControlPreviousTrack")
        break
        
    case UIEventSubtype.RemoteControlNextTrack:
        print("RemoteControlNextTrack")
        break
        
        //The lock screen time elapsed/remaining don't track well with seeking
        //But at least this has them moving in the right direction.
        
    case UIEventSubtype.RemoteControlBeginSeekingBackward:
        print("RemoteControlBeginSeekingBackward")
        Globals.mpPlayer?.beginSeekingBackward()
//        updatePlayingInfoCenter()
        setupPlayingInfoCenter()
        break
        
    case UIEventSubtype.RemoteControlEndSeekingBackward:
        Globals.mpPlayer?.endSeeking()
        updateUserDefaultsCurrentTimeExact()
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
        Globals.mpPlayer?.endSeeking()
        updateUserDefaultsCurrentTimeExact()
//        updatePlayingInfoCenter()
        setupPlayingInfoCenter()
        break
    }
}

func updateUserDefaultsCurrentTimeExact()
{
    if (Globals.mpPlayer != nil) {
        updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
    }
}

func updateUserDefaultsCurrentTimeExact(seekToTime:Float)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    print("\(Float(seekToTime).description)")
    defaults.setObject(Float(seekToTime).description,forKey: Constants.CURRENT_TIME)
    defaults.synchronize()
}

func updatePlayingInfoCenter()
{
    if (Globals.sermonPlaying != nil) {
        //        let imageName = "\(Globals.coverArtPreamble)\(Globals.seriesPlaying!.name)\(Globals.coverArtPostamble)"
        //    print("\(imageName)")
        
        var sermonInfo = [String:AnyObject]()
        
        sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.duration),            forKey: MPMediaItemPropertyPlaybackDuration)
        sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.currentPlaybackTime), forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
        sermonInfo.updateValue(NSNumber(float: Globals.mpPlayer!.currentPlaybackRate),  forKey: MPNowPlayingInfoPropertyPlaybackRate)
        
        //    print("\(sermonInfo.count)")
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
    }
}

func setupPlayingInfoCenter()
{
    if (Globals.sermonPlaying != nil) {
        let imageName = "\(Constants.COVER_ART_PREAMBLE)\(Globals.sermonPlaying!.series!.name)\(Constants.COVER_ART_POSTAMBLE)"
        //    println("\(imageName)")
        
        var sermonInfo = [String:AnyObject]()
        
        sermonInfo.updateValue(Globals.sermonPlaying!.series!.title + " (Part \(Globals.sermonPlaying!.index + 1))",    forKey: MPMediaItemPropertyTitle)
        sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyArtist)
        
        sermonInfo.updateValue(Globals.sermonPlaying!.series!.title,                                                forKey: MPMediaItemPropertyAlbumTitle)
        sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyAlbumArtist)
        sermonInfo.updateValue(MPMediaItemArtwork(image: UIImage(named:imageName)!),                        forKey: MPMediaItemPropertyArtwork)
        
        sermonInfo.updateValue(Globals.sermonPlaying!.index + 1,                                                forKey: MPMediaItemPropertyAlbumTrackNumber)
        sermonInfo.updateValue(Globals.sermonPlaying!.series!.numberOfSermons,                                      forKey: MPMediaItemPropertyAlbumTrackCount)
        
        if (Globals.mpPlayer != nil) {
            sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.duration),                                forKey: MPMediaItemPropertyPlaybackDuration)
            sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.currentPlaybackTime),                     forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
        }
        
        sermonInfo.updateValue(NSNumber(float:Globals.mpPlayer!.currentPlaybackRate),                       forKey: MPNowPlayingInfoPropertyPlaybackRate)
        
        //    println("\(sermonInfo.count)")
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
    }
}


func removeEndPlayObserver()
{

}


func addEndPlayObserver()
{

}
