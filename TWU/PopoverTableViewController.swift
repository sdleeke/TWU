//
//  PopoverTableViewController.swift
//  TPS
//
//  Created by Steve Leeke on 8/19/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

enum PopoverPurpose {
    case selectingShow
    
    case selectingSorting
    case selectingFiltering
    
    case selectingAction
}

protocol PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index:Int, strings:[String], purpose:PopoverPurpose, sermon:Sermon?)
}

struct Section {
    var titles:[String]?
    var counts:[Int]?
    var indexes:[Int]?
}

class PopoverTableViewController: UITableViewController {
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var selectedSermon:Sermon?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var showIndex:Bool = false
    var indexByLastName:Bool = false
    var showSectionHeaders:Bool = false
    
    var strings:[String]?
    
    lazy var section:Section! = {
        var section = Section()
        return section
    }()
    
    func setPreferredContentSize()
    {
        guard (strings != nil) else {
            return
        }
        
        self.tableView.sizeToFit()
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0
        
        //        print(strings)
        
        for string in strings! {
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 44.0)
            let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
            
            let heightSize: CGSize = CGSize(width: view.bounds.width - 30, height: .greatestFiniteMagnitude)
            let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
            
            //            print(string)
            //            print(maxSize)
            
            if maxWidth.width > width {
                //                print(string)
                width = maxWidth.width
            }
            
            height += 44
            
            //            print(maxHeight.height, (Int(maxHeight.height) / 16) - 1)
            height += CGFloat(((Int(maxHeight.height) / 16) - 1) * 16)
        }
        
        width += 2*20
        
        switch purpose! {
        case .selectingFiltering:
            fallthrough
        case .selectingSorting:
            width += 44
            break
            
        default:
            break
        }
        
        if showIndex {
            width += 24
        }
        
        self.preferredContentSize = CGSize(width: width, height: height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard (strings != nil) else {
            return
        }
        
        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
//        var max = 0
//        
//        if (navigationItem.title != nil) {
//            max = navigationItem.title!.characters.count
//        }
//        
//        for string in strings! {
//            if string.characters.contains("\n") {
//                var newString = string
//                
//                var strings = [String]()
//                
//                repeat {
//                    strings.append(newString.substring(to: newString.range(of: "\n")!.lowerBound))
//                    newString = newString.substring(from: newString.range(of: "\n")!.upperBound)
//                } while newString.characters.contains("\n")
//                
//                strings.append(newString)
//                
//                for string in strings {
//                    if string.characters.count > max {
//                        max = string.characters.count
//                    }
//                }
//            } else {
//                if string.characters.count > max {
//                    max = string.characters.count
//                }
//            }
//        }
//        
//        //        print("count: \(CGFloat(strings!.count)) rowHeight: \(tableView.rowHeight) height: \(height)")
//        
//        var width = CGFloat(max * 12)
//        if width < 200 {
//            width = 200
//        }
//        var height = 50 * CGFloat(strings!.count) //35 tableView.rowHeight was -1 which I don't understand
//        if height < 150 {
//            height = 150
//        }
//        
//        if showSectionHeaders {
//            height = 1.5*height
//        }
//
//        self.preferredContentSize = CGSize(width: width, height: height)
        
//        print("Strings: \(strings)")
//        print("Sections: \(sections)")
//        print("Section Indexes: \(sectionIndexes)")
//        print("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func setupIndex()
    {
        if (showIndex) {
            let a = "A"
            
            section.titles = Array(Set(strings!.map({ (string:String) -> String in
                if indexByLastName {
                    return lastNameFromName(string)!.substring(to: a.endIndex)
                } else {
                    return stringWithoutPrefixes(string)!.substring(to: a.endIndex)
                }
            }))).sorted() { $0 < $1 }
            
            var indexes = [Int]()
            var counts = [Int]()
            
            for sectionTitle in section.titles! {
                var counter = 0
                
                for index in 0..<strings!.count {
                    var string:String?
                    
                    if indexByLastName {
                        string = lastNameFromName(strings?[index])!.substring(to: a.endIndex)
                    } else {
                        string = stringWithoutPrefixes(strings?[index])!.substring(to: a.endIndex)
                    }
                    
                    if (sectionTitle == string) {
                        if (counter == 0) {
                            indexes.append(index)
                        }
                        counter += 1
                    }
                }
                
                counts.append(counter)
            }
            
            section.indexes = indexes.count > 0 ? indexes : nil
            section.counts = counts.count > 0 ? counts : nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        setupIndex()
        
        tableView.reloadData()
        
        setPreferredContentSize()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if (showIndex) {
            return self.section.titles != nil ? self.section.titles!.count : 0
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if (showIndex) {
            return self.section.counts != nil ? self.section.counts![section] : 0
        } else {
            return strings != nil ? strings!.count : 0
        }
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if (showIndex) {
            return self.section.titles
        } else {
            return nil
        }
    }
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 48
//    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if (showIndex) {
            return index
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (showIndex && showSectionHeaders) {
            return self.section.titles != nil ? self.section.titles![section] : nil
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath)

        var index = -1
        
        if (showIndex) {
            index = section.indexes != nil ? section.indexes![(indexPath as NSIndexPath).section]+(indexPath as NSIndexPath).row : -1
        } else {
            index = (indexPath as NSIndexPath).row
        }
        
        // Configure the cell...
        switch purpose! {
        case .selectingAction:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
            
        case .selectingFiltering:
            //            print("strings: \(strings[indexPath.row]) sermontTag: \(globals.sermonTag)")
            switch globals.showing {
            case .all:
                if strings![index] == Constants.All {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
            
            case .filtered:
                if strings![index] == globals.filter {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
            }
            
        case .selectingSorting:
            if (strings?[index].lowercased() == globals.sorting?.lowercased()) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        case .selectingShow:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
        }

        cell.textLabel?.text = strings![index]

        return cell
    }

    override func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRowAtIndexPath(indexPath)

        var index = -1
        if (showIndex) {
            index = self.section.indexes != nil ? self.section.indexes![(indexPath as NSIndexPath).section]+(indexPath as NSIndexPath).row : -1
        } else {
            index = (indexPath as NSIndexPath).row
        }

        delegate?.rowClickedAtIndex(index, strings: self.strings!, purpose: self.purpose!, sermon: self.selectedSermon)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
