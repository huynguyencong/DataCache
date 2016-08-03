//
//  Cache.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/4/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

public enum ImageFormat {
    case Unknown, PNG, JPEG
}

public class DataCache {
    static let cacheDirectoryPrefix = "com.nch.cache."
    static let ioQueuePrefix = "com.nch.queue."
    static let defaultMaxCachePeriodInSecond: NSTimeInterval = 60 * 60 * 24 * 7         // a week
    
    public static var defaultCache = DataCache(name: "default")
    
    var cachePath: String
    
    let memCache = NSCache()
    let ioQueue: dispatch_queue_t
    let fileManager: NSFileManager
    
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
        
        self.fileManager = NSFileManager()
        
        #if !os(OSX) && !os(watchOS)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: UIApplicationWillTerminateNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        #endif
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

    // MARK: Store

extension DataCache {
    
    /// Write data for key. This is an async operation.
    public func writeData(data: NSData, forKey key: String) {
        memCache.setObject(data, forKey: key)
        writeDataToDisk(data, key: key)
    }
    
    func writeDataToDisk(data: NSData, key: String) {
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
    
    /// Read data for key
    public func readDataForKey(key:String) -> NSData? {
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
    
    
    /// Write an object for key. This object must inherit from `NSObject` and implement `NSCoding` protocol. `String`, `Array`, `Dictionary` conform to this method.
    ///
    /// NOTE: Can't write `UIImage` with this method. Please use `writeImage(_:forKey:)` to write an image
    public func writeObject(value: NSCoding, forKey key: String) {
        let data = NSKeyedArchiver.archivedDataWithRootObject(value)
        writeData(data, forKey: key)
    }
    
    /// Read an object for key. This object must inherit from `NSObject` and implement NSCoding protocol. `String`, `Array`, `Dictionary` conform to this method
    public func readObjectForKey(key: String) -> NSObject? {
        let data = readDataForKey(key)
        
        if let data = data {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSObject
        }
        
        return nil
    }
    
    /// Read a string for key
    public func readStringForKey(key: String) -> String? {
        return readObjectForKey(key) as? String
    }
    
    /// Read an array for key
    public func readArrayForKey(key: String) -> Array<AnyObject>? {
        return readObjectForKey(key) as? Array<AnyObject>
    }
    
    /// Read a dictionary for key
    public func readDictionaryForKey(key: String) -> Dictionary<String, AnyObject>? {
        return readObjectForKey(key) as? Dictionary<String, AnyObject>
    }
    
    // MARK: Read & write image
    
    /// Write image for key. Please use this method to write an image instead of `writeObject(_:forKey:)`
    public func writeImage(image: UIImage, forKey key: String, format: ImageFormat? = nil) {
        var data: NSData? = nil
        
        if let format = format where format == .PNG {
            data = UIImagePNGRepresentation(image)
        }
        else {
            data = UIImageJPEGRepresentation(image, 0.9)
        }
        
        if let data = data {
            writeData(data, forKey: key)
        }
    }
    
    /// Read image for key. Please use this method to write an image instead of `readObjectForKey(_:)`
    public func readImageForKey(key: String) -> UIImage? {
        let data = readDataForKey(key)
        if let data = data {
            return UIImage(data: data, scale: 1.0)
        }
        
        return nil
    }
}

// MARK: Utils

extension DataCache {
    
    /// Check if has data on disk
    public func hasDataOnDiskForKey(key: String) -> Bool {
        return self.fileManager.fileExistsAtPath(self.cachePathForKey(key))
    }
    
    /// Check if has data on mem
    public func hasDataOnMemForKey(key: String) -> Bool {
        return (memCache.objectForKey(key) != nil)
    }
}

// MARK: Clean

extension DataCache {
    
    /// Clean all mem cache and disk cache. This is an async operation.
    public func cleanAll() {
        cleanMemCache()
        cleanDiskCache()
    }
    
    /// Clean cache by key. This is an async operation.
    public func cleanByKey(key: String) {
        memCache.removeObjectForKey(key)
        
        dispatch_async(ioQueue) { 
            do {
                try self.fileManager.removeItemAtPath(self.cachePathForKey(key))
            } catch {}
        }
    }
    
    func cleanMemCache() {
        memCache.removeAllObjects()
    }
    
    func cleanDiskCache() {
        dispatch_async(ioQueue) {
            do {
                try self.fileManager.removeItemAtPath(self.cachePath)
            } catch {}
        }
    }
    
    /// Clean expired disk cache. This is an async operation.
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
                } catch {}
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
                    } catch {}
                    
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
                completionHandler?()
            })
        })
    }
}

// MARK: Helpers

extension DataCache {
    
    // This method is from Kingfisher
    func travelCachedFiles() -> (URLsToDelete: [NSURL], diskCacheSize: UInt, cachedFiles: [NSURL: [NSObject: AnyObject]]) {
        
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
    
    func cachePathForKey(key: String) -> String {
        let fileName = key.kf_MD5
        return (cachePath as NSString).stringByAppendingPathComponent(fileName)
    }
}