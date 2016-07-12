//
//  Dictionary+Cache.swift
//  Pods
//
//  Created by Nguyen Cong Huy on 7/12/16.
//
//

import Foundation

extension Dictionary {
    func keysSortedByValue(isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sort{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}