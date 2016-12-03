//
//  Series.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

func == (lhs:Series,rhs:Series) -> Bool
{
    return (lhs.name == rhs.name) && (lhs.id == rhs.id)
}

func != (lhs:Series,rhs:Series) -> Bool
{
    return (lhs.name != rhs.name) || (lhs.id != rhs.id)
}

class Series : Equatable, CustomStringConvertible {
    var dict:[String:String]?
    
    init(seriesDict:[String:String]?)
    {
        dict = seriesDict
        
        for i in 0..<show {
            let sermon = Sermon(series: self,id:startingIndex+i)
            if sermons == nil {
                sermons = [sermon]
            } else {
                sermons?.append(sermon)
            }
        }
    }
    
    var id:Int {
        get {
            return Int(seriesID!)!
        }
    }
    
    var seriesID:String? {
        get {
            return dict![Constants.FIELDS.ID]        }
    }
    
    var url:URL? {
        get {
            return URL(string: Constants.URL.BASE.WEB + "\(id)")
        }
    }
    
    var name:String? {
        get {
            return dict![Constants.FIELDS.NAME]
        }
    }
    
    var title:String? {
        get {
            return dict![Constants.FIELDS.TITLE]
        }
    }
    
    var scripture:String? {
        get {
            return dict![Constants.FIELDS.SCRIPTURE]
        }
    }
    
    var text:String? {
        get {
            return dict![Constants.FIELDS.TEXT]
        }
    }
    
    var startingIndex:Int {
        get {
            return Int(dict![Constants.FIELDS.STARTING_INDEX]!)!
        }
    }
    
    var show:Int {
        get {
            if (dict![Constants.FIELDS.SHOW] != nil) {
                return Int(dict![Constants.FIELDS.SHOW]!)!
            } else {
                return numberOfSermons
            }
        }
    }
    
    var numberOfSermons:Int {
        get {
            return Int(dict![Constants.FIELDS.NUMBER_OF_SERMONS]!)!
        }
    }
    
    var titleSort:String? {
        get {
            if (dict![Constants.FIELDS.TITLE+Constants.SORTING] == nil) {
                dict![Constants.FIELDS.TITLE+Constants.SORTING] = stringWithoutPrefixes(title)?.lowercased()
            }
            
            return dict![Constants.FIELDS.TITLE+Constants.SORTING]
        }
    }

    var coverArt:String?
    
    var book:String? {
        get {
            if (dict![Constants.FIELDS.BOOK] == nil) {
                if (scripture == Constants.Selected_Scriptures) {
                    dict![Constants.FIELDS.BOOK] = Constants.Selected_Scriptures
                } else {
                    if (dict![Constants.FIELDS.BOOK] == nil) {
                        for bookTitle in Constants.TESTAMENT.OLD {
                            if (scripture!.endIndex >= bookTitle.endIndex) &&
                                (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
                                    dict![Constants.FIELDS.BOOK] = bookTitle
                                    break
                            }
                        }
                    }
                    if (dict![Constants.FIELDS.BOOK] == nil) {
                        for bookTitle in Constants.TESTAMENT.NEW {
                            if (scripture!.endIndex >= bookTitle.endIndex) &&
                                (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
                                    dict![Constants.FIELDS.BOOK] = bookTitle
                                    break
                            }
                        }
                    }
                }
            }
            
            return dict![Constants.FIELDS.BOOK]
        }
    }

    func getArt() -> UIImage?
    {
        let imageName = "\(Constants.COVER_ART_PREAMBLE)\(name!)\(Constants.COVER_ART_POSTAMBLE)"
        
        // If we don't have it, see if it is in the file system and if not, download it and store it in the file system.
        
        if let image = UIImage(named:imageName) {
            return image
        } else {
            print("Image \(imageName) not in bundle")
            
            // Check to see if it is in the file system.
            if let imageURL = cachesURL()?.appendingPathComponent(imageName + Constants.FILE_EXTENSION.JPEG) {
                if let image = UIImage(contentsOfFile: imageURL.path) {
                    return image
                } else {
                    print("Image \(imageName) not in file system")
                    
                    // Try to get it from the cloud
                    let imageCloudURL = Constants.URL.BASE.IMAGE + imageName + Constants.FILE_EXTENSION.JPEG
                    //                print("\(imageCloudURL)")
                    if let imageData = try? Data(contentsOf: URL(string: imageCloudURL)!) {
                        if let image = UIImage(data: imageData) {
                            try? UIImageJPEGRepresentation(image, 1.0)?.write(to: imageURL, options: [.atomic])
                        }
                    } else {
                        // Can't get it from anywhere.
                    }
                }
            }
        }
        
        return nil
    }
    
    var sermons:[Sermon]?
    
    struct Settings {
        weak var series:Series?
        
        init(series:Series?) {
            if (series == nil) {
                print("nil series in Settings init!")
            }
            self.series = series
        }
        
        subscript(key:String) -> String? {
            get {
                var value:String?
                value = globals.seriesSettings?[self.series!.seriesID!]?[key]
                return value
            }
            set {
                guard (newValue != nil) else {
                    print("newValue == nil in Settings!")
                    return
                }
                
                guard (series != nil) else {
                    print("series == nil in Settings!")
                    return
                }
                
                guard (series!.seriesID != nil) else {
                    print("series!.seriesID == nil in Settings!")
                    return
                }
                
                if (globals.seriesSettings == nil) {
                    globals.seriesSettings = [String:[String:String]]()
                }
                
                if (globals.seriesSettings?[self.series!.seriesID!] == nil) {
                    globals.seriesSettings?[self.series!.seriesID!] = [String:String]()
                }
                
                globals.seriesSettings?[self.series!.seriesID!]?[key] = newValue
                
                // For a high volume of activity this can be very expensive.
                globals.saveSettingsBackground()
            }
        }
    }

    lazy var settings:Settings? = {
        return Settings(series:self)
    }()

    var sermonSelected:Sermon? {
        get {
            if let sermonID = settings?[Constants.SETTINGS.SELECTED.SERMON] {
//                print(sermonID)
//                print(sermonID.substring(from: sermonID.range(of: ":")!.upperBound))
//                print(Int(sermonID.substring(from: sermonID.range(of: ":")!.upperBound))! - startingIndex)
                return sermons?[Int(sermonID.substring(from: sermonID.range(of: Constants.COLON)!.upperBound))! - startingIndex]
            } else {
                return nil
            }
        }
        
        set {
            if (newValue != nil) {
//                print(newValue!.sermonID!)
                settings?[Constants.SETTINGS.SELECTED.SERMON] = newValue!.sermonID!
            } else {
                print("newValue == nil")
            }
        }
    }
    
    init() {
    }
    
//    func bookFromScripture()
//    {
//        let selectedScriptures:String = Constants.Selected_Scriptures
//        
//        if (scripture == selectedScriptures) {
//            book = selectedScriptures
//        } else {
//            for bookTitle in Constants.OLD_TESTAMENT {
//                if (scripture.endIndex >= bookTitle.endIndex) &&
//                    (scripture.substringToIndex(bookTitle.endIndex) == bookTitle) {
//                        book = bookTitle
//                }
//            }
//            for bookTitle in Constants.NEW_TESTAMENT {
//                if (scripture.endIndex >= bookTitle.endIndex) &&
//                    (scripture.substringToIndex(bookTitle.endIndex) == bookTitle) {
//                        book = bookTitle
//                }
//            }
//        }
//        
//        //        println("\(book)")
//        
//        if (scripture != selectedScriptures) && (book == Constants.EMPTY_STRING) {
//            print("ERROR in bookFromScripture")
//            print("\(scripture)")
//            print("\(book)")
//        }
//    }

    var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var seriesString = "Series: "
        
        if (title != "") {
            seriesString = "\(seriesString) \(title)"
        }
        
        if (scripture != "") {
            seriesString = "\(seriesString) \(scripture)"
        }
        
        if (name != "") {
            seriesString = "\(seriesString)\n\(name)"
        }
        
        seriesString = "\(seriesString)\n\(id)"
        
        seriesString = "\(seriesString) \(startingIndex)"
        
        seriesString = "\(seriesString) \(numberOfSermons)"
        
        seriesString = "\(seriesString)\n\(text)"
        
        return seriesString
    }
}

