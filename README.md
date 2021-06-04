# Cache
This is a simple disk and memory cache. It can cache basic swift types and `Codable` types, such as `String`, `Array`, `Dictionary`, `UIImage`, `Data`, numbers (`Int`, `Float`, `Double`, etc.). It can also cache classes that conform to `NSCoding`.

### Why use this cache library
There are many reasons why you should use this cache libary:  

- Easiest, simplest way to cache, store data in memory and disk.
- Fast responding time. Instead of waiting for load data from Internet, now you can load from cache before update from remote resources.
- Loaded from cache, just update from remote source when cache expired, can save Internet data (especially mobile data) for users, it can help to improve battery life.
- It stores data on disk and memory. When you read cache, it will try to get data from memory first. That makes reading speed fast. It cleans mem cache when RAM is full automatically, so it doesn't make your app out of memory.

### Compatibility
- iOS 9 and later (if you want to use it on iOS 7, you can add files manually)
- Swift 5 and later (for earlier Swift version, please use earlier DataCache version)

### Usage
#### Cocoapod
Add below lines to your Podfile:  

```ruby
use_frameworks!

pod 'DataCache'
```

Note: If above pod doesn't work, try using the below pod defination in Podfile:  
`pod 'DataCache', :git => 'https://github.com/huynguyencong/DataCache.git'`

#### Swift Package Manager
In Xcode, select menu File -> Swift Packages -> Add Package Dependency. Select a target, then add this link to the input field:
`https://github.com/huynguyencong/DataCache.git`

#### Manual
Add all files in the `Sources` folder to your project. 

#### Simple to use
Use default cache a create new cache if you want. In each cache instance, you can setup cache size and expired time.
##### Read and write an object

Cache object such as `String`, `Array`, `Dictionary`, your custom class (conform to `Codable` or `NSCoding`), etc.

NOTE: With `UIImage`, please read next section.

- Write:
```swift
do {
    try DataCache.instance.write(codable: myCodableObject, forKey: "myKey")
} catch {
    print("Write error \(error.localizedDescription)")
}
```

or use a utility methods for  `String`, `Array` or `Dictionary`:
```
DataCache.instance.write(string: myString, forKey: "myKey")
```

- Read:

```
do {
    let object: MyCodableObject? = try DataCache.instance.readCodable(forKey: "myKey")
} catch {
    print("Read error \(error.localizedDescription)")
}
```

You can use utility methods for `String`, `Array` or `Dictionary`:
```swift
DataCache.instance.write(string: myString, forKey: "myKey")
```

##### Read and write an image

```swift
let image = UIImage(named: "myImageName")
DataCache.instance.write(image: image!, forKey: "imageKey")
```

```swift
let image = DataCache.instance.readImage(forKey: "imageKey")
```

##### Read and write Data

```swift
let data = ... // your data  
DataCache.instance.write(data: data, forKey: "myKey")
```

```swift
let data = DataCache.instance.readData(forKey: "myKey")
```

##### Clean cache

You can clean by key, or clean all, use one of below methods:
```swift
DataCache.instance.clean(byKey: "myKey")
DataCache.instance.cleanAll()
```
It also clear cache after expiration day. The Default expiration day is 1 week. If you want to customize expiration, please create your customized cache by below instruction. 

##### Custom a class for cache ability
Just make your type conform to Codable.

```swift
struct User: Codable {
    let name: String
    let yearOld: Double
}
```

##### Create custom Cache instance

Beside using default cache `DataCache.instance`, you can create your cache instances, then you can set different expiration time, disk size, disk path. The name parameter specifies path name for disk cache.

```swift
let cache = DataCache(name: "MyCustomCache")
```

### License
This open source use some piece of code from Kingfisher library.

DataCache is released under the MIT license. See LICENSE for details. Copyright © Nguyen Cong Huy
