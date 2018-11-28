//
//  Settings.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Settings
{
    var series = ThreadSafeDictionaryOfDictionaries<String>(name: "SeriesSettings") // [String:[String:String]]?
    var sermon = ThreadSafeDictionaryOfDictionaries<String>(name: "SermonSettings") // [String:[String:String]]?
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Settings"
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    func saveBackground()
    {
        print("saveSermonSettingsBackground")
        
        operationQueue.addOperation {
            self.save()
        }
    }
    
    func save()
    {
        print("saveSermonSettings")
        let defaults = UserDefaults.standard
        defaults.set(series.copy,forKey: Constants.SETTINGS.KEY.SERIES)
        defaults.set(sermon.copy,forKey: Constants.SETTINGS.KEY.SERMON)
        defaults.synchronize()
    }
    
    func load()
    {
        let defaults = UserDefaults.standard
        
        if let settingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.SERIES) {
            series.update(storage: settingsDictionary)
        }
        
        if let settingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.SERMON) {
            sermon.update(storage: settingsDictionary)
        }
        
        if let sorting = defaults.string(forKey: Constants.SORTING) {
            Globals.shared.series.sorting = sorting
        }
        
        if let filter = defaults.string(forKey: Constants.FILTER) {
            if (filter == Constants.All) {
                Globals.shared.series.filter = nil
                Globals.shared.series.showing = .all
            } else {
                Globals.shared.series.filter = filter
                Globals.shared.series.showing = .filtered
            }
        }
        
        if let seriesPlaying = defaults.string(forKey: Constants.SETTINGS.PLAYING.SERIES) {
            if let index = Globals.shared.series.all?.index(where: { (series) -> Bool in
                return series.name == seriesPlaying
            }) {
                let seriesPlaying = Globals.shared.series.all?[index]
                
                if let sermonPlaying = defaults.string(forKey: Constants.SETTINGS.PLAYING.SERMON) {
                    Globals.shared.mediaPlayer.playing = seriesPlaying?.sermons?.filter({ (sermon) -> Bool in
                        return sermon.id == sermonPlaying
                    }).first
                }
            } else {
                defaults.removeObject(forKey: Constants.SETTINGS.PLAYING.SERIES)
            }
        }
    }
    
    var autoAdvance:Bool
    {
        get {
            return UserDefaults.standard.bool(forKey: Constants.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
}

