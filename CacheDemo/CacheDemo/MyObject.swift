//
//  MyObject.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/11/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

public class MyObject: NSObject, NSCoding {
    public var name = ""
    public var yearOld = 0
    
    override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObjectForKey("name") as! String
        self.yearOld = aDecoder.decodeIntegerForKey("yearOld")
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name, forKey: "name")
        aCoder.encodeInteger(self.yearOld, forKey: "yearOld")
    }
}