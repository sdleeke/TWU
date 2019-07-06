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
    deinit {
        debug(self)
    }
    
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

class ThreadSafe<T>
{
    deinit {
        debug(self)
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
        }()
    
    var _value : T?
    
    var value : T?
    {
        get {
            return queue.sync {
                return _value
            }
        }
        set {
            queue.sync {
                _value = newValue
            }
        }
    }
    
    init(_ value:(()->(T))? = nil)
    {
        self.value = value?()
    }
}

class ThreadSafeArray<T>
{
    deinit {
        debug(self)
    }
    
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

class ThreadSafeDN<T>
{
    deinit {
        debug(self)
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: self?.name ?? UUID().uuidString)
    }()
    
    private var storage = [String:Any]()
    
    //    var levels = 0
    
    var name : String?
    
    init(name:String? = nil) // ,levels:Int
    {
        self.name = name
        //        self.levels = levels
    }
    
    //    var values : [T]?
    //    {
    //        get {
    //            return queue.sync {
    //                if let storage = (storage as? [String:T]) {
    //                    return Array(storage.values)
    //                } else {
    //                    return nil
    //                }
    //            }
    //        }
    //    }
    
    var count : Int
    {
        get {
            return queue.sync { [weak self] in
                return self?.storage.count ?? 0
            }
        }
    }
    
    var copy : [String:Any]?
    {
        get {
            return queue.sync { [weak self] in
                return self?.storage.count > 0 ? self?.storage : nil
            }
        }
    }
    
    func clear()
    {
        queue.sync { [weak self] in
            self?.storage = [String:Any]()
        }
    }
    
    func update(storage:[String:Any]?)
    {
        queue.sync { [weak self] in
            guard let storage = storage else {
                return
            }
            
            self?.storage = storage
        }
    }
    
    func keys(_ keys:String...) -> [String]?
    {
        // keys.count is the number of levels deep in the hierarchy of dictionaries we are to go
        // the array.last is key to the dictionary before last, it returns the last from which
        // keys are produced.
        
        // Doesn't work, will always return nil because self[] always returns T? which in this case is nil.
        //        return (self[keys.joined(separator: ",")] as? [String:Any])?.keys
        
        // This differs from the subscript algorithm in the return before return nil
        return queue.sync { [weak self] in
            guard keys.count > 0 else {
                if let keys = self?.storage.keys {
                    return Array(keys)
                }
                return nil
            }
            
            // start with a copy of storage
            var dict:[String:Any]? = self?.storage
            
            for index in keys.indices {
                // go through all of the levels but the last
                guard index < keys.indices.last else {
                    break
                }
                // keep going deeper into the nested dictionaries
                dict = dict?[keys[index]] as? [String:Any]
            }
            
            if let index = keys.indices.last, let keys = (dict?[keys[index]] as? [String:Any])?.keys {
                // we've reached the last index, the value of which in the current dictionary (one before last)
                // is the last dictionary (of N hierarchical levels deep) from which we return the keys.
                return Array(keys)
            } else {
                return nil
            }
        }
    }
    
    func values(_ keys:String...) -> [T]?
    {
        // keys.count is the number of levels deep in the hierarchy of dictionaries we are to go
        // the array.last is key to the dictionary before last, it returns the last from which
        // keys are produced.
        
        // Doesn't work, will always return nil because self[] always returns T? which in this case is nil.
        //        return (self[keys.joined(separator: ",")] as? [String:Any])?.keys
        
        // This differs from the subscript algorithm in the return before return nil
        return queue.sync { [weak self] in
            guard keys.count > 0 else {
                return Array(storage.values) as? [T]
            }
            
            // start with a copy of storage
            var dict:[String:Any]? = storage
            
            for index in keys.indices {
                // go through all of the levels but the last
                guard index < keys.indices.last else {
                    break
                }
                // keep going deeper into the nested dictionaries
                dict = dict?[keys[index]] as? [String:Any]
            }
            
            if let index = keys.indices.last, let values = (dict?[keys[index]] as? [String:T])?.values {
                // we've reached the last index, the value of which in the current dictionary (one before last)
                // is the last dictionary (of N hierarchical levels deep) from which we return the keys.
                return Array(values)
            } else {
                return nil
            }
        }
    }
    
    subscript(keys:String...) -> T?
    {
        get {
            guard keys.count > 0 else {
                return nil
            }
            
            guard keys.count > 1 else {
                return queue.sync { [weak self] in
                    return self?.storage[keys[0]] as? T
                }
            }
            
            // keys.count is the number of levels deep in the hierarchy of dictionaries we are to go
            // the array.last is key to the last dictionary, it returns the value which is cast to T and returned
            
            // This differs from the keys algorithm in the return before return nil
            return queue.sync { [weak self] in
                // start with a copy of storage
                var dict:[String:Any]? = self?.storage
                
                for index in keys.indices {
                    // go through all of the levels but the last
                    guard index < keys.indices.last else {
                        break
                    }
                    
                    // keep going deeper into the nested dictionaries
                    dict = dict?[keys[index]] as? [String:Any]
                }
                
                if let index = keys.indices.last {
                    // we've reached the last index, the value of which in the current dictionary (the last)
                    // is the value we return as? T
                    return dict?[keys[index]] as? T
                } else {
                    return nil
                }
            }
        }
        set {
            guard keys.count > 0 else {
                return
            }
            
            guard keys.count > 1 else {
                queue.sync { [weak self] in
                    self?.storage[keys[0]] = newValue
                }
                return
            }
            
            //            print(keys)
            queue.sync { [weak self] in
                // start with a copy of storage
                var dict:[String:Any]? = storage
                
                // keey an array of all the dictionaries we traverse
                // since everytime we touch a new level we make a copy
                // since dictionaries are value, not reference, objects
                // in order to copy them back after we finally set the value
                var dicts = [[String:Any]]()
                
                // Go through the levels
                for index in 0..<keys.count {
                    // Except the last since that's the dictionary in which we have to set the value
                    guard index < (keys.count - 1) else {
                        break
                    }
                    
                    guard dict != nil else {
                        // If this ever happens something is very wrong.
                        break
                    }
                    
                    // keep a copy of each dict we touch
                    dicts.append(dict!)
                    
                    // If this level's value is nil, set a blank dictionary in its place
                    // as we'll need that in the next level, i.e. be self-assembling
                    if dict?[keys[index]] == nil {
                        dict?[keys[index]] = [String:Any]()
                    }
                    
                    // keep going deeper into the nested dictionaries
                    dict = dict?[keys[index]] as? [String:Any]
                }
                
                // Don't append the last dict since we have it in hand (i.e. the var dict)
                //                dicts.append(dict!)
                
                // Set the new value at the deepest level, which is assumed to be the leaf level
                // i.e. no dictionaries as values at this level
                if let index = keys.indices.last {
                    //                    print(keys[index])
                    dict?[keys[index]] = newValue
                }
                
                // Now we have to reconstruct the hierarchy
                // Start with the deepest level
                var newDict:[String:Any]? = dict
                
                // got through the other levels in the hierarchy
                for index in 0..<(keys.count - 1) {
                    // In reverse order, of course
                    let maxIndex = keys.count - 2 // since keys.count - 1 is one more than we'll ever go.
                    let index = maxIndex - index
                    
                    dicts[index][keys[index]] = newDict
                    
                    // Move to the next level higher up
                    newDict = dicts[index]
                }
                
                // Reset storage to the modified dict hierarchy
                //                print(newDict!)
                
                guard newDict != nil else {
                    return
                }
                
                self?.storage = newDict!
            }
        }
    }
}

//class ThreadSafeDictionary<T>
//{
//    deinit {
//
//    }
//
//    private var storage = [String:T]()
//
//    var count : Int
//    {
//        get {
//            return queue.sync {
//                return storage.count
//            }
//        }
//    }
//
//    var copy : [String:T]?
//    {
//        get {
//            return queue.sync {
//                return storage.count > 0 ? storage : nil
//            }
//        }
//    }
//
//    var isEmpty : Bool
//    {
//        return queue.sync {
//            return storage.isEmpty
//        }
//    }
//
//    var values : [T]
//    {
//        get {
//            return queue.sync {
//                return Array(storage.values)
//            }
//        }
//    }
//
//    var keys : [String]
//    {
//        get {
//            return queue.sync {
//                return Array(storage.keys)
//            }
//        }
//    }
//
//    func clear()
//    {
//        queue.sync {
//            self.storage = [String:T]()
//        }
//    }
//
//    func update(storage:Any?)
//    {
//        queue.sync {
//            guard let storage = storage as? [String:T] else {
//                return
//            }
//
//            self.storage = storage
//        }
//    }
//
//    // Make it thread safe
//    lazy var queue : DispatchQueue = { [weak self] in
//        return DispatchQueue(label: name ?? UUID().uuidString)
//    }()
//
//    var name : String?
//
//    init(name:String? = nil)
//    {
//        self.name = name
//    }
//
//    subscript(key:String?) -> T? {
//        get {
//            return queue.sync {
//                guard let key = key else {
//                    return nil
//                }
//
//                return storage[key]
//            }
//        }
//        set {
//            queue.sync {
//                guard let key = key else {
//                    return
//                }
//
//                storage[key] = newValue
//            }
//        }
//    }
//}

//class ThreadSafeDictionaryOfDictionaries<T>
//{
//    private var storage = [String:[String:T]]()
//    
//    var count : Int
//    {
//        get {
//            return queue.sync {
//                return storage.count
//            }
//        }
//    }
//    
//    var copy : [String:[String:T]]?
//    {
//        get {
//            return queue.sync {
//                return storage.count > 0 ? storage : nil
//            }
//        }
//    }
//    
//    var isEmpty : Bool
//    {
//        return queue.sync {
//            return storage.isEmpty
//        }
//    }
//    
//    var values : [[String:T]]
//    {
//        get {
//            return queue.sync {
//                return Array(storage.values)
//            }
//        }
//    }
//    
//    var keys : [String]
//    {
//        get {
//            return queue.sync {
//                return Array(storage.keys)
//            }
//        }
//    }
//    
//    func clear()
//    {
//        queue.sync {
//            self.storage = [String:[String:T]]()
//        }
//    }
//    
//    func update(storage:Any?)
//    {
//        queue.sync {
//            guard let storage = storage as? [String:[String:T]] else {
//                return
//            }
//            
//            self.storage = storage
//        }
//    }
//    
//    // Make it thread safe
//    lazy var queue : DispatchQueue = { [weak self] in
//        return DispatchQueue(label: name ?? UUID().uuidString)
//    }()
//    
//    var name : String?
//    
//    init(name:String? = nil)
//    {
//        self.name = name
//    }
//    
//    subscript(outer:String?) -> [String:T]? {
//        get {
//            return queue.sync {
//                guard let outer = outer else {
//                    return nil
//                }
//                
//                return storage[outer]
//            }
//        }
//        set {
//            queue.sync {
//                guard let outer = outer else {
//                    return
//                }
//                
//                storage[outer] = newValue
//            }
//        }
//    }
//    
//    subscript(outer:String?,inner:String?) -> T? {
//        get {
//            return queue.sync {
//                guard let outer = outer else {
//                    return nil
//                }
//                
//                guard let inner = inner else {
//                    return nil
//                }
//                
//                return storage[outer]?[inner]
//            }
//        }
//        set {
//            queue.sync {
//                guard let outer = outer else {
//                    return
//                }
//                
//                guard let inner = inner else {
//                    return
//                }
//                
//                if storage[outer] == nil {
//                    storage[outer] = [String:T]()
//                }
//                
//                storage[outer]?[inner] = newValue
//            }
//        }
//    }
//}

class Fetch<T>
{
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Fetch" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1 // The sync queue controls
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    init(name:String?, useCache:Bool = true, fetch:(()->(T?))? = nil)
    {
        self.name = name
        self.fetch = fetch
        self.useCache = useCache
    }
    
    var useCache = true
    
    var fetch : (()->(T?))?
    
    var store : ((T?)->())?
    var retrieve : (()->(T?))?
    
    var name : String?
    
    private var cache : T?
    {
        didSet {
            
        }
    }

    func clear()
    {
        queue.sync {
            cache = nil
        }
    }
    
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
//    func load()
//    {
//        queue.sync {
//            guard cache == nil else {
//                return
//            }
//
//            cache = retrieve?()
//
//            guard cache == nil else {
//                return
//            }
//
//            self.cache = self.fetch?()
//
//            store?(self.cache)
//        }
//    }
    
//    func fill()
//    {
//        operationQueue.addOperation {
//            _ = self.result
//        }
//    }
    
    var result:T?
    {
        get {
            return queue.sync {
                if useCache, cache != nil {
                    return cache
                }
                
                var result = retrieve?()
                
                guard result == nil else {
                    if useCache {
                        cache = result
                    }
                    return result
                }
                
                result = self.fetch?()
                
                operationQueue.addOperation {
                    self.store?(result)
                }
                
                if useCache {
                    cache = result
                }
                
                return result
            }
        }
    }
}

protocol Size
{
    var _fileSize : Int? { get set }
    var fileSize : Int? { get }
}

class FetchCodable<T:Codable> : Fetch<T>, Size
{
    deinit {
        debug(self)
    }
    
    var fileSystemURL : URL?
    {
        get {
            return name?.fileSystemURL
        }
    }
    
    // Replacing these two w/ a Shadow class is a big performance hit
    internal var _fileSize : Int?
    var fileSize : Int?
    {
        get {
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize
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
    override init(name: String?, useCache:Bool = true, fetch: (() -> (T?))? = nil)
    {
        super.init(name:name, useCache:useCache, fetch:fetch)
        
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
