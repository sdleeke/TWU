//
//  Series.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation

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
    
    var id:Int {
        get {
            return Int(dict![Constants.ID]!)!
        }
    }
    
    var name:String {
        get {
            return dict![Constants.NAME]!
        }
    }
    
    var title:String {
        get {
            return dict![Constants.TITLE]!
        }
    }
    
    var scripture:String {
        get {
            return dict![Constants.SCRIPTURE]!
        }
    }
    
    var text:String {
        get {
            return dict![Constants.TEXT]!
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
                dict![Constants.TITLE+Constants.SORTING] = stringWithoutLeadingTheOrAOrAn(title)?.lowercaseString
            }
            
            return dict![Constants.TITLE+Constants.SORTING]
        }
    }

    var coverArt:String?
    
    var book:String? {
        get {
            if (dict![Constants.BOOK] == nil) {
                let selectedScriptures:String = Constants.Selected_Scriptures
                
                if (scripture == selectedScriptures) {
                    dict![Constants.BOOK] = selectedScriptures
                } else {
                    if (dict![Constants.BOOK] == nil) {
                        for bookTitle in Constants.OLD_TESTAMENT {
                            if (scripture.endIndex >= bookTitle.endIndex) &&
                                (scripture.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                    dict![Constants.BOOK] = bookTitle
                            }
                        }
                    }
                    if (dict![Constants.BOOK] == nil) {
                        for bookTitle in Constants.NEW_TESTAMENT {
                            if (scripture.endIndex >= bookTitle.endIndex) &&
                                (scripture.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                    dict![Constants.BOOK] = bookTitle
                            }
                        }
                    }
                }
            }
            
            return dict![Constants.BOOK]
        }
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

