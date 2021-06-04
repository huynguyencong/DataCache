# Cache
This is a simple disk and memory cache for iOS written in Swift. It can cache `Codable` types, `NSCoding` types, primitive types (`String`, `Int`, `Array`, etc.).

## Why would I like to use it?
There are some reasons why you would like to use this libary for caching:

- Easiest, simplest way to cache, store data in memory and disk.
- Fast response time. Instead of waiting for data loading from Internet, now you can load it from cache before update it from remote resources.
- Loading data from cache, just update from remote source when the cache expired, will save user's Internet data (especially mobile data) and help to improve battery life.
- It stores data on disk and memory. When you read cache, it will try to get data from memory first. That makes reading speed fast. It cleans memory cache when RAM is full automatically, so it doesn't make your application out of memory.

## Compatibility
- iOS 9 and later (if you want to use it on iOS 7, you can add files manually)
- Swift 5 and later (for earlier Swift version, please use earlier DataCache version)

## Usage
### Installing
#### Cocoapod
Add below lines to your Podfile:  

```ruby
pod 'DataCache'
```

Note: If above pod doesn't work, try using the below pod defination in Podfile:  
`pod 'DataCache', :git => 'https://github.com/huynguyencong/DataCache.git'`

#### Swift Package Manager
In Xcode, select menu File -> Swift Packages -> Add Package Dependency. Select a target, then add this link to the input field:
`https://github.com/huynguyencong/DataCache.git`

#### Manually
Add all files in the `Sources` folder to your project. 

### Simple to use
Use default cache a create new cache if you want. In each cache instance, you can setup cache size and expired time.
#### Read and write an object

Cache `Codable` types, include your custom types that conformed to `Codable` protocol, and primitive types (`String`, `Int`, etc.) which have already conformed to `Codable` by default.

- Write:
```swift
do {
    try DataCache.instance.write(codable: myCodableObject, forKey: "myKey")
} catch {
    print("Write error \(error.localizedDescription)")
}
```

- Read:

```swift
do {
    let object: MyCodableObject? = try DataCache.instance.readCodable(forKey: "myKey")
} catch {
    print("Read error \(error.localizedDescription)")
}
```

#### Read and write `UIImage`

- Write:
```swift
let image = UIImage(named: "myImageName")
DataCache.instance.write(image: image!, forKey: "imageKey")
```

- Read:
```swift
let image = DataCache.instance.readImage(forKey: "imageKey")
```

#### Read and write `Data`

- Write:
```swift
let data = ... // your data  
DataCache.instance.write(data: data, forKey: "myKey")
```

- Read:
```swift
let data = DataCache.instance.readData(forKey: "myKey")
```

#### Clean cache

You can clean by key, or clean all, use one of below methods:
```swift
DataCache.instance.clean(byKey: "myKey")
DataCache.instance.cleanAll()
```
It also clear cache after expiration day. The Default expiration day is 1 week. If you want to customize expiration, please create your customized cache by below instruction. 

#### Custom a class for cache ability
Just make your type conform to Codable.

```swift
struct User: Codable {
    let name: String
    let yearOld: Double
}
```

#### Create custom Cache instance

Beside using default cache `DataCache.instance`, you can create your cache instances, then you can set different expiration time, disk size, disk path. The name parameter specifies path name for disk cache.

```swift
let cache = DataCache(name: "MyCustomCache")
cache.maxDiskCacheSize = 100*1024*1024      // 100 MB
cache.maxCachePeriodInSecond = 7*86400      // 1 week
```

## License
This open source use some piece of code from Kingfisher library.

DataCache is released under the MIT license. See LICENSE for details. Copyright © Nguyen Cong Huy
