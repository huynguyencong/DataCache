//
//  MyObject.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/11/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

open class MyObject: NSObject, NSCoding {
    open var name = ""
    open var yearOld = 0
    
    override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.yearOld = aDecoder.decodeInteger(forKey: "yearOld")
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.yearOld, forKey: "yearOld")
    }
}
