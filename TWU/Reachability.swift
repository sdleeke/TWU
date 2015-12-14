//
//  Reachability.swift
//  TPS
//
//  Created by Steve Leeke on 9/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation

public class Reachability {
    
    class func isConnectedToNetwork()->Bool
    {
        
        var status:Bool = false
        let url = NSURL(string: Constants.REACHABILITY_TEST_URL)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        var response: NSURLResponse?
        
        _ = (try? NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)) as NSData?
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                status = true
            }
        }
        
        return status
    }
}