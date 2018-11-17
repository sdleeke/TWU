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
    
    override var description: String
        {
        get {
            return ""
        }
    }
    
    init(block:(((()->(Bool))?)->())?)
    {
        super.init()
        
        self.block = block
    }
    
    deinit {
        
    }
    
    override func main()
    {
        block?({return self.isCancelled})
    }
}
