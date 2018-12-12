//
//  generics.swift
//
//  Created by Steve Leeke on 9/22/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}

func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

class BoundsCheckedArray<T>
{
    private var storage = [T]()
    
    func sorted(_ sort:((T,T)->Bool)) -> [T]
    {
        guard let getIt = getIt else {
            return storage.sorted(by: sort)
        }
        
        let sorted = getIt().sorted(by: sort)
        //        print(sorted)
        return sorted
    }
    
    func filter(_ fctn:((T)->Bool)) -> [T]
    {
        guard let getIt = getIt else {
            return storage.filter(fctn)
        }
        
        let filtered = getIt().filter(fctn)
        //        print(filtered)
        return filtered
    }
    
    var count : Int
    {
        guard let getIt = getIt else {
            return storage.count
        }
        
        return getIt().count
    }
    
    func clear()
    {
        storage = [T]()
    }
    
    var getIt:(()->([T]))?
    
    init(getIt:(()->([T]))?)
    {
        self.getIt = getIt
    }
    
    subscript(key:Int) -> T? {
        get {
            if let array = getIt?() {
                if key >= 0,key < array.count {
                    return array[key]
                }
            } else {
                if key >= 0,key < storage.count {
                    return storage[key]
                }
            }
            
            return nil
        }
        set {
            guard getIt == nil else {
                return
            }
            
            guard let newValue = newValue else {
                if key >= 0,key < storage.count {
                    storage.remove(at: key)
                }
                return
            }
            
            if key >= 0,key < storage.count {
                storage[key] = newValue
            }
            
            if key == storage.count {
                storage.append(newValue)
            }
        }
    }
}

class ThreadSafeArray<T>
{
    private var storage = [T]()
    
    func sorted(sort:((T,T)->Bool)) -> [T]
    {
        return storage.sorted(by: sort)
    }
    
    var copy : [T]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }
    
    var count : Int
    {
        get {
            return storage.count
        }
    }
    
    var isEmpty : Bool
    {
        return storage.isEmpty
    }
    
    func clear()
    {
        queue.sync {
            self.storage = [T]()
        }
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [T] else {
                return
            }
            
            self.storage = storage
        }
    }

    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    subscript(key:Int) -> T? {
        get {
            return queue.sync {
                if key >= 0,key < storage.count {
                    return storage[key]
                }
                
                return nil
            }
        }
        set {
            queue.sync {
                guard let newValue = newValue else {
                    if key >= 0,key < storage.count {
                        storage.remove(at: key)
                    }
                    return
                }
                
                if key >= 0,key < storage.count {
                    storage[key] = newValue
                }
                
                if key == storage.count {
                    storage.append(newValue)
                }
            }
        }
    }
}

class ThreadSafeDictionary<T>
{
    private var storage = [String:T]()
    
    var count : Int
    {
        get {
            return queue.sync {
                return storage.count
            }
        }
    }
    
    var copy : [String:T]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }

    var isEmpty : Bool
    {
        return queue.sync {
            return storage.isEmpty
        }
    }
    
    var values : [T]
    {
        get {
            return queue.sync {
                return Array(storage.values)
            }
        }
    }
    
    var keys : [String]
    {
        get {
            return queue.sync {
                return Array(storage.keys)
            }
        }
    }
    
    func clear()
    {
        queue.sync {
            self.storage = [String:T]()
        }
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [String:T] else {
                return
            }
            
            self.storage = storage
        }
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    subscript(key:String?) -> T? {
        get {
            return queue.sync {
                guard let key = key else {
                    return nil
                }
                
                return storage[key]
            }
        }
        set {
            queue.sync {
                guard let key = key else {
                    return
                }
                
                storage[key] = newValue
            }
        }
    }
}

class ThreadSafeDictionaryOfDictionaries<T>
{
    private var storage = [String:[String:T]]()
    
    var count : Int
    {
        get {
            return queue.sync {
                return storage.count
            }
        }
    }
    
    var copy : [String:[String:T]]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }
    
    var isEmpty : Bool
    {
        return queue.sync {
            return storage.isEmpty
        }
    }
    
    var values : [[String:T]]
    {
        get {
            return queue.sync {
                return Array(storage.values)
            }
        }
    }
    
    var keys : [String]
    {
        get {
            return queue.sync {
                return Array(storage.keys)
            }
        }
    }
    
    func clear()
    {
        queue.sync {
            self.storage = [String:[String:T]]()
        }
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [String:[String:T]] else {
                return
            }
            
            self.storage = storage
        }
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    subscript(outer:String?) -> [String:T]? {
        get {
            return queue.sync {
                guard let outer = outer else {
                    return nil
                }
                
                return storage[outer]
            }
        }
        set {
            queue.sync {
                guard let outer = outer else {
                    return
                }
                
                storage[outer] = newValue
            }
        }
    }
    
    subscript(outer:String?,inner:String?) -> T? {
        get {
            return queue.sync {
                guard let outer = outer else {
                    return nil
                }
                
                guard let inner = inner else {
                    return nil
                }
                
                return storage[outer]?[inner]
            }
        }
        set {
            queue.sync {
                guard let outer = outer else {
                    return
                }
                
                guard let inner = inner else {
                    return
                }
                
                if storage[outer] == nil {
                    storage[outer] = [String:T]()
                }
                
                storage[outer]?[inner] = newValue
            }
        }
    }
}

class Fetch<T>
{
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Fetch" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    init(name:String?,fetch:(()->(T?))? = nil)
    {
        self.name = name
        self.fetch = fetch
    }
    
    var fetch : (()->(T?))?
    
    var store : ((T?)->())?
    var retrieve : (()->(T?))?
    
    var name : String?
    
    var cache : T?

    func clear()
    {
        queue.sync {
            cache = nil
        }
    }
    
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    func load()
    {
        queue.sync {
            guard cache == nil else {
                return
            }

            cache = retrieve?()
            
            guard cache == nil else {
                return
            }
            
            self.cache = self.fetch?()
            
            store?(self.cache)
        }
    }
    
    func fill()
    {
        operationQueue.addOperation {
            self.load()
        }
    }
    
    var result:T?
    {
        get {
            load()
            
            return cache
        }
    }
}

class FetchCodable<T:Codable> : Fetch<T>
{
    var fileSystemURL : URL?
    {
        get {
            return name?.fileSystemURL
        }
    }
    
    private var _fileSize : Int?
    
    var fileSize : Int
    {
        get {
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize ?? 0
            }
            
            return fileSize
        }
    }
    
    func delete()
    {
        _fileSize = nil
        fileSystemURL?.delete()
    }
    
    // name MUST be unique to ever INSTANCE, not just the class!
    override init(name: String?, fetch: (() -> (T?))? = nil)
    {
        super.init(name: name, fetch: fetch)
        
        store = { (t:T?) in
            guard let t = t else {
                return
            }
            
            guard let fileSystemURL = self.fileSystemURL else {
                return
            }
            
            let dict = ["value":t]
            
            do {
                let data = try JSONEncoder().encode(dict)
                print("able to encode T: \(fileSystemURL.lastPathComponent)")
                
                do {
                    try data.write(to: fileSystemURL)
                    print("able to write T to the file system: \(fileSystemURL.lastPathComponent)")
                } catch let error {
                    print("unable to write T to the file system: \(fileSystemURL.lastPathComponent)")
                    NSLog(error.localizedDescription)
                }
            } catch let error {
                print("unable to encode T: \(fileSystemURL.lastPathComponent)")
                NSLog(error.localizedDescription)
            }
        }
        
        retrieve = {
            guard let fileSystemURL = self.fileSystemURL else {
                return nil
            }
            
            do {
                let data = try Data(contentsOf: fileSystemURL)
                print("able to read T from storage: \(fileSystemURL.lastPathComponent)")
                
                do {
                    let dict = try JSONDecoder().decode([String:T].self, from: data)
                    print("able to decode T from storage: \(fileSystemURL.lastPathComponent)")
                    return dict["value"]
                } catch let error {
                    print("unable to decode T from storage: \(fileSystemURL.lastPathComponent)")
                    NSLog(error.localizedDescription)
                }
            } catch let error {
                print("unable to read T from storage: \(fileSystemURL.lastPathComponent)")
                NSLog(error.localizedDescription)
            }
            
            return nil
        }
    }
}
