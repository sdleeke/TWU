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
    return (lhs.name == rhs.name)
}

func != (lhs:Series,rhs:Series) -> Bool
{
    return (lhs.name != rhs.name)
}

class Series : NSObject
{
    deinit {
        debug(self)
    }
    
    var fullText : String?
    {
        get {
            guard let title = title, let url = url else {
                return nil
            }
            
            var string = "\(title) by Tom Pennington from The Word Unleashed"
            
            // .replacingOccurrences(of: "\n\n", with: "\n")
            if let description = text?.replacingOccurrences(of: " ???", with: ",").replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "—", with: "&mdash;").replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n\n\n", with: "\n\n").replacingOccurrences(of: "’", with: "&rsquo;").replacingOccurrences(of: "“", with: "&ldquo;").replacingOccurrences(of: "”", with: "&rdquo;").replacingOccurrences(of: "?۪s", with: "'s").replacingOccurrences(of: "…", with: "...") {
                string += "\n\n\(description)"
            }
            
            if let sermons = sermons {
                var sermonDescriptions = [String:String]()
                
                for sermon in sermons {
                    if let string = sermon.text?.replacingOccurrences(of: " ???", with: ",").replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "—", with: "&mdash;").replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n\n\n", with: "\n\n").replacingOccurrences(of: "’", with: "&rsquo;").replacingOccurrences(of: "“", with: "&ldquo;").replacingOccurrences(of: "”", with: "&rdquo;").replacingOccurrences(of: "?۪s", with: "'s").replacingOccurrences(of: "…", with: "...") {
                        if let partNumber = sermon.partNumber {
                            sermonDescriptions[partNumber] = string
                        }
                    }
                }

                if sermonDescriptions.count > 0 {
                    for sermonDescriptionKey in sermonDescriptions.keys.sorted(by: { (first,second) -> Bool in
                        return Int(first) < Int(second)
                    }) {
                        if let sermonDescription = sermonDescriptions[sermonDescriptionKey] {
                            string += "\n"
                            string += "\n"
                            string += "Part \(sermonDescriptionKey) of \(sermonDescriptions.keys.count)"
                            string += "\n"
                            string += sermonDescription
                        }
                    }
                }
            }
            
            string += "\n\n\(url.absoluteString)"

            return string
        }
    }
    
    var dict:[String:Any]?
    
    init(seriesDict:[String:Any]?)
    {
        super.init()
        
        dict = seriesDict

        if let programs = dict?["programs"] as? [[String:Any]] {
            for program in programs {
                let sermon = Sermon(series: self,dict:program)
                if sermons == nil {
                    sermons = [sermon]
                } else {
                    sermons?.append(sermon)
                }
            }
        }

//        switch Constants.JSON.URL {
////        case Constants.JSON.URLS.MEDIALIST_PHP:
////            fallthrough
//
//        case Constants.JSON.URLS.MEDIALIST_JSON:
//            guard show > 0 else {
//                break
//            }
//
//            for i in 0..<show {
//                let sermon = Sermon(series: self, dict: ["part":"\(i+1)","mediaCode":"twu\(String(format: Constants.FILENAME_FORMAT, startingIndex+i))"])
//                if sermons == nil {
//                    sermons = [sermon]
//                } else {
//                    sermons?.append(sermon)
//                }
//            }
//            break
//
//        case Constants.JSON.URLS.SERIES_JSON:
//            if let programs = dict?["programs"] as? [[String:Any]] {
//                for program in programs {
//                    let sermon = Sermon(series: self,dict:program)
//                    if sermons == nil {
//                        sermons = [sermon]
//                    } else {
//                        sermons?.append(sermon)
//                    }
//                }
//            }
//            break
//
//        default:
//            break
//        }
    }
    
//    var id:Int!
//    {
//        get {
////            guard Constants.JSON.URL == Constants.JSON.URLS.MEDIALIST_PHP else {
////                return nil
////            }
//
//            guard let seriesID = seriesID else {
//                return nil
//            }
//
//            if let num = Int(seriesID) {
//                return num
//            } else {
//                return nil
//            }
//        }
//    }

//    var seriesID:String!
//    {
//        get {
//            switch Constants.JSON.URL {
//            case Constants.JSON.URLS.MEDIALIST_PHP:
//                return dict?[Constants.FIELDS.ID] as? String
//
//            case Constants.JSON.URLS.MEDIALIST_JSON:
//                fallthrough
//
//            case Constants.JSON.URLS.SERIES_JSON:
//                return name
//
//            default:
//                return nil
//            }
//        }
//    }
    
    var url:URL?
    {
        guard let name = name else {
            return nil
        }
        return URL(string: Constants.URL.BASE.SERIES_WEB + name)

//        get {
//            switch Constants.JSON.URL {
//            case Constants.JSON.URLS.MEDIALIST_PHP:
//                if let id = id {
//                    return URL(string: Constants.URL.BASE.PHP_WEB + "\(id)")
//                } else {
//                    return nil
//                }
//
//            case Constants.JSON.URLS.MEDIALIST_JSON:
//                fallthrough
//
//            case Constants.JSON.URLS.SERIES_JSON:
//                return URL(string: Constants.URL.BASE.SERIES_WEB + name)
//
//            default:
//                return nil
//            }
//        }
    }

    var name:String?
    {
        get {
            return dict?[Constants.FIELDS.NAME] as? String
        }
    }
    
    var title:String?
    {
        get {
            return dict?[Constants.FIELDS.TITLE] as? String
        }
    }
    
    var scripture:String?
    {
        get {
            return dict?[Constants.FIELDS.SCRIPTURE] as? String
        }
    }
    
    var text:String?
    {
        return dict?[Constants.FIELDS.DESCRIPTION] as? String

//        get {
//            switch Constants.JSON.URL {
//            case Constants.JSON.URLS.MEDIALIST_PHP:
//                return dict?[Constants.FIELDS.TEXT] as? String
//
//            case Constants.JSON.URLS.MEDIALIST_JSON:
//                return dict?[Constants.FIELDS.TEXT] as? String
//
//            case Constants.JSON.URLS.SERIES_JSON:
//                return dict?[Constants.FIELDS.DESCRIPTION] as? String
//
//            default:
//                return nil
//            }
//        }
    }
    
//    var startingIndex:Int
//    {
//        get {
//            switch Constants.JSON.URL {
//            case Constants.JSON.URLS.MEDIALIST_PHP:
//                if let startingIndex = dict?[Constants.FIELDS.STARTING_INDEX] as? String {
//                    if let startingIndex = Int(startingIndex) {
//                        return startingIndex
//                    }
//                }
//                return -1
//
//            case Constants.JSON.URLS.MEDIALIST_JSON:
//                if let startingIndex = dict?[Constants.FIELDS.STARTING_INDEX] as? Int {
//                    return startingIndex
//                }
//                return -1
//
//            case Constants.JSON.URLS.SERIES_JSON:
//                return -1
//
//            default:
//                return -1
//            }
//        }
//    }
    
    var programs:[[String:Any]]?
    {
//        guard Constants.JSON.URL == Constants.JSON.URLS.SERIES_JSON else {
//            return nil
//        }
        
        return dict?["programs"] as? [[String:Any]]
    }
    
    var featuredStartDate:String?
    {
        get {
            return dict?[Constants.FIELDS.FEATURED_START_DATE] as? String
            
//            switch Constants.JSON.URL {
//            case Constants.JSON.URLS.MEDIALIST_PHP:
//                return nil
//
//            case Constants.JSON.URLS.MEDIALIST_JSON:
//                fallthrough
//
//            case Constants.JSON.URLS.SERIES_JSON:
//                return dict?[Constants.FIELDS.FEATURED_START_DATE] as? String
//
//            default:
//                return nil
//            }
        }
    }
    
//    var show:Int
//    {
//        get {
//            switch Constants.JSON.URL {
//            case Constants.JSON.URLS.MEDIALIST_PHP:
//                if let show = dict?[Constants.FIELDS.SHOW] as? String { // , let num = Int(show)
//                    return Int(show)!
//                } else {
//                    return numberOfSermons
//                }
//
//            case Constants.JSON.URLS.MEDIALIST_JSON:
//                if let show = dict?[Constants.FIELDS.SHOW] as? Int { // , let num = Int(show)
//                    return show
//                } else {
//                    return numberOfSermons
//                }
//
//            case Constants.JSON.URLS.SERIES_JSON:
//                return sermons?.count ?? -1
//
//            default:
//                return -1
//            }
//        }
//    }

//    var numberOfSermons:Int
//    {
//        get {
//            switch Constants.JSON.URL {
//            case Constants.JSON.URLS.MEDIALIST_PHP:
//                if let numberOfSermons = dict?[Constants.FIELDS.NUMBER_OF_SERMONS] as? String {
//                    return Int(numberOfSermons)!
//                } else {
//                    return -1
//                }
//
//            case Constants.JSON.URLS.MEDIALIST_JSON:
//                if let numberOfSermons = dict?[Constants.FIELDS.NUMBER_OF_SERMONS] as? Int {
//                    return numberOfSermons
//                } else {
//                    return -1
//                }
//
//            case Constants.JSON.URLS.SERIES_JSON:
//                return sermons?.count ?? -1
//
//            default:
//                return -1
//            }
//        }
//    }
    
    var titleSort:String?
    {
        get {
            return title?.withoutPrefixes.lowercased()
        }
    }

    var coverArtURL : URL?
    {
        get {
//            guard Constants.JSON.URL != Constants.JSON.URLS.MEDIALIST_PHP else {
//                if let name = name {
//                    return URL(string:"\(Constants.URL.BASE.PHP_IMAGE)\(Constants.COVER_ART_PREAMBLE)\(name)\(Constants.COVER_ART_POSTAMBLE)\(Constants.FILE_EXTENSION.JPEG)")
//                }
//
//                return nil
//            }
            
            guard let imageURL = Globals.shared.series.meta.imageURL else {
                return nil
            }
            
            guard let imageName = name else {
                return nil
            }
            
            guard let squareSuffix = Globals.shared.series.meta.squareSuffix else {
                return nil
            }
            
            let coverArtURL = imageURL + imageName + squareSuffix
            
            return coverArtURL.url
        }
    }

    lazy var coverArt:FetchImage? = { [weak self] in
        guard let coverArtURL = coverArtURL else {
            return nil
        }
    
        return FetchImage(url: coverArtURL)
    }()
    
    var book:String?
    {
        get {
            guard let scripture = scripture else {
                return nil
            }
            
            if (dict?[Constants.FIELDS.BOOK] == nil) {
                if (scripture == Constants.Selected_Scriptures) {
                    dict?[Constants.FIELDS.BOOK] = Constants.Selected_Scriptures
                } else {
                    if (dict?[Constants.FIELDS.BOOK] == nil) {
                        for bookTitle in Constants.TESTAMENT.OLD {
                            if scripture.endIndex >= bookTitle.endIndex, String(scripture[..<bookTitle.endIndex]) == bookTitle {
                                    dict?[Constants.FIELDS.BOOK] = bookTitle
                                    break
                            }
                        }
                    }
                    if (dict?[Constants.FIELDS.BOOK] == nil) {
                        for bookTitle in Constants.TESTAMENT.NEW {
                            if scripture.endIndex >= bookTitle.endIndex, String(scripture[..<bookTitle.endIndex]) == bookTitle {
                                    dict?[Constants.FIELDS.BOOK] = bookTitle
                                    break
                            }
                        }
                    }
                }
            }
            
            return dict?[Constants.FIELDS.BOOK] as? String
        }
    }

    var sermons:[Sermon]?
    {
        didSet {
            guard let sermons = sermons else {
                return
            }
            
            for sermon in sermons {
                if let id = sermon.id {
                    if index == nil {
                        index = [String:Sermon]()
                    }
                    index?[id] = sermon
                }
            }
        }
    }
    var index:[String:Sermon]?
    
    lazy var seriesSettings:SeriesSettings? = { [weak self] in
        return SeriesSettings(series:self)
    }()

    var sermonSelected:Sermon?
    {
        get {
            if let sermonID = seriesSettings?[Constants.SETTINGS.SELECTED.SERMON] {
                return sermons?.filter({ (sermon) -> Bool in
                    return sermon.id == sermonID
                }).first
            }

            return nil
        }
        
        set {
            guard let newValue = newValue else {
                print("newValue == nil")
                return
            }
            
            guard let sermonID = newValue.id else {
                print("sermonID == nil")
                return
            }
            
            seriesSettings?[Constants.SETTINGS.SELECTED.SERMON] = sermonID
        }
    }
    
    override var description : String
    {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var seriesString = "Series: "
        
        if let title = title, !title.isEmpty {
            seriesString = "\(seriesString ) \(title)"
        }
        
        if let scripture = scripture, !scripture.isEmpty {
            seriesString = "\(seriesString ) \(scripture)"
        }
        
        if let name = name, !name.isEmpty {
            seriesString = "\(seriesString)\n\(name)"
        }
        
//        seriesString = "\(seriesString) \(startingIndex)"
        
        if let numberOfSermons = sermons?.count {
            seriesString = "\(seriesString) \(numberOfSermons)"
        }
        
//        if let text = text, !text.isEmpty {
//            seriesString = "\(seriesString)\n\(text)"
//        }
        
        return seriesString
    }
}

