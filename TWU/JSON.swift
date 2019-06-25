//
//  JSON.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class JSON
{
//    func get(from filename:String?) -> Any?
//    {
//        guard let filename = filename else {
//            return nil
//        }
//
//        guard let fileSystemURL = filename.fileSystemURL else {
//            return nil
//        }
//
//        do {
//            let data = try Data(contentsOf: fileSystemURL)
//            print("able to read json from the URL.")
//
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                return json
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                return nil
//            }
//        } catch let error as NSError {
//            print("Network unavailable: json could not be read from the file system.")
//            NSLog(error.localizedDescription)
//            return nil
//        }
//    }
    
    deinit {
        operationQueue.cancelAllOperations()
        debug(self)
    }
    
    var format:String?
    {
        get {
            let defaults = UserDefaults.standard
            
            return defaults.string(forKey: Constants.FORMAT)
        }
        
        set {
            let defaults = UserDefaults.standard
            if (newValue != nil) {
                defaults.set(newValue,forKey: Constants.FORMAT)
            } else {
                defaults.removeObject(forKey: Constants.FORMAT)
            }
            defaults.synchronize()
        }
    }
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "JSON"
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    func get(from urlString:String?,filename:String?) -> Any?
    {
        // DO NOT DO THIS AS IT STOPS LOADING FROM STORAGE AS WELL!
//        guard Globals.shared.reachability.isReachable else {
//            return nil
//        }
        
//        guard let urlString = urlString else {
//            return nil
//        }
//
//        guard let url = URL(string: urlString) else {
//            return filename?.fileSystemURL?.data?.json
//        }
        
//        guard let json = filename?.fileSystemURL?.data?.json else {
//            // BLOCKS
//            let data = urlString?.url?.data
//
//            operationQueue.addOperation {
//                _ = data?.save(to: filename?.fileSystemURL)
//                self.format = Constants.JSON.SERIES_JSON
//            }
//
//            return data?.json
//        }
//
//        operationQueue.addOperation {
//            _ = urlString?.url?.data?.save(to: filename?.fileSystemURL)
//        }
//
//        return json
        
        guard Globals.shared.reachability.isReachable else {
            return filename?.fileSystemURL?.data?.json
        }
        
        guard let data = urlString?.url?.data else {
            return filename?.fileSystemURL?.data?.json
        }
        
        operationQueue.addOperation {
            _ = data.save(to: filename?.fileSystemURL)
        }
        
        return data.json
        
//        func urlData() -> Any?
//        {
//            let data = urlString?.url?.data
//
//            guard let json = data?.json else {
//                return nil
//            }
//
//            operationQueue.addOperation {
//                _ = data?.save(to: filename?.fileSystemURL)
//                self.format = Constants.JSON.SERIES_JSON
//            }
//
//            return json
//        }
//
//        guard format == Constants.JSON.SERIES_JSON else {
//            return urlData()
//        }
//
//        guard let json = filename?.fileSystemURL?.data?.json else {
//            return urlData()
//        }
//
//        operationQueue.addOperation {
//            _ = urlData()
//        }
//
//        return json
    }

    func load() -> [String:Any]?
    {
        return get(from: Constants.JSON.SERIES_JSON,filename: Constants.JSON.SERIES_JSON.url?.lastPathComponent) as? [String:Any]
        
//        guard let json = get(from: Constants.JSON.SERIES_JSON,filename: Constants.JSON.SERIES_JSON.url?.lastPathComponent) as? [String:Any] else {
//            print("could not get json from file, make sure that file contains valid json.")
//            return nil
//        }
        
//        if let meta = json[Constants.JSON.KEYS.META] as? [String:Any] {
//            Globals.shared.series.meta.update(contents:meta)
//        }
//
//        return json[Constants.JSON.KEYS.DATA] as? [[String:Any]]
        
//        var seriesDicts = [[String:Any]]()
//
//        let key = Constants.JSON.KEYS.DATA
//
////        switch Constants.JSON.URL {
////        case Constants.JSON.URLS.MEDIALIST_PHP:
////            key = Constants.JSON.KEYS.SERIES
////            break
////
////        default:
////            key = Constants.JSON.KEYS.DATA
////            break
////        }
//
//        if let series = json[key] as? [[String:Any]] {
//            for i in 0..<series.count {
//                var dict = [String:Any]()
//
//                for (key,value) in series[i] {
//                    dict[key] = value
//                }
//
//                seriesDicts.append(dict)
//            }
//        }
//
//        return seriesDicts.count > 0 ? seriesDicts : nil
    }
}
