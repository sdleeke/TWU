//
//  Constants.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

enum Constants {
    static let APP_ID = "org.countrysidebible.TWU"
    
    static let CMTime_Resolution = Int32(1000)
    
    static let SUPPORT_REMOTE_NOTIFICATION = true
    
    static let Email_TWU = "E-mail TWU"
    static let TWU_Website = "TWU Website"
    
    static let Share_This_App = "Share This App"
    
    static let MIN_PLAY_TIME = 15.0
    static let MIN_LOAD_TIME = 30.0
    
    enum INTERVALS {
        enum TIMERS {
            static let SLIDER       = 0.1
            static let PLAYER       = 0.1
            static let LOADING      = 0.2
            static let PROGRESS     = 0.1
        }
        
        static let PLAY_OBSERVER_TIME = 10.0 // seconds
        
        static let VIEW_TRANSITION_TIME = 0.50 // seconds
        static let SKIP_TIME = 15
    }
    
    enum FIELDS {
        static let ID = "id"

        static let NAME = "name"
        static let FEATURED_START_DATE = "featuredStartDate"
        static let TITLE = "title"
        static let SCRIPTURE = "scripture"
        static let BOOK = "book"
        static let TEXT = "text"
        static let DESCRIPTION = "description"

        static let STARTING_INDEX = "startingIndex"
        static let NUMBER_OF_SERMONS = "numberOfSermons"
        static let SHOW = "show"
    }
    
    enum NOTIFICATION {
        static let UPDATE_PLAY_PAUSE        = "UPDATE PLAY PAUSE"
        static let UPDATE_PLAYING_PAUSED    = "UPDATE PLAYING PAUSED"
        
        static let REACHABLE                = "REACHABLE"
        static let NOT_REACHABLE            = "NOT REACHABLE"
        
        static let DONE_SEEKING             = "DONE SEEKING"
        
        static let READY_TO_PLAY            = "READY TO PLAY"

        static let FAILED_TO_PLAY           = "FAILED TO PLAY"
        static let FAILED_TO_LOAD           = "FAILED TO LOAD"

        static let SHOW_PLAYING             = "SHOW PLAYING"

        static let UPDATE_VIEW              = "UPDATE VIEW"
        static let CLEAR_VIEW               = "CLEAR VIEW"

        static let PAUSED                   = "PAUSED"

        static let SERIES_UPDATE_UI         = "SERIES UPDATE UI"
        static let SERMON_UPDATE_UI         = "SERMON UPDATE UI"
        
        static let MEDIA_DOWNLOAD_FAILED    = "MEDIA DOWNLOAD FAILED"
        
        static let SHOWING_ABOUT_CHANGED    = "SHOWING ABOUT CHANGED"
    }
    
    enum JSON {
        enum KEYS {
//            static let SERIES = "series"
            static let DATA = "data"
            static let META = "meta"
        }
        
//        enum URLS {
//            static let MEDIALIST_PHP = "https://www.thewordunleashed.org/medialist.php"
//            static let MEDIALIST_JSON = "https://www.thewordunleashed.org/medialist.json" // craft.
//            static let SERIES_JSON = "https://www.thewordunleashed.org/series.json" // craft.
//        }
//
//        static let URL = URLS.SERIES_JSON // URLS.MEDIALIST_PHP

        static let SERIES_JSON = "https://www.thewordunleashed.org/series.json" // craft.

//        static let SERIES = "series.json"
    }
    
    enum CBC {
        static let WEBSITE  = "https://www.countrysidebible.org"
        static let APP_URL  = "https://itunes.apple.com/us/app/countryside-bible-church/id1166303807?mt=8"
        static let ARCHIVES_URL = "cbc://category=Sermons&tag=Pennington,%20Tom&sorting=reverse%20chronological&grouping=year"
    }
    
    enum TWU {
        static let SHORT = "TWU"
        static let LONG = "The Word Unleashed"
        
        static let APP = LONG + SINGLE_SPACE + "App"
        static let APP_URL = "https://itunes.apple.com/us/app/the-word-unleashed/id1145083780?ls=1&mt=8"
        
        static let EMAIL = "listeners@thewordunleashed.org"
        static let WEBSITE = "https://www.thewordunleashed.org"

        static let GIVING_URL = "https://countrysidebible.ccbchurch.com/goto/giving" // "https://countryside.infellowship.com/OnlineGiving/GiveNow/NoAccount/"
    }
    
    enum REMOTE_NOTIFICATION {
        static let SUBSCRIPTION_RECORD_TYPE = "Globals"
        static let CATEGORY = "UPDATE"
        static let ALERT_BODY = "Update Available"
        static let DESIRED_KEYS = ["Title","ID","Show"]
        static let NOW_ACTION_IDENTIFIER = "NOW"
        static let NOW_ACTION_TITLE = "Update Now"
        static let LATER_ACTION_IDENTIFIER = "LATER"
        static let LATER_ACTION_TITLE = "Update Later"
    }
    
    enum IDENTIFIER {
        static let POPOVER_CELL = "PopoverCell"
        static let POPOVER_TABLEVIEW = "PopoverTableView"
        
        static let SERIES_CELL = "SeriesCell"
        static let SERMON_CELL = "SeriesSermon"
        
        static let DOWNLOAD = "com.leeke.TWU.download."
    }
    
    enum Fonts {
        static let body = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        
        static let bold = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        
        enum Attributes {
            static let normal = [ NSAttributedStringKey.font: Fonts.body ]
            
            static let bold = [ NSAttributedStringKey.font: Fonts.bold ]
            
            static let marked = [ NSAttributedStringKey.backgroundColor: UIColor.lightGray,
                                  NSAttributedStringKey.font: Fonts.body ]
            
            static let highlighted = [ NSAttributedStringKey.backgroundColor: UIColor.yellow,
                                       NSAttributedStringKey.font: Fonts.body ]
            
            static let destructive = [ NSAttributedStringKey.foregroundColor: UIColor.red,
                                       NSAttributedStringKey.font: Fonts.body ]
            
            static let boldHighlighted = [ NSAttributedStringKey.backgroundColor: UIColor.yellow,
                                           NSAttributedStringKey.font: Fonts.bold ]
        }
    }

    enum FA {
        static let name = "FontAwesome"
        static let FONT_SIZE = CGFloat(24.0)
        static let PLAY = "\u{f04b}"
        static let PAUSE = "\u{f04c}"
        static let ACTION = "\u{f150}"
    }
    
    enum FILE_EXTENSION {
        static let MP3 = ".mp3"
        static let TMP = ".tmp"
        static let JPEG = ".jpg"
    }
    
    static let COLON = ":"
    
    static let REACHABILITY_TEST_URL = Constants.TWU.WEBSITE // "https://www.google.com/"

    static let AUTO_ADVANCE = "AUTO_ADVANCE"
    
    enum Titles {
        static let Loading_Series = "Loading Series"
        static let Loading_Settings = "Loading Settings"
        
        static let Sorting = "Sorting"
        static let Setting_up_Player = "Setting up Player"
    }
    
    static let Unable_to_Load_Sermons = "Unable to Load Sermons"

    static let PLAYING = "playing"
    static let AUDIO = "audio"
    static let VIDEO = "video"

    static let Sermon_Update_Available = "Sermon Update Available"
    static let Sermon_Updates_Available = "Sermon Updates Available"

    static let Tom_Pennington = "Tom Pennington"
    
    static let ZERO = "0"

    enum URL {
        enum BASE {
            //This must support https to be compatible with iOS 9
//            static let PHP_AUDIO = "http://sitedata.thewordunleashed.org/avmedia/broadcasts/"
            static let AUDIO_PREFIX = "https://www.thewordunleashed.org/series/"  // CRAFT_ // craft.
            static let AUDIO_POSTFIX = "?media=audio&mediacode="

            //Used in the email and social media for series
//            static let PHP_WEB = "http://www.thewordunleashed.org/index.php/series?seriesId="
            static let SERIES_WEB = "https://www.thewordunleashed.org/series/" // craft.

            static let SERMON_WEB = "https://www.countrysidebible.org/cbcmedia?return=single&mediacode="
            
            //Used for testing downloading the album art in real time - which didn't meet performance requirements,
            //we would have to implement caching, which is more work that embedding the album art in the app resources, at least for now.
//            static let PHP_IMAGE = "http://sitedata.thewordunleashed.org/avmedia/series/"
        }
    }
    
    enum SCRIPTURE_URL {
        static let PREFIX = "http://www.biblegateway.com/passage/?search="
        static let POSTFIX = "&version=NASB"
    }
    
    enum SEGUE {
        static let SHOW_ABOUT = "Show About"
        static let SHOW_SERIES = "Show Series"
        static let SHOW_SETTINGS = "Show Settings"
    }
    
    enum SETTINGS {
        enum SELECTED {
            static let SERIES = "series selected"
            static let SERMON = "sermon selected"
        }

        enum PLAYING {
            static let SERIES = "series playing"
            static let SERMON = "sermon playing"
        }

        static let AT_END = "At End"
        
        enum KEY {
            static let SERIES = "Series Settings"
            static let SERMON = "Sermon Settings"
        }
    }
    
    static let COVER_ART_PREAMBLE = "series_"
    static let COVER_ART_POSTAMBLE = "_512w512h"
    
    static let CURRENT_TIME = "currentTime"

    static let DOWNLOADING_TITLE = "Downloading Sermons"
    
    static let FILENAME_FORMAT = "%04d" // + Constants.FILE_EXTENSION.MP3
    
    static let EMPTY_STRING = ""
    static let SINGLE_SPACE = " "
    static let NEWLINE = "\n"
    static let FORWARD_SLASH = "/"
    
    static let Network_Error = "Network Error"
    static let The_Word_Unleashed = "The Word Unleashed"
    
    static let All = "All"
    
    static let FORMAT = "format"
    
    static let SORTING = "sorting"
    static let Sort = "Sort"
    static let Sorting_Options_Title = "Sort"
    
    enum Sorting {
        static let Newest_to_Oldest = "Newest to Oldest"
        static let Oldest_to_Newest = "Oldest to Newest"
        static let Title_AZ = "Title A - Z"
        static let Title_ZA = "Title Z - A"
        
        static let Options = [Newest_to_Oldest,Oldest_to_Newest,Title_AZ,Title_ZA]
    }
    
    static let FILTER = "filter"
    static let Filter = "Filter"
    static let Filtering_Options_Title = "Filter by Scripture"

    static let Settings = "Settings"
    static let Settings_Title = "Settings"
    
    static let Play = "Play"
    static let Pause = "Pause"
    
    static let Playing = "Playing"
    static let Paused = "Paused"
    
    static let None = "None"
    
    static let Okay = "OK"
    static let Cancel = "Cancel"
    
    static let Email_Subject = "Recommendation"
    
    static let Download = "Download"
    static let Downloaded = Download + "ed"
    static let Downloading = Download + "ing"
    
    static let Download_All = "Download All"
    static let Cancel_All_Downloads = "Cancel All Downloads"
    static let Delete_All_Downloads = "Delete All Downloads"
    
    static let Selected_Scriptures = "Selected Scriptures"
    static let Open_Scripture = "Open Scripture"
    
    static let Open_Series = "Open on TWU" // Series //  Web Site
    static let Open_Sermon = "Open on CBC" // Series //  Web Site
//    static let Email_Series = "E-Mail" // Series
    static let Share = "Share" // Series
    
    static let Share_on_Facebook = "Share on Facebook"
    static let Share_on_Twitter = "Share on Twitter"

    enum TESTAMENT {
        static let OLD:[String] = [
            "Genesis",
            "Exodus",
            "Leviticus",
            "Numbers",
            "Deuteronomy",
            "Joshua",
            "Judges",
            "Ruth",
            "1 Samuel",
            "2 Samuel",
            "1 Kings",
            "2 Kings",
            "1 Chronicles",
            "2 Chronicles",
            "Ezra",
            "Nehemiah",
            "Esther",
            "Job",
            "Psalm",
            "Proverbs",
            "Ecclesiastes",
            "Song of Solomon",
            "Isaiah",
            "Jeremiah",
            "Lamentations",
            "Ezekiel",
            "Daniel",
            "Hosea",
            "Joel",
            "Amos",
            "Obadiah",
            "Jonah",
            "Micah",
            "Nahum",
            "Habakkuk",
            "Zephaniah",
            "Haggai",
            "Zechariah",
            "Malachi"
        ]

        static let NEW:[String] = [
            "Matthew",
            "Mark",
            "Luke",
            "John",
            "Acts",
            "Romans",
            "1 Corinthians",
            "2 Corinthians",
            "Galatians",
            "Ephesians",
            "Philippians",
            "Colossians",
            "1 Thessalonians",
            "2 Thessalonians",
            "1 Timothy",
            "2 Timothy",
            "Titus",
            "Philemon",
            "Hebrews",
            "James",
            "1 Peter",
            "2 Peter",
            "1 John",
            "2 John",
            "3 John",
            "Jude",
            "Revelation"
        ]
    }
}

