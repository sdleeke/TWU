//
//  CancellableOperation.swift
//  CBC
//
//  Created by Steve Leeke on 10/10/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class CancellableOperation : Operation
{
    var block : (((()->(Bool))?)->())?
    
    var tag : String?
    
    override var description: String
        {
        get {
            return ""
        }
    }
    
    init(tag:String? = nil, block:(((()->(Bool))?)->())?)
    {
        super.init()
        
        self.tag = tag
        self.block = block
    }
    
    deinit {
        debug(self)
    }
    
    override func main()
    {
        block?({return self.isCancelled})
    }
}
