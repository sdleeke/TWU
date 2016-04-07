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

func startAudio()
{
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
}

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
}

func lastNameFromName(name:String?) -> String?
{
    if var lastname = name {
        while (lastname.rangeOfString(Constants.SINGLE_SPACE_STRING) != nil) {
            lastname = lastname.substringFromIndex(lastname.rangeOfString(Constants.SINGLE_SPACE_STRING)!.endIndex)
        }
        return lastname
    }
    return nil
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

//func removeTempFiles()
//{
//    // Clean up temp directory for cancelled downloads
//    let fileManager = NSFileManager.defaultManager()
//    let path = NSTemporaryDirectory()
//    do {
//        let array = try fileManager.contentsOfDirectoryAtPath(path)
//        
//        for name in array {
//            if (name.rangeOfString(Constants.TMP_FILE_EXTENSION)?.endIndex == name.endIndex) {
//                print("Deleting: \(name)")
//                try fileManager.removeItemAtPath(path + name)
//            }
//        }
//    } catch _ {
//    }
//}

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
    
    return sortString
}

func seriesFromSeriesDicts(seriesDicts:[[String:String]]?) -> [Series]?
{
    return seriesDicts?.map({ (seriesDict:[String:String]) -> Series in
        return Series(seriesDict: seriesDict)
    })
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

func removeJSONFromFileSystemDirectory()
{
    if let jsonFileSystemURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERIES_JSON) {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(jsonFileSystemURL.path!)
        } catch _ {
            print("failed to copy sermons.json")
        }
    }
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



