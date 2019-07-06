//
//  Meta.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

struct Meta
{
    // From NEW JSON
    private var storage = ThreadSafeDN<Any>(name: "META") // [String:Any]? // ictionary
    
    func update(contents:[String:Any]?)
    {
        self.storage.update(storage:contents)
    }
    
    var audioURL : String?
    {
        return storage["audio"] as? String
        
//        switch Constants.JSON.URL {
//        case Constants.JSON.URLS.MEDIALIST_PHP:
//            return Constants.URL.BASE.PHP_AUDIO
//            
//        default:
//            return storage["audio"] as? String
//        }
    }
    
    var imageURL : String?
    {
        return storage["image"] as? String
    }
    
    var squareSuffix : String?
    {
        return (storage["imageSuffix"] as? [String:String])?["1x1"]
    }
    
    var imageTransformDir : [String:String]?
    {
        return storage["imageTransformDir"] as? [String:String]
    }
    
    var wideSuffix : String?
    {
        return (storage["imageSuffix"] as? [String:String])?["16x9"]
    }
}

