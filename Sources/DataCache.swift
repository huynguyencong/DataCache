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
    private static let defaultMaxCachePeriodInSecond: NSTimeInterval = 60 * 60 * 24 * 7         // a week
    
    public static var defaultCache = DataCache(name: "default")
    
    private var cachePath: String
    
    private let memCache = NSCache()
    private let ioQueue: dispatch_queue_t
    private let fileManager: NSFileManager! = nil
    
    /// Name of cache
    public var name: String = ""
    
    /// Life time of disk cache, in second. Default is a week
    public var maxCachePeriodInSecond = DataCache.defaultMaxCachePeriodInSecond
    
    /// Size is allocated for disk cache, in byte. 0 mean no limit. Default is 0
    public var maxDiskCacheSize: UInt = 0
    
    /// Specify distinc name param, it represents folder name for disk cache
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
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        #endif
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Store
    
    public func writeData(data: NSData, forKey rawKey: String) {
        let key = normalizeKeyForRawKey(rawKey)
        
    /// Write data for key
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
    /// Read data for key
        var data = memCache.objectForKey(key) as? NSData
        
        if data == nil {
            if let dataFromDisk = readDataFromDiskForKey(key) {
                data = dataFromDisk
                memCache.setObject(dataFromDisk, forKey: key)
            }
        }
        
        return data
    }
    
    /// Read data from disk for key
    public func readDataFromDiskForKey(key: String) -> NSData? {
        return self.fileManager.contentsAtPath(cachePathForKey(key))
    }
    
    // MARK: Read & write utils
    
    /// Write a string for key
    public func writeString(value: String, forKey key: String) {
        let data = value.dataUsingEncoding(NSUTF8StringEncoding)
        
        if let data = data {
            writeData(data, forKey: key)
        }
    }
    
    /// Read a string for key
    public func readStringForKey(key: String) -> String? {
        let data = readDataForKey(key)
        
        if let data = data {
            return String(data: data, encoding: NSUTF8StringEncoding)
        }
        
        return nil
    }
    
    // MARK: Clean
    
    /// Clean mem cache
    public func cleanMemCache() {
        memCache.removeAllObjects()
    }
    
    /// Clean mem cache and expired disk cache
    public func clean() {
        cleanMemCache()
        cleanExpiredDiskCache()
    }
    
    /**
     Clean expired disk cache. This is an async operation.
     */
    @objc public func cleanExpiredDiskCache() {
        cleanExpiredDiskCacheWithCompletionHander(nil)
    }
    
    // This method is from Kingfisher
    /**
     Clean expired disk cache. This is an async operation.
     
     - parameter completionHandler: Called after the operation completes.
     */
    public func cleanExpiredDiskCacheWithCompletionHander(completionHandler: (()->())?) {
        
        // Do things in cocurrent io queue
        dispatch_async(ioQueue, { () -> Void in
            
            var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles()
            
            for fileURL in URLsToDelete {
                do {
                    try self.fileManager.removeItemAtURL(fileURL)
                } catch _ {
                }
            }
            
            if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                let targetSize = self.maxDiskCacheSize / 2
                
                // Sort files by last modify date. We want to clean from the oldest files.
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1[NSURLContentModificationDateKey] as? NSDate,
                        date2 = resourceValue2[NSURLContentModificationDateKey] as? NSDate {
                        return date1.compare(date2) == .OrderedAscending
                    }
                    // Not valid date information. This should not happen. Just in case.
                    return true
                }
                
                for fileURL in sortedFiles {
                    
                    do {
                        try self.fileManager.removeItemAtURL(fileURL)
                    } catch {
                        
                    }
                    
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?[NSURLTotalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize -= fileSize.unsignedLongValue
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if URLsToDelete.count != 0 {
                    let cleanedHashes = URLsToDelete.map({ (url) -> String in
                        return url.lastPathComponent!
                    })
                }
                
                completionHandler?()
            })
        })
    }
    
    // MARK: Helpers
    
    // This method is from Kingfisher
    
    private func travelCachedFiles() -> (URLsToDelete: [NSURL], diskCacheSize: UInt, cachedFiles: [NSURL: [NSObject: AnyObject]]) {
        
        let diskCacheURL = NSURL(fileURLWithPath: cachePath)
        let resourceKeys = [NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
        let expiredDate = NSDate(timeIntervalSinceNow: -self.maxCachePeriodInSecond)
        
        var cachedFiles = [NSURL: [NSObject: AnyObject]]()
        var URLsToDelete = [NSURL]()
        var diskCacheSize: UInt = 0
        
        if let fileEnumerator = self.fileManager.enumeratorAtURL(diskCacheURL, includingPropertiesForKeys: resourceKeys, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil),
            urls = fileEnumerator.allObjects as? [NSURL] {
            for fileURL in urls {
                
                do {
                    let resourceValues = try fileURL.resourceValuesForKeys(resourceKeys)
                    // If it is a Directory. Continue to next file URL.
                    if let isDirectory = resourceValues[NSURLIsDirectoryKey] as? NSNumber {
                        if isDirectory.boolValue {
                            continue
                        }
                    }
                    
                    // If this file is expired, add it to URLsToDelete
                    if let modificationDate = resourceValues[NSURLContentModificationDateKey] as? NSDate {
                        if modificationDate.laterDate(expiredDate) == expiredDate {
                            URLsToDelete.append(fileURL)
                            continue
                        }
                    }
                    
                    if let fileSize = resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize += fileSize.unsignedLongValue
                        cachedFiles[fileURL] = resourceValues
                    }
                } catch _ {
                }
            }
        }
        
        return (URLsToDelete, diskCacheSize, cachedFiles)
    }
    
    private func cachePathForKey(key: String) -> String {
        let fileName = key.kf_MD5
        return (cachePath as NSString).stringByAppendingPathComponent(fileName)
    }
    
    private func normalizeKeyForRawKey(rawKey: String) -> String {
        return rawKey.stringByReplacingOccurrencesOfString("/", withString: "--")
    }
}

extension Dictionary {
    func keysSortedByValue(isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sort{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}