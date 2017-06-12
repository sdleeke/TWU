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

func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}

func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(lhs > rhs)
    }
}

func startAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    } catch let error as NSError {
        NSLog(error.localizedDescription)
    }
    
//    do {
//        //        audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error:nil)
//        try audioSession.setActive(true)
//    } catch let error as NSError {
//        NSLog(error.localizedDescription)
//    }
}

func shareHTML(viewController:UIViewController,htmlString:String?)
{
    guard htmlString != nil else {
        return
    }
    
    //    let formatter = UIMarkupTextPrintFormatter(markupText: htmlString!)
    //    formatter.perPageContentInsets = UIEdgeInsets(top: 54, left: 54, bottom: 54, right: 54) // 72=1" margins
    
    let activityItems = [htmlString as Any]
    
    let activityViewController = UIActivityViewController(activityItems:activityItems, applicationActivities: nil)
    
    // exclude some activity types from the list (optional)
    
    activityViewController.excludedActivityTypes = [ .addToReadingList ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
    
    activityViewController.popoverPresentationController?.barButtonItem = viewController.navigationItem.rightBarButtonItem
    
    // present the view controller
    DispatchQueue.main.async(execute: { () -> Void in
        viewController.present(activityViewController, animated: false, completion: nil)
    })
}

extension Date
{
    
    init(dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "MM/dd/yyyy"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let d = dateStringFormatter.date(from: dateString)!
        self = Date(timeInterval:0, since:d)
    }
    
    func isNewerThanDate(_ dateToCompare : Date) -> Bool
    {
        //Declare Variables
        var isNewer = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedDescending
        {
            isNewer = true
        }
        
        //Return Result
        return isNewer
    }
    
    
    func isOlderThanDate(_ dateToCompare : Date) -> Bool
    {
        //Declare Variables
        var isOlder = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedAscending
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
    
    
    
    func addDays(_ daysToAdd : Int) -> Date
    {
        let secondsInDays : TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    
    func addHours(_ hoursToAdd : Int) -> Date
    {
        let secondsInHours : TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}

func documentsURL() -> URL?
{
    let fileManager = FileManager.default
    return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
}

func cachesURL() -> URL?
{
    let fileManager = FileManager.default
    return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
}

func sortSeries(_ series:[Series]?,sorting:String?) -> [Series]?
{
    var results:[Series]?
    
    switch sorting! {
    case Constants.Sorting.Title_AZ:
        results = series?.sorted() { $0.titleSort < $1.titleSort }
        break
    case Constants.Sorting.Title_ZA:
        results = series?.sorted() { $0.titleSort > $1.titleSort }
        break
    case Constants.Sorting.Newest_to_Oldest:
        results = series?.sorted() { $0.id > $1.id }
        break
    case Constants.Sorting.Oldest_to_Newest:
        results = series?.sorted() { $0.id < $1.id }
        break
    default:
        break
    }
    
    return results
}

func bookNumberInBible(_ book:String?) -> Int?
{
    if (book != nil) {
        if let index = Constants.TESTAMENT.OLD.index(of: book!) {
            return index
        }
        
        if let index = Constants.TESTAMENT.NEW.index(of: book!) {
            return Constants.TESTAMENT.OLD.count + index
        }
        
        return Constants.TESTAMENT.OLD.count + Constants.TESTAMENT.NEW.count+1 // Not in the Bible.  E.g. Selected Scriptures
    } else {
        return nil
    }
}

func booksFromSeries(_ series:[Series]?) -> [String]?
{
//    var bookSet = Set<String>()
//    var bookArray = [String]()
    
    return Array(Set(series!.filter({ (series:Series) -> Bool in
        return series.book != nil
    }).map { (series:Series) -> String in
        return series.book!
    })).sorted(by: { bookNumberInBible($0) < bookNumberInBible($1) })
}

func lastNameFromName(_ name:String?) -> String?
{
    if var lastname = name {
        while (lastname.range(of: Constants.SINGLE_SPACE) != nil) {
            lastname = lastname.substring(from: lastname.range(of: Constants.SINGLE_SPACE)!.upperBound)
        }
        return lastname
    }
    return nil
}

var alert:UIAlertController!

func networkUnavailable(_ message:String?)
{
    if (alert == nil) { // && (UIApplication.shared.applicationState == UIApplicationState.active)
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
        
        alert = UIAlertController(title:Constants.Network_Error,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            alert = nil
        })
        alert.addAction(action)
        
//        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        })
    }
}

func filesOfTypeInCache(_ fileType:String) -> [String]?
{
    var files = [String]()
    
    let fileManager = FileManager.default
    let path = cachesURL()?.path
    do {
        let array = try fileManager.contentsOfDirectory(atPath: path!)
        
        for string in array {
            if string.range(of: fileType) != nil {
                if fileType == string.substring(from: string.range(of: fileType)!.lowerBound) {
                    files.append(string)
                }
            }
        }
    } catch let error as NSError {
        NSLog(error.localizedDescription)
        print("failed to get files in caches directory")
    }
    
    return files.count > 0 ? files : nil
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

func stringWithoutPrefixes(_ fromString:String?) -> String?
{
    var sortString = fromString
    
    let quote:String = "\""
    let prefixes = ["A ","An ","And ","The "]
    
    if (fromString?.endIndex >= quote.endIndex) && (fromString?.substring(to: quote.endIndex) == quote) {
        sortString = fromString!.substring(from: quote.endIndex)
    }
    
    for prefix in prefixes {
        if (fromString?.endIndex >= prefix.endIndex) && (fromString?.substring(to: prefix.endIndex) == prefix) {
            sortString = fromString!.substring(from: prefix.endIndex)
            break
        }
    }
    
    return sortString
}

