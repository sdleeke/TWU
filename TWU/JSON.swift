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
    func get(from filename:String?) -> Any?
    {
        guard let filename = filename else {
            return nil
        }
        
        guard let fileSystemURL = filename.fileSystemURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileSystemURL)
            print("able to read json from the URL.")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                return nil
            }
        } catch let error as NSError {
            print("Network unavailable: json could not be read from the file system.")
            NSLog(error.localizedDescription)
            return nil
        }
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
        guard let urlString = urlString else {
            return nil
        }
        
        guard Globals.shared.reachability.isReachable, let url = URL(string: urlString) else {
            print("json not reachable.")
            return get(from: filename)
        }
        
        if format == Constants.JSON.SERIES_JSON, let json = get(from: filename) {
            operationQueue.addOperation {
                do {
                    let data = try Data(contentsOf: url)
                    print("able to read json from the URL.")
                    
                    do {
                        if let fileSystemURL = filename?.fileSystemURL { // fileSystemURL(filename)
                            try data.write(to: fileSystemURL)
                        }
                        self.format = Constants.JSON.SERIES_JSON
                        print("able to write json to the file system")
                    } catch let error as NSError {
                        print("unable to write json to the file system.")
                        NSLog(error.localizedDescription)
                    }
                } catch let error {
                    NSLog(error.localizedDescription)
                }
            }
            
            return json
        } else {
            do {
                let data = try Data(contentsOf: url)
                print("able to read json from the URL.")
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    do {
                        if let jsonFileSystemURL = filename?.fileSystemURL {
                            try data.write(to: jsonFileSystemURL)
                        }
                        format = Constants.JSON.SERIES_JSON
                        print("able to write json to the file system")
                    } catch let error as NSError {
                        print("unable to write json to the file system.")
                        
                        NSLog(error.localizedDescription)
                    }
                    
                    return json
                } catch let error as NSError {
                    NSLog(error.localizedDescription)
                    return get(from: filename)
                }
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                return get(from: filename)
            }
        }
    }

    func load() -> [[String:Any]]?
    {
        guard let json = get(from: Constants.JSON.SERIES_JSON,filename: Constants.JSON.SERIES_JSON.url?.lastPathComponent) as? [String:Any] else {
            print("could not get json from file, make sure that file contains valid json.")
            return nil
        }
        
        if let meta = json[Constants.JSON.KEYS.META] as? [String:Any] {
            Globals.shared.series.meta.update(contents:meta)
        }
        
        var seriesDicts = [[String:Any]]()
        
        let key = Constants.JSON.KEYS.DATA
        
//        switch Constants.JSON.URL {
//        case Constants.JSON.URLS.MEDIALIST_PHP:
//            key = Constants.JSON.KEYS.SERIES
//            break
//            
//        default:
//            key = Constants.JSON.KEYS.DATA
//            break
//        }
        
        if let series = json[key] as? [[String:Any]] {
            for i in 0..<series.count {
                var dict = [String:Any]()
                
                for (key,value) in series[i] {
                    dict[key] = value
                }
                
                seriesDicts.append(dict)
            }
        }
        
        return seriesDicts.count > 0 ? seriesDicts : nil
    }
}
