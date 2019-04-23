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


func debug(_ any:Any...)
{
    //    print(any)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    return input.rawValue
}

func startAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)))
    } catch let error as NSError {
        NSLog(error.localizedDescription)
    }
    
    UIApplication.shared.beginReceivingRemoteControlEvents()
}

func stopAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setActive(false)
    } catch let error as NSError {
        print("failed to audioSession.setActive(false): \(error.localizedDescription)")
    }
}

//func shareHTML(viewController:UIViewController,htmlString:String?)
//{
//    guard htmlString != nil else {
//        return
//    }
//    
//    let activityItems = [htmlString as Any]
//    
//    let activityViewController = UIActivityViewController(activityItems:activityItems, applicationActivities: nil)
//    
//    // exclude some activity types from the list (optional)
//    
//    activityViewController.excludedActivityTypes = [ .addToReadingList ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
//    
//    activityViewController.popoverPresentationController?.barButtonItem = viewController.navigationItem.rightBarButtonItem
//    
//    // present the view controller
//    Thread.onMainThread {
//        viewController.present(activityViewController, animated: false, completion: nil)
//    }
//}

//var documentsURL:URL?
//{
//    get {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//    }
//}

//func remove(_ filename:String)
//{
//    if let fileSystemURL = filename.fileSystemURL {
//        do {
//            try FileManager.default.removeItem(atPath: fileSystemURL.path)
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//            print("failed to copy sermons.json")
//        }
//    }
//}

//func save(_ filename:String)
//{
//    //Get documents directory URL
//    guard let fileSystemURL = filename.fileSystemURL else {
//        return
//    }
//
//    let fileManager = FileManager.default
//
//    // Check if file exist
//    if (!fileManager.fileExists(atPath: fileSystemURL.path)){
//        //            downloadJSON()
//    }
//}

//func fileSystemURL(_ filename:String?) -> URL?
//{
//    return cachesURL()?.appendingPathComponent(filename)
//}

//var cachesURL:URL?
//{
//    get {
//        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
//    }
//}

//func sortSeries(_ series:[Series]?,sorting:String?) -> [Series]?
//{
//    guard let series = series else {
//        return nil
//    }
//    
//    guard let sorting = sorting else {
//        return nil
//    }
//    
//    var results:[Series]?
//    
//    switch sorting {
//    case Constants.Sorting.Title_AZ:
//        results = series.sorted() { $0.titleSort < $1.titleSort }
//        break
//    case Constants.Sorting.Title_ZA:
//        results = series.sorted() { $0.titleSort > $1.titleSort }
//        break
//    case Constants.Sorting.Newest_to_Oldest:
//        results = series.sorted() { $0.featuredStartDate > $1.featuredStartDate }
//        
////        switch Constants.JSON.URL {
////        case Constants.JSON.URLS.MEDIALIST_PHP:
////            results = series.sorted() { $0.id > $1.id }
////
////        case Constants.JSON.URLS.MEDIALIST_JSON:
////            fallthrough
////
////        case Constants.JSON.URLS.SERIES_JSON:
////            results = series.sorted() { $0.featuredStartDate > $1.featuredStartDate }
////
////        default:
////            return nil
////        }
//        break
//    case Constants.Sorting.Oldest_to_Newest:
//        results = series.sorted() { $0.featuredStartDate < $1.featuredStartDate }
//        
////        switch Constants.JSON.URL {
////        case Constants.JSON.URLS.MEDIALIST_PHP:
////            results = series.sorted() { $0.id < $1.id }
////            
////        case Constants.JSON.URLS.MEDIALIST_JSON:
////            fallthrough
////            
////        case Constants.JSON.URLS.SERIES_JSON:
////            results = series.sorted() { $0.featuredStartDate < $1.featuredStartDate }
////            
////        default:
////            return nil
////        }
//        break
//    default:
//        break
//    }
//    
//    return results
//}

//func booksFromSeries(_ series:[Series]?) -> [String]?
//{
//    guard let series = series else {
//        return nil
//    }
//    
//    return Array(Set(series.filter({ (series:Series) -> Bool in
//        return series.book != nil
//    }).map { (series:Series) -> String in
//        return series.book!
//    })).sorted(by: { bookNumberInBible($0) < bookNumberInBible($1) })
//}

//func bookNumberInBible(_ book:String?) -> Int?
//{
//    guard let book = book else {
//        return nil
//    }
//    
//    if let index = Constants.TESTAMENT.OLD.firstIndex(of: book) {
//        return index
//    }
//    
//    if let index = Constants.TESTAMENT.NEW.firstIndex(of: book) {
//        return Constants.TESTAMENT.OLD.count + index
//    }
//    
//    return Constants.TESTAMENT.OLD.count + Constants.TESTAMENT.NEW.count+1 // Not in the Bible.  E.g. Selected Scriptures
//}
//
//func lastNameFromName(_ name:String?) -> String?
//{
//    if var lastname = name {
//        while (lastname.range(of: Constants.SINGLE_SPACE) != nil) {
//            if let range = lastname.range(of: Constants.SINGLE_SPACE) {
//                lastname = String(lastname[range.upperBound...])
//            }
//        }
//        return lastname
//    }
//    return nil
//}

//func networkUnavailable(viewController:UIViewController,message:String?)
//{
//    let alert = UIAlertController(title:Constants.Network_Error,
//        message: message,
//        preferredStyle: UIAlertController.Style.alert)
//
//    let action = UIAlertAction(title: Constants.Cancel, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
//    })
//    alert.addAction(action)
//
//    Thread.onMainThread {
//        viewController.present(alert, animated: true, completion: nil)
//    }
//}

//func filesOfTypeInCache(_ fileType:String) -> [String]?
//{
//    guard let path = cachesURL?.path else {
//        return nil
//    }
//
//    var files = [String]()
//
//    let fileManager = FileManager.default
//
//    do {
//        let array = try fileManager.contentsOfDirectory(atPath: path)
//
//        for string in array {
//            if let range = string.range(of: fileType) {
//                if fileType == String(string[range.lowerBound...]) {
//                    files.append(string)
//                }
//            }
//        }
//    } catch let error as NSError {
//        NSLog(error.localizedDescription)
//        print("failed to get files in caches directory")
//    }
//
//    return files.count > 0 ? files : nil
//}

//func alert(viewController:UIViewController,title:String?,message:String?)
//{
//    guard UIApplication.shared.applicationState == UIApplication.State.active else {
//        return
//    }
//    
//    let alert = UIAlertController(title:title,
//                                  message: message,
//                                  preferredStyle: UIAlertController.Style.alert)
//    
//    let action = UIAlertAction(title: Constants.Cancel, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
//    })
//    alert.addAction(action)
//    
//    Thread.onMainThread {
//        Globals.shared.rootViewController?.dismiss(animated: true, completion: nil)
//        viewController.present(alert, animated: true, completion: nil)
//    }
//}

//func stringWithoutPrefixes(_ fromString:String?) -> String?
//{
//    guard let fromString = fromString else {
//        return nil
//    }
//
//    var sortString = fromString
//    
//    let quote:String = "\""
//    let prefixes = ["A ","An ","And ","The "]
//    
//    if fromString.endIndex >= quote.endIndex, String(fromString[..<quote.endIndex]) == quote {
//        sortString = String(fromString[quote.endIndex...])
//    }
//    
//    for prefix in prefixes {
//        if fromString.endIndex >= prefix.endIndex, String(fromString[..<prefix.endIndex]) == prefix {
//            sortString = String(fromString[prefix.endIndex...])
//            break
//        }
//    }
//    
//    return sortString
//}

//func userAlert(title:String?,message:String?)
//{
//    if (UIApplication.shared.applicationState == UIApplication.State.active) {
//        let alert = UIAlertController(title: title,
//                                      message: message,
//                                      preferredStyle: UIAlertController.Style.alert)
//        
//        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
//            
//        })
//        alert.addAction(action)
//        
//        Thread.onMainThread {
//            Globals.shared.rootViewController?.present(alert, animated: true, completion: nil)
//        }
//    }
//}


