//
//  Cache.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/4/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

public enum ImageFormat {
    case unknown, png, jpeg
}

open class DataCache {
    static let cacheDirectoryPrefix = "com.nch.cache."
    static let ioQueuePrefix = "com.nch.queue."
    static let defaultMaxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7         // a week
    
    open static var instance = DataCache(name: "default")
    
    var cachePath: String
    
    let memCache = NSCache<AnyObject, AnyObject>()
    let ioQueue: DispatchQueue
    let fileManager: FileManager
    
    /// Name of cache
    open var name: String = ""
    
    /// Life time of disk cache, in second. Default is a week
    open var maxCachePeriodInSecond = DataCache.defaultMaxCachePeriodInSecond
    
    /// Size is allocated for disk cache, in byte. 0 mean no limit. Default is 0
    open var maxDiskCacheSize: UInt = 0
    
    /// Specify distinc name param, it represents folder name for disk cache
    public init(name: String, path: String? = nil) {
        self.name = name
        
        cachePath = path ?? NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        cachePath = (cachePath as NSString).appendingPathComponent(DataCache.cacheDirectoryPrefix + name)
        
        ioQueue = DispatchQueue(label: DataCache.ioQueuePrefix + name)
        
        self.fileManager = FileManager()
        
        #if !os(OSX) && !os(watchOS)
            NotificationCenter.default.addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Store data

extension DataCache {
    
    /// Write data for key. This is an async operation.
    public func write(data: Data, forKey key: String) {
        memCache.setObject(data as AnyObject, forKey: key as AnyObject)
        writeDataToDisk(data: data, key: key)
    }
    
    func writeDataToDisk(data: Data, key: String) {
        ioQueue.async {
            if self.fileManager.fileExists(atPath: self.cachePath) == false {
                do {
                    try self.fileManager.createDirectory(atPath: self.cachePath, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print("Error while creating cache folder")
                }
            }
            
            self.fileManager.createFile(atPath: self.cachePath(forKey: key), contents: data, attributes: nil)
        }
    }
    
    /// Read data for key
    public func readData(forKey key:String) -> Data? {
        var data = memCache.object(forKey: key as AnyObject) as? Data
        
        if data == nil {
            if let dataFromDisk = readDataFromDisk(forKey: key) {
                data = dataFromDisk
                memCache.setObject(dataFromDisk as AnyObject, forKey: key as AnyObject)
            }
        }
        
        return data
    }
    
    /// Read data from disk for key
    public func readDataFromDisk(forKey key: String) -> Data? {
        return self.fileManager.contents(atPath: cachePath(forKey: key))
    }
    
    
    // MARK: Read & write utils
    
    
    /// Write an object for key. This object must inherit from `NSObject` and implement `NSCoding` protocol. `String`, `Array`, `Dictionary` conform to this method.
    ///
    /// NOTE: Can't write `UIImage` with this method. Please use `writeImage(_:forKey:)` to write an image
    public func write(object: NSCoding, forKey key: String) {
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        write(data: data, forKey: key)
    }
    
    /// Read an object for key. This object must inherit from `NSObject` and implement NSCoding protocol. `String`, `Array`, `Dictionary` conform to this method
    public func readObject(forKey key: String) -> NSObject? {
        let data = readData(forKey: key)
        
        if let data = data {
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? NSObject
        }
        
        return nil
    }
    
    /// Read a string for key
    public func readString(forKey key: String) -> String? {
        return readObject(forKey: key) as? String
    }
    
    /// Read an array for key
    public func readArray(forKey key: String) -> Array<Any>? {
        return readObject(forKey: key) as? Array<Any>
    }
    
    /// Read a dictionary for key
    public func readDictionary(forKey key: String) -> Dictionary<String, Any>? {
        return readObject(forKey: key) as? Dictionary<String, Any>
    }
    
    // MARK: Read & write image
    
    /// Write image for key. Please use this method to write an image instead of `writeObject(_:forKey:)`
    public func write(image: UIImage, forKey key: String, format: ImageFormat? = nil) {
        var data: Data? = nil
        
        if let format = format, format == .png {
            data = UIImagePNGRepresentation(image)
        }
        else {
            data = UIImageJPEGRepresentation(image, 0.9)
        }
        
        if let data = data {
            write(data: data, forKey: key)
        }
    }
    
    /// Read image for key. Please use this method to write an image instead of `readObjectForKey(_:)`
    public func readImageForKey(key: String) -> UIImage? {
        let data = readData(forKey: key)
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
        return self.fileManager.fileExists(atPath: self.cachePath(forKey: key))
    }
    
    /// Check if has data on mem
    public func hasDataOnMemForKey(key: String) -> Bool {
        return (memCache.object(forKey: key as AnyObject) != nil)
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
    public func clean(byKey key: String) {
        memCache.removeObject(forKey: key as AnyObject)
        
        ioQueue.async {
            do {
                try self.fileManager.removeItem(atPath: self.cachePath(forKey: key))
            } catch {}
        }
    }
    
    public func cleanMemCache() {
        memCache.removeAllObjects()
    }
    
    public func cleanDiskCache() {
        ioQueue.async {
            do {
                try self.fileManager.removeItem(atPath: self.cachePath)
            } catch {}
        }
    }
    
    /// Clean expired disk cache. This is an async operation.
    @objc public func cleanExpiredDiskCache() {
        cleanExpiredDiskCacheWithCompletionHander(completionHandler: nil)
    }
    
    // This method is from Kingfisher
    /**
     Clean expired disk cache. This is an async operation.
     
     - parameter completionHandler: Called after the operation completes.
     */
    public func cleanExpiredDiskCacheWithCompletionHander(completionHandler: (()->())?) {
        
        // Do things in cocurrent io queue
        ioQueue.async(execute: { () -> Void in
            
            var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles()
            
            for fileURL in URLsToDelete {
                do {
                    try self.fileManager.removeItem(at: fileURL)
                } catch {}
            }
            
            if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                let targetSize = self.maxDiskCacheSize / 2
                
                // Sort files by last modify date. We want to clean from the oldest files.
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1[URLResourceKey.contentModificationDateKey] as? Date,
                        let date2 = resourceValue2[URLResourceKey.contentModificationDateKey] as? Date {
                        return date1.compare(date2) == .orderedAscending
                    }
                    // Not valid date information. This should not happen. Just in case.
                    return true
                }
                
                for fileURL in sortedFiles {
                    
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                    } catch {}
                    
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize -= fileSize.uintValue
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                }
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler?()
            })
        })
    }
}

// MARK: Helpers

extension DataCache {
    
    // This method is from Kingfisher
    fileprivate func travelCachedFiles() -> (URLsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: [URLResourceKey: Any]]) {
        
        let diskCacheURL = URL(fileURLWithPath: cachePath)
        let resourceKeys = [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey, URLResourceKey.totalFileAllocatedSizeKey]
        let expiredDate = Date(timeIntervalSinceNow: -self.maxCachePeriodInSecond)
        
        var cachedFiles = [URL: [URLResourceKey: Any]]()
        var URLsToDelete = [URL]()
        var diskCacheSize: UInt = 0
        
        if let fileEnumerator = self.fileManager.enumerator(at: diskCacheURL, includingPropertiesForKeys: resourceKeys, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, errorHandler: nil),
            let urls = fileEnumerator.allObjects as? [URL] {
            for fileURL in urls {
                
                do {
                    let bookmarkData = try fileURL.bookmarkData()
                    let resourceValues = try URL.resourceValues(forKeys: Set(resourceKeys), fromBookmarkData: bookmarkData)?.allValues
                    // If it is a Directory. Continue to next file URL.
                    if let isDirectory = resourceValues?[URLResourceKey.isDirectoryKey] as? NSNumber {
                        if isDirectory.boolValue {
                            continue
                        }
                    }
                    
                    // If this file is expired, add it to URLsToDelete
                    if let modificationDate = resourceValues?[URLResourceKey.contentModificationDateKey] as? NSDate {
                        if modificationDate.laterDate(expiredDate) == expiredDate {
                            URLsToDelete.append(fileURL)
                            continue
                        }
                    }
                    
                    if let fileSize = resourceValues?[URLResourceKey.totalFileSizeKey] as? NSNumber {
                        diskCacheSize += fileSize.uintValue
                        cachedFiles[fileURL] = resourceValues
                    }
                } catch _ {
                }
            }
        }
        
        return (URLsToDelete, diskCacheSize, cachedFiles)
    }
    
    func cachePath(forKey key: String) -> String {
        let fileName = key.md5
        return (cachePath as NSString).appendingPathComponent(fileName)
    }
}
