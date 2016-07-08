//
//  Cache.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/4/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

public class DataCache {
    private static let cacheDirectoryPrefix = "com.nch.cache."
    private static let ioQueuePrefix = "com.nch.queue."
    
    public static var defaultCache = DataCache(name: "default")
    
    private var cachePath: String
    
    private let memCache = NSCache()
    private let ioQueue: dispatch_queue_t
    private let fileManager: NSFileManager! = nil
    
    public var name: String = ""
    
    public init(name: String, path: String? = nil) {
        self.name = name
        
        cachePath = path ?? NSSearchPathForDirectoriesInDomains(.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        cachePath = (cachePath as NSString).stringByAppendingPathComponent(DataCache.cacheDirectoryPrefix + name)
        
        ioQueue = dispatch_queue_create(DataCache.ioQueuePrefix + name, DISPATCH_QUEUE_CONCURRENT)
        
        dispatch_async(ioQueue) { 
            self.fileManager = NSFileManager()
        }
        
        #if !os(OSX) && !os(watchOS)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: UIApplicationWillTerminateNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DataCache.backgroundCleanExpiredDiskCache), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        #endif
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Store
    
    public func writeData(data: NSData, forKey rawKey: String) {
        let key = normalizeKeyForRawKey(rawKey)
        
        memCache.setObject(data, forKey: key)
        writeDataToDisk(data, key: key)
    }
    
    private func writeDataToDisk(data: NSData, key: String) {
        dispatch_async(ioQueue) { 
            if self.fileManager.fileExistsAtPath(self.cachePath) == false {
                do {
                    try self.fileManager.createDirectoryAtPath(self.cachePath, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print("Error while creating cache folder")
                }
            }
            
            self.fileManager.createFileAtPath(self.cachePathForKey(key), contents: data, attributes: nil)
        }
    }
    
    // MARK: Read
    
    public func readDataForKey(rawKey:String) -> NSData? {
        let key = normalizeKeyForRawKey(rawKey)
        var data = memCache.objectForKey(key) as? NSData
        
        if data == nil {
            if let dataFromDisk = readDataFromDiskForKey(key) {
                data = dataFromDisk
                memCache.setObject(dataFromDisk, forKey: key)
            }
        }
        
        return data
    }
    
    public func readDataFromDiskForKey(key: String) -> NSData? {
        return self.fileManager.contentsAtPath(cachePathForKey(key))
    }
    
    // MARK: Read & write utils
    
    public func writeString(value: String, forKey key: String) {
        let data = value.dataUsingEncoding(NSUTF8StringEncoding)
        
        if let data = data {
            writeData(data, forKey: key)
        }
    }
    
    public func readStringForKey(key: String) -> String? {
        let data = readDataForKey(key)
        
        if let data = data {
            return String(data: data, encoding: NSUTF8StringEncoding)
        }
        
        return nil
    }
    
    // MARK: Clean
    
    @objc private func cleanExpiredDiskCache() {
        
    }
    
    @objc private func backgroundCleanExpiredDiskCache() {
        
    }
    
    // MARK: Utils
    
    private func cachePathForKey(key: String) -> String {
        return (cachePath as NSString).stringByAppendingPathComponent(key)
    }
    
    private func normalizeKeyForRawKey(rawKey: String) -> String {
        return rawKey.stringByReplacingOccurrencesOfString("/", withString: "--")
    }
}
