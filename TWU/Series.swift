//
//  Series.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class ScriptureReference {
    var book:String
    var chapter:Int
    var verse:Int //could also have a qualifier, e.g. a lowercase letter.
    
    init() {
        book = ""
        chapter = 0
        verse = 0
    }
}

class ScripturePassage {
    //could both be the same book for an intrabook passage
    var startingScriptureReference : ScriptureReference
    var endingScriptureReference : ScriptureReference
    
    init() {
        startingScriptureReference = ScriptureReference()
        endingScriptureReference = ScriptureReference()
    }
}

func removeObject<T:Equatable>(inout arr:Array<T>, object:T) -> T? {
    if let found = arr.indexOf(object) {
        return arr.removeAtIndex(found)
    }
    return nil
}

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
        
        for i in 0..<numberOfSermons {
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
            return Int(dict![Constants.ID]!)!
        }
    }
    
    var url:NSURL? {
        get {
            return NSURL(string: Constants.BASE_WEB_URL + "\(id)")
        }
    }
    
    var name:String? {
        get {
            return dict![Constants.NAME]
        }
    }
    
    var title:String? {
        get {
            return dict![Constants.TITLE]
        }
    }
    
    var scripture:String? {
        get {
            return dict![Constants.SCRIPTURE]
        }
    }
    
    var text:String? {
        get {
            return dict![Constants.TEXT]
        }
    }
    
    var startingIndex:Int {
        get {
            return Int(dict![Constants.STARTING_INDEX]!)!
        }
    }
    
    var show:Int? {
        get {
            if (dict![Constants.SHOW] != nil) {
                return Int(dict![Constants.SHOW]!)!
            } else {
                return Int(dict![Constants.NUMBER_OF_SERMONS]!)!
            }
        }
    }
    
    var numberOfSermons:Int {
        get {
            return Int(dict![Constants.NUMBER_OF_SERMONS]!)!
        }
    }
    
    var titleSort:String? {
        get {
            if (dict![Constants.TITLE+Constants.SORTING] == nil) {
                dict![Constants.TITLE+Constants.SORTING] = stringWithoutPrefixes(title)?.lowercaseString
            }
            
            return dict![Constants.TITLE+Constants.SORTING]
        }
    }

    var coverArt:String?
    
    var book:String? {
        get {
            if (dict![Constants.BOOK] == nil) {
                if (scripture == Constants.Selected_Scriptures) {
                    dict![Constants.BOOK] = Constants.Selected_Scriptures
                } else {
                    if (dict![Constants.BOOK] == nil) {
                        for bookTitle in Constants.OLD_TESTAMENT {
                            if (scripture!.endIndex >= bookTitle.endIndex) &&
                                (scripture!.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                    dict![Constants.BOOK] = bookTitle
                                    break
                            }
                        }
                    }
                    if (dict![Constants.BOOK] == nil) {
                        for bookTitle in Constants.NEW_TESTAMENT {
                            if (scripture!.endIndex >= bookTitle.endIndex) &&
                                (scripture!.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                    dict![Constants.BOOK] = bookTitle
                                    break
                            }
                        }
                    }
                }
            }
            
            return dict![Constants.BOOK]
        }
    }

    func getArt() -> UIImage?
    {
        let imageName = "\(Constants.COVER_ART_PREAMBLE)\(name!)\(Constants.COVER_ART_POSTAMBLE)"
        var image = UIImage(named:imageName)
        
        // If we don't have it, see if it is in the file system and if not, download it and store it in the file system.
        
        if (image == nil) {
            // Check to see if it is in the file system.
            let imageURL = cachesURL()?.URLByAppendingPathComponent(imageName + Constants.JPEG_FILE_EXTENSION)
            image = UIImage(contentsOfFile: imageURL!.path!)
            
            if (image == nil) {
                // Try to get it from the cloud
                let imageCloudURL = Constants.baseImageURL + imageName + Constants.JPEG_FILE_EXTENSION
                //                print("\(imageCloudURL)")
                if let imageData = NSData(contentsOfURL: NSURL(string: imageCloudURL)!) {
                    image = UIImage(data: imageData)
                    if (image != nil) {
                        UIImageJPEGRepresentation(image!, 1.0)?.writeToURL(imageURL!, atomically: true)
                    } else {
                        // Can't get it from anywhere.
                    }
                } else {
                    // Can't get it from anywhere.
                }
            }
        }
        
        return image
    }
    
    var sermons:[Sermon]?
    
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

