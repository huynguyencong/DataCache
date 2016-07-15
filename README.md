# Cache
This is a simple disk and memory cache. It can cache basic swift type such as `String`, `Array`, `Dictionary`, `Image`, `NSData`, numbers (`Int`, `Float`, `Double`, ...) ... It also can cache your custom classes, as long as those class inherit `NSObject` and implement `NSCoding`.

### Why use this cache library
There are many reasons why you should use this cache  libary:  

- Easiest, simplest way to cache, store data.
- Fast responding time. Instead of waiting for load data from Internet, now you can load from cache before update from remote resource.
- Load from cache, just update from remote source when cache expired, can save Internet data (especial 3G data) for users, it can help improve battery life.
- It stores data on disk and memory. When you read cache, it try to get data from memory first. That make reading speed is fast. It auto clean mem cache when RAM is full, so it doesn't make your app out of memory.

### Compatible
- iOS 8 or later (if you want to use it on iOS 7, you can add files manually)
- Swift 2.0 or later

### Usage
#### Cocoapod
Add below lines to Podfile:  

```
use_frameworks!

pod DataCache
```

Note: If above pod doesn't work, try using below pod defination in Podfile:  
`pod 'DataCache', :git => 'https://github.com/huynguyencong/DataCache.git'`

#### Manual
Add all file in folder `Sources` to your project. 

#### Simple to use
Use default cache a create new cache if you want. With each cache instance, you can setup cache size and expired time.
##### Cache and Read an object
Cache object such as `String`, `Array`, `Dictionary`, your custom class (inherite `NSObject` and implement `NSCoding`), ...  
NOTE: With `UIImage`, read next section.

```
let myString = "Hello Cache"
DataCache.defaultCache.writeObject(myString, forKey: "myKey")
```

```
DataCache.defaultCache.readObjectForKey("myKey") as? String
```

You can use some utility methods to avoid casting step (`as?` keyword): `readStringForKey(_:)`, `readArrayForKey(_:)`, `readDictionaryForKey(_:)`. With other types, please use `as?` to cast object to your type.

##### Cache and Read an image

```
let image = UIImage(named: "myImageName")
DataCache.defaultCache.writeImage(image!, forKey: "imageKey")
```

```
let image = DataCache.defaultCache.readImageForKey("imageKey")
```

##### Cache and Read a NSData

```
let data = ... // your data  
DataCache.defaultCache.writeData(data, forKey: "myKey")
```

```
let data = DataCache.defaultCache.readDataForKey("myKey")
```

##### Custom a class for cache ability
Inherite `NSObject` and implement `NSCoding` protocol with constructor `init(coder:)` and `encodeWithCoder(_:)` method

```
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
```
##### Create custom Cache instance

Beside using `DataCache.defaultCache`, you can create your cache instances, then you can set different expire time, disk size, disk path. The name parameter specify path name for disk cache.

```
let cache = DataCache(name: "MyCustomCache")
```

### License
This open source use some piece of code from Kingfisher library.

DataCache is released under the MIT license. See LICENSE for details. Copyright © Nguyen Cong Huy