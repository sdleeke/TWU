//
//  Constants.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static let APP_ID = "com.leeke.TWU"
    
    static let SUPPORT_REMOTE_NOTIFICATION = true
    
    static let Email_TWU = "E-mail TWU"
    static let TWU_Website = "TWU Website"
    
    static let MIN_PLAY_TIME = 15.0
    static let MIN_LOAD_TIME = 30.0
    
    static let DOWNLOAD_TIMER_INTERVAL = 0.5
    static let SLIDER_TIMER_INTERVAL = 0.5
    static let PLAYER_TIMER_INTERVAL = 0.2
    static let SEEKING_TIMER_INTERVAL = 0.1
    
    static let COLON = ":"
    
    static let UPDATE_VIEW_NOTIFICATION = "UPDATE VIEW"
    static let CLEAR_VIEW_NOTIFICATION = "CLEAR VIEW"
    
    static let REACHABILITY_TEST_URL = Constants.TWU_WEBSITE // "https://www.google.com/"

    static let JSON_ARRAY_KEY = "series"
//    static let JSON_URL_PREFIX = "https://s3.amazonaws.com/jd2-86d4fd0ec0a8fca71eef54e388261c5b-us/"
    static let JSON_URL = "http://www.thewordunleashed.org/medialist.php"
    
    static let TWU_GIVING_URL = "https://countryside.infellowship.com/OnlineGiving/GiveNow/NoAccount/"
    
    static let TWU_SHORT = "TWU"
    static let TWU_LONG = "The Word Unleashed"
    
    static let AUTO_ADVANCE = "AUTO_ADVANCE"
    
    static let Loading_Sermons = "Loading Sermons"
    static let Loading_Settings = "Loading Settings"
    static let Sorting = "Sorting"
    static let Setting_up_Player = "Setting up Player"
    
    static let Unable_to_Load_Sermons = "Unable to Load Sermons"
    
    static let SERIES_JSON = "series.json"

    static let PLAYING = "playing"
    static let AUDIO = "audio"
    static let VIDEO = "video"

    static let SERMON_UPDATE_UI_NOTIFICATION = "SERMON UPDATE UI"
    static let SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION = "SERMON UPDATE PLAYING PAUSED"
    static let SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION = "SERMON UPDATE PLAY PAUSE"
    
//    static let SERMON_UPDATE_AVAILABLE_NOTIFICATION = "SERMON UPDATE AVAILABLE"
    
    static let SUBSCRIPTION_RECORD_TYPE = "Globals"
    static let REMOTE_NOTIFICATION_CATEGORY = "UPDATE"
    static let REMOTE_NOTIFICATION_ALERT_BODY = "Update Available"
    static let REMOTE_NOTIFICATION_DESIRED_KEYS = ["Title","ID","Show"]
    static let REMOTE_NOTIFICATION_NOW_ACTION_IDENTIFIER = "NOW"
    static let REMOTE_NOTIFICATION_NOW_ACTION_TITLE = "Update Now"
    static let REMOTE_NOTIFICATION_LATER_ACTION_IDENTIFIER = "LATER"
    static let REMOTE_NOTIFICATION_LATER_ACTION_TITLE = "Update Later"
    
    static let Sermon_Update_Available = "Sermon Update Available"
    static let Sermon_Updates_Available = "Sermon Updates Available"
    
    static let POPOVER_CELL_IDENTIFIER = "PopoverCell"
    static let POPOVER_TABLEVIEW_IDENTIFIER = "PopoverTableView"
    
    static let SERIES_CELL_IDENTIFIER = "SeriesCell"
    static let SERMON_CELL_IDENTIFIER = "SeriesSermon"
    
    static let FA_PLAY_PLAUSE_FONT_SIZE = CGFloat(24.0)
    static let FA_PLAY = "\u{f04b}"
    static let FA_PAUSE = "\u{f04c}"
    
    static let Tom_Pennington = "Tom Pennington"
    
    static let PLAY_OBSERVER_TIME_INTERVAL = 10.0 // seconds
    
    static let VIEW_TRANSITION_TIME = 1.0 // seconds
    static let SKIP_TIME_INTERVAL = 15
    static let ZERO = "0"

    //This must support https to be compatible with iOS 9
    static let BASE_AUDIO_URL = "http://sitedata.thewordunleashed.org/avmedia/broadcasts/twu"
    
    //Used in the email and social media for series
    static let BASE_WEB_URL = "http://www.thewordunleashed.org/index.php/series?seriesId="
    
    //Used for testing downloading the album art in real time - which didn't meet performance requirements,
    //we would have to implement caching, which is more work that embedding the album art in the app resources, at least for now.
    static var baseImageURL:String = "http://sitedata.thewordunleashed.org/avmedia/series/"
    
    static let COVER_ART_PREAMBLE = "series_"
    static let COVER_ART_POSTAMBLE = "_512w512h"
    
    static let SERIES_SELECTED = "series selected"

    static let SERMON_SELECTED = "sermon selected"

    static let SERIES_PLAYING = "series playing"
    static let SERMON_PLAYING_INDEX = "sermon playing index"
    
    static let SCRIPTURE_URL_PREFIX = "http://www.biblegateway.com/passage/?search="
    static let SCRIPTURE_URL_POSTFIX = "&version=NASB"
    
    static let ID = "id"
    static let NAME = "name"
    static let TITLE = "title"
    static let SCRIPTURE = "scripture"
    static let BOOK = "book"
    static let TEXT = "text"
    static let STARTING_INDEX = "startingIndex"
    static let NUMBER_OF_SERMONS = "numberOfSermons"
    static let SHOW = "show"
    
    static let CURRENT_TIME = "currentTime"
    
    static let SERIES_SETTINGS_KEY = "Series Settings"
    static let SERMON_SETTINGS_KEY = "Sermon Settings"
    
    static let SHOW_ABOUT_SEGUE = "Show About"
    static let SHOW_SERIES_SEGUE = "Show Series"
    static let SHOW_SETTINGS_SEGUE = "Show Settings"
    
    static let DOWNLOADING_TITLE = "Downloading Sermons"
    
    static let DOWNLOAD_IDENTIFIER = "com.leeke.TWU.download."
    
    static let MP3_FILE_EXTENSION = ".mp3"
    static let TMP_FILE_EXTENSION = ".tmp"
    static let JPEG_FILE_EXTENSION = ".jpg"
    
    static let FILENAME_FORMAT = "%04d"+Constants.MP3_FILE_EXTENSION
    
    static let EMPTY_STRING = ""
    static let SINGLE_SPACE_STRING = " "
    static let FORWARD_SLASH = "/"
    
    static let Network_Error = "Network Error"
    static let The_Word_Unleashed = "The Word Unleashed"
    
    static let TWU_EMAIL = "listeners@thewordunleashed.org"
    static let TWU_WEBSITE = "http://www.thewordunleashed.org"
    
    static let All = "All"
    
    static let SORTING = "sorting"
    static let Sort = "Sort"
    static let Sorting_Options_Title = "Sort"
    
    static let Newest_to_Oldest = "Newest to Oldest"
    static let Oldest_to_Newest = "Oldest to Newest"
    static let Title_AZ = "Title A - Z"
    static let Title_ZA = "Title Z - A"
    
    static let Sorting_Options = [Constants.Newest_to_Oldest,Constants.Oldest_to_Newest,Constants.Title_AZ,Constants.Title_ZA]
    
    static let FILTER = "filter"
    static let Filter = "Filter"
    static let Filtering_Options_Title = "Filter by Scripture"

    static let Settings = "Settings"
    static let Settings_Title = "Settings"
    
    static let Play = "Play"
    static let Pause = "Pause"
    
    static let Playing = "Playing"
    static let Paused = "Paused"
    
    static let Okay = "OK"
    static let Cancel = "Cancel"
    
    static let Email_Subject = "Recommendation"
    
    static let Download = "Download"
    static let Downloaded = "Downloaded"
    static let Downloading = "Downloading"
    
    static let Download_All = "Download All"
    static let Cancel_All_Downloads = "Cancel All Downloads"
    static let Delete_All_Downloads = "Delete All Downloads"
    
    static let Selected_Scriptures = "Selected Scriptures"
    static let Open_Scripture = "Open Scripture"
    
    static let Open_Series = "Open Series on TWU Web Site"
    static let Email_Series = "E-Mail Series"
    
    static let Share_on_Facebook = "Share on Facebook"
    static let Share_on_Twitter = "Share on Twitter"

    static let OLD_TESTAMENT:[String] = [
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
    
    static let NEW_TESTAMENT:[String] = [
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

