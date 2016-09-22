//
//  CacheDemoTests.swift
//  CacheDemoTests
//
//  Created by Nguyen Cong Huy on 7/12/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import XCTest
@testable import DataCache

class CacheDemoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReadWriteCache() {
        let str = "testReadWriteCache"
        let key = "testReadWriteCacheKey"
        
        DataCache.defaultCache.writeObject(str, forKey: key)
        let cachedString = DataCache.defaultCache.readStringForKey(key)
        
        XCTAssert(cachedString == str)
    }
    
    func testWriteCacheToDisk() {
        let str = "testWriteCacheToDisk"
        let key = "testWriteCacheToDiskKey"
        
        let expectation = self.expectation(description: "Write to disk is an asynchonous operation")
        
        DataCache.defaultCache.writeObject(str, forKey: key)
        DataCache.defaultCache.cleanMemCache()
        
        // wait for write to disk successful
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
            let cachedString = DataCache.defaultCache.readStringForKey(key)
            XCTAssert(cachedString == str)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { (error) in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testReadWriteImage() {
        let image = UIImage(named: "dog.jpg")
        let key = "testReadWriteImageKey"
        
        DataCache.defaultCache.writeImage(image!, forKey: key)
        let cachedImage = DataCache.defaultCache.readImageForKey(key)
        
        if let image = image, let cachedImage = cachedImage {
            XCTAssert(image.size == cachedImage.size)
        }
        else {
            XCTFail()
        }
    }
    
    func testHasDataOnDiskForKey() {
        let str = "testHasDataOnDiskForKey"
        let key = "testHasDataOnDiskForKeyKey"
        let expectation = self.expectation(description: "Write to disk is an asynchonous operation")
        
        DataCache.defaultCache.writeObject(str, forKey: key)
        
        // wait for write to disk successful
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
            let hasDataOnDisk = DataCache.defaultCache.hasDataOnDiskForKey(key)
            XCTAssert(hasDataOnDisk == true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { (error) in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testHasDataOnMemForKey() {
        let str = "testHasDataOnMemForKey"
        let key = "testHasDataOnMemForKeyKey"
        
        DataCache.defaultCache.writeObject(str, forKey: key)
        let hasDataOnMem = DataCache.defaultCache.hasDataOnMemForKey(key)
        
        XCTAssert(hasDataOnMem == true)
    }
    
    func testCleanCache() {
        let str = "testCleanCache"
        let key = "testCleanCacheKey"
        let expectation = self.expectation(description: "Clean is an asynchonous operation")
        
        DataCache.defaultCache.writeObject(str, forKey: key)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
            DataCache.defaultCache.cleanAll()
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                let cachedString = DataCache.defaultCache.readStringForKey(key)
                XCTAssert(cachedString == nil)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3) { (error) in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}
