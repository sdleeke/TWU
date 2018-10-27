//
//  extensions.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

extension Double
{
    var secondsToHMS : String?
    {
        get {
            let hours = max(Int(self / (60*60)),0)
            let mins = max(Int((self - (Double(hours) * 60*60)) / 60),0)
            let sec = max(Int(self.truncatingRemainder(dividingBy: 60)),0)
            
            var string:String
            
            if (hours > 0) {
                string = "\(String(format: "%d",hours)):"
            } else {
                string = Constants.EMPTY_STRING
            }
            
            string += "\(String(format: "%02d",mins)):\(String(format: "%02d",sec))"
            
            return string
        }
    }
}

extension String
{
    var withoutPrefixes : String
    {
        get {
            var sortString = self
            
            let quote:String = "\""
            let prefixes = ["A ","An ","And ","The "]
            
            if self.endIndex >= quote.endIndex, String(self[..<quote.endIndex]) == quote {
                sortString = String(self[quote.endIndex...])
            }
            
            for prefix in prefixes {
                if self.endIndex >= prefix.endIndex, String(self[..<prefix.endIndex]) == prefix {
                    sortString = String(self[prefix.endIndex...])
                    break
                }
            }
            
            return sortString
        }
    }
    
    var hmsToSeconds : Double?
    {
        get {
            guard self.range(of: ":") != nil else {
                return nil
            }
            
            var str = self.replacingOccurrences(of: ",", with: ".")
            
            var numbers = [Double]()
            
            repeat {
                if let index = str.range(of: ":") {
                    let numberString = String(str[..<index.lowerBound])
                    
                    if let number = Double(numberString) {
                        numbers.append(number)
                    }
                    
                    str = String(str[index.upperBound...])
                }
            } while str.range(of: ":") != nil
            
            if !str.isEmpty {
                if let number = Double(str) {
                    numbers.append(number)
                }
            }
            
            var seconds = 0.0
            var counter = 0.0
            
            for number in numbers.reversed() {
                seconds = seconds + (counter != 0 ? number * pow(60.0,counter) : number)
                counter += 1
            }
            
            return seconds
        }
    }
    
    var secondsToHMS : String?
    {
        get {
            guard let timeNow = Double(self) else {
                return nil
            }
            
            let hours = max(Int(timeNow / (60*60)),0)
            let mins = max(Int((timeNow - (Double(hours) * 60*60)) / 60),0)
            let sec = max(Int(timeNow.truncatingRemainder(dividingBy: 60)),0)
            let fraction = timeNow - Double(Int(timeNow))
            
            var hms:String
            
            if (hours > 0) {
                hms = "\(String(format: "%02d",hours)):"
            } else {
                hms = "00:" //Constants.EMPTY_STRING
            }
            
            // \(String(format: "%.3f",fraction)
            // .trimmingCharacters(in: CharacterSet(charactersIn: "0."))
            
            hms = hms + "\(String(format: "%02d",mins)):\(String(format: "%02d",sec)).\(String(format: "%03d",Int(fraction * 1000)))"
            
            return hms
        }
    }
}

extension UIApplication
{
    func isRunningInFullScreen() -> Bool
    {
        if let w = self.keyWindow
        {
            let maxScreenSize = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            let minScreenSize = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            
            let maxAppSize = max(w.bounds.size.width, w.bounds.size.height)
            let minAppSize = min(w.bounds.size.width, w.bounds.size.height)
            
            return (maxScreenSize == maxAppSize) && (minScreenSize == minAppSize)
        }
        
        return true
    }
}

extension UIImage
{
    func resize(scale:CGFloat) -> UIImage?
    {
        let toScaleSize = CGSize(width: scale * self.size.width, height: scale * self.size.height)
        
        UIGraphicsBeginImageContextWithOptions(toScaleSize, true, self.scale)
        
        self.draw(in: CGRect(x: 0, y: 0, width: scale * self.size.width, height: scale * self.size.height))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}

extension UIBarButtonItem
{
    func setTitleTextAttributes(_ attributes:[NSAttributedStringKey:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UISegmentedControl
{
    func setTitleTextAttributes(_ attributes:[String:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UIButton
{
    func setTitle(_ string:String? = nil)
    {
        setTitle(string, for: UIControlState.normal)
        setTitle(string, for: UIControlState.disabled)
        setTitle(string, for: UIControlState.selected)
    }
}

extension Thread
{
    static func onMainThread(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.async {
                block?()
            }
        }
    }

    static func onMainThreadSync(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.sync {
                block?()
            }
        }
    }
}

extension UIViewController
{
    func setDVCLeftBarButton()
    {
        // MUST be called from the detail view ONLY
        if let isCollapsed = splitViewController?.isCollapsed {
            if isCollapsed {
                navigationController?.topViewController?.navigationItem.leftBarButtonItem = self.navigationController?.navigationItem.backBarButtonItem
            } else {
                navigationController?.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            }
        }
    }
}

extension NSLayoutConstraint {
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}

extension String
{
    var url : URL?
    {
        get {
            return URL(string: self)
        }
    }

    var fileSystemURL : URL?
    {
        return url?.fileSystemURL
    }
}

fileprivate var queue = DispatchQueue(label: UUID().uuidString)

extension URL
{
    var fileSystemURL : URL?
    {
        return cachesURL()?.appendingPathComponent(self.lastPathComponent)
    }

    var downloaded : Bool
    {
        get {
            if let fileSystemURL = fileSystemURL {
                return FileManager.default.fileExists(atPath: fileSystemURL.path)
            } else {
                return false
            }
        }
    }

    var data : Data?
    {
        get {
            return try? Data(contentsOf: self)
        }
    }
    
    @available(iOS 11.0, *)
    var pdf : PDFDocument?
    {
        get {
            guard let data = data else {
                return nil
            }
            
            return PDFDocument(data: data)
        }
    }
    
    func delete()
    {
        guard let fileSystemURL = fileSystemURL else {
            return
        }
        
        // Check if file exists and if so, delete it.
        if (FileManager.default.fileExists(atPath: fileSystemURL.path)){
            do {
                try FileManager.default.removeItem(at: fileSystemURL)
            } catch let error as NSError {
                print("failed to delete download: \(error.localizedDescription)")
            }
        }
    }
    
    func image(block:((UIImage)->()))
    {
        if let image = image {
            block(image)
        }
    }
    
    var image : UIImage?
    {
        get {
            guard let imageURL = fileSystemURL else {
                return nil
            }
            
            if imageURL.downloaded, let image = UIImage(contentsOfFile: imageURL.path) {
                return image
            } else {
                guard let data = data else {
                    return nil
                }
                
                guard let image = UIImage(data: data) else {
                    return nil
                }
                
                DispatchQueue.global(qos: .background).async {
                    queue.sync {
                        guard !imageURL.downloaded else {
                            return
                        }
                        
                        do {
                            try UIImageJPEGRepresentation(image, 1.0)?.write(to: imageURL, options: [.atomic])
                            print("Image \(self.lastPathComponent) saved to file system")
                        } catch let error as NSError {
                            NSLog(error.localizedDescription)
                            print("Image \(self.lastPathComponent) not saved to file system")
                        }
                    }
                }

                return image
            }
        }
    }
}

extension Data
{
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf16.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    var html2String: String? {
        return html2AttributedString?.string
    }
}

extension String
{
    var html2AttributedString: NSAttributedString? {
        return self.data(using: String.Encoding.utf16)?.html2AttributedString
    }
    var html2String: String? {
        return html2AttributedString?.string
    }
}

extension Date
{
    //MARK: Date extension
    
    // VERY Computationally Expensive
    init?(dateString:String)
    {
        let dateStringFormatter = DateFormatter()
        
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let d = dateStringFormatter.date(from: dateString) else {
            return nil
        }
        
        self = Date(timeInterval:0, since:d)
    }
    
    // VERY Computationally Expensive
    init?(string:String)
    {
        let dateStringFormatter = DateFormatter()

        dateStringFormatter.dateFormat = "MMM dd, yyyy"

        var text = string
        
        if let range = string.range(of: " AM"), string.endIndex == range.upperBound {
            text = String(string[..<range.lowerBound])
        }
        
        if let range = string.range(of: " PM"), string.endIndex == range.upperBound {
            text = String(string[..<range.lowerBound])
        }

        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard var d = dateStringFormatter.date(from: text) else {
            return nil
        }

        if let range = string.range(of: " PM"), string.endIndex == range.upperBound {
            d += 12*60*60
        }

        self = Date(timeInterval:0, since:d)
    }
    
    // VERY Computationally Expensive
    var ymd : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy-MM-dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var mdyhm : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            dateStringFormatter.amSymbol = "AM"
            dateStringFormatter.pmSymbol = "PM"
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var mdy : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var year : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var month : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var day : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    func isNewerThan(_ dateToCompare : Date) -> Bool
    {
        return (self.compare(dateToCompare) == ComparisonResult.orderedDescending) && (self.compare(dateToCompare) != ComparisonResult.orderedSame)
    }
    
    
    func isOlderThan(_ dateToCompare : Date) -> Bool
    {
        return (self.compare(dateToCompare) == ComparisonResult.orderedAscending) && (self.compare(dateToCompare) != ComparisonResult.orderedSame)
    }
    
    
    func isEqualTo(_ dateToCompare : Date) -> Bool
    {
        return self.compare(dateToCompare) == ComparisonResult.orderedSame
    }
    
    func addDays(_ daysToAdd : Int) -> Date
    {
        let secondsInDays : TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(_ hoursToAdd : Int) -> Date
    {
        let secondsInHours : TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}

public extension UIDevice
{
    var isSimulator : Bool
    {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "i386":
            fallthrough
        case "x86_64":
            return true
            
        default:
            return false
        }
    }
    
    var deviceName : String
    {
        get {
            return UIDevice.current.name
            
//            if UIDevice.current.isSimulator {
//                return "\(UIDevice.current.name):\(UIDevice.current.modelName)"
//            } else {
//                return UIDevice.current.name
//            }
        }
    }
    
//    var modelName: String
//    {
//        var systemInfo = utsname()
//        uname(&systemInfo)
//        let machineMirror = Mirror(reflecting: systemInfo.machine)
//        var identifier = machineMirror.children.reduce("") { identifier, element in
//            guard let value = element.value as? Int8, value != 0 else { return identifier }
//            return identifier + String(UnicodeScalar(UInt8(value)))
//        }
//
//        switch identifier {
//        case "i386":
//            fallthrough
//        case "x86_64":
//            if let id = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
//                identifier = id
//            }
//
//        default:
//            break
//        }
//
//        var modelName: String
//
//        switch identifier {
//        case "iPhone1,1": modelName = "iPhone"
//        case "iPhone1,2": modelName = "iPhone 3G"
//
//        case "iPhone2,1": modelName = "iPhone 3GS"
//
//        case "iPhone3,1": modelName = "iPhone 4 (GSM)"
//        case "iPhone3,2": modelName = "iPhone 4 (GSM Rev A)"
//        case "iPhone3,3": modelName = "iPhone 4 (CDMA)"
//
//        case "iPhone4,1": modelName = "iPhone 4S"
//
//        case "iPhone5,1": modelName = "iPhone 5 (GSM)"
//        case "iPhone5,2": modelName = "iPhone 5 (CDMA)"
//
//        case "iPhone5,3": modelName = "iPhone 5c (GSM)"
//        case "iPhone5,4": modelName = "iPhone 5c (CDMA)"
//
//        case "iPhone6,1": modelName = "iPhone 5s (GSM)"
//        case "iPhone6,2": modelName = "iPhone 5s (CDMA)"
//
//        case "iPhone7,1": modelName = "iPhone 6 Plus"
//        case "iPhone7,2": modelName = "iPhone 6"
//
//        case "iPhone8,1": modelName = "iPhone 6s"
//        case "iPhone8,2": modelName = "iPhone 6s Plus"
//
//        case "iPhone8,4": modelName = "iPhone SE"
//
//        case "iPhone9,1": modelName = "iPhone 7 (CDMA+GSM)"
//        case "iPhone9,2": modelName = "iPhone 7 Plus (CDMA+GSM)"
//        case "iPhone9,3": modelName = "iPhone 7 (GSM)"
//        case "iPhone9,4": modelName = "iPhone 7 Plus (GSM)"
//
//        case "iPod1,1": modelName = "iPod Touch 1st Generation"
//        case "iPod2,1": modelName = "iPod Touch 2nd Generation"
//        case "iPod3,1": modelName = "iPod Touch 3rd Generation"
//        case "iPod4,1": modelName = "iPod Touch 4th Generation"
//        case "iPod5,1": modelName = "iPod Touch 5th Generation"
//
//        case "iPod7,1": modelName = "iPod Touch 6th Generation"
//
//        case "iPad1,1": modelName = "iPad"
//
//        case "iPad2,1": modelName = "iPad 2 (WiFi)"
//        case "iPad2,2": modelName = "iPad 2 (WiFi+GSM)"
//        case "iPad2,3": modelName = "iPad 2 (WiFi+CDMA)"
//        case "iPad2,4": modelName = "iPad 2 (WiFi, revised)"
//
//        case "iPad2,5": modelName = "iPad Mini (WiFi)"
//        case "iPad2,6": modelName = "iPad Mini (WiFi+GSM)"
//        case "iPad2,7": modelName = "iPad Mini (WiFi+GSM+CDMA)"
//
//        case "iPad3,1": modelName = "iPad 3rd Generation (WiFi)"
//        case "iPad3,2": modelName = "iPad 3rd Generation (WiFi+GSM+CDMA)"
//        case "iPad3,3": modelName = "iPad 3rd Generation (WiFi+GSM)"
//
//        case "iPad3,4": modelName = "iPad 4th Generation (WiFi)"
//        case "iPad3,5": modelName = "iPad 4th Generation (WiFi+GSM)"
//        case "iPad3,6": modelName = "iPad 4th Generation (WiFi+GSM+CDMA)"
//
//        case "iPad4,1": modelName = "iPad Air (WiFi)"
//        case "iPad4,2": modelName = "iPad Air (WiFi+Cellular)"
//        case "iPad4,3": modelName = "iPad Air (revised)"
//
//        case "iPad4,4": modelName = "iPad mini 2 (WiFi)"
//        case "iPad4,5": modelName = "iPad mini 2 (WiFi+Cellular)"
//        case "iPad4,6": modelName = "iPad mini 2 (revised)"
//
//        case "iPad4,7": modelName = "iPad mini 3 (WiFi)"
//        case "iPad4,8": modelName = "iPad mini 3 (WiFi+Cellular)"
//        case "iPad4,9": modelName = "iPad mini 3 (China Model)"
//
//        case "iPad5,1": modelName = "iPad mini 4 (WiFi)"
//        case "iPad5,2": modelName = "iPad mini 4 (WiFi+Cellular)"
//
//        case "iPad5,3": modelName = "iPad Air 2 (WiFi)"
//        case "iPad5,4": modelName = "iPad Air 2 (WiFi+Cellular)"
//
//        case "iPad6,3": modelName = "iPad Pro (9.7 inch) (WiFi)"
//        case "iPad6,4": modelName = "iPad Pro (9.7 inch) (WiFi+Cellular)"
//
//        case "iPad6,7": modelName = "iPad Pro (12.9 inch) (WiFi)"
//        case "iPad6,8": modelName = "iPad Pro (12.9 inch) (WiFi+Cellular)"
//
//        case "iPad7,3": modelName = "iPad Pro (10.5 inch) (WiFi)"
//        case "iPad7,4": modelName = "iPad Pro (10.5 inch) (WiFi+Cellular)"
//
//        default: modelName = "Unknown"
//        }
//
//        return modelName
//    }
}


