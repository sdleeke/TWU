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
    func rowClickedAtIndex(_ index:Int, strings:[String], purpose:PopoverPurpose)
}

struct Section {
    var titles:[String]?
    var counts:[Int]?
    var indexes:[Int]?
}

class PopoverTableViewController: UITableViewController {
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var showIndex:Bool = false
    var showSectionHeaders:Bool = false
    
    var strings:[String]?
    
    lazy var section:Section! = {
        var section = Section()
        return section
    }()
    
    func setPreferredContentSize()
    {
        guard let strings = strings else {
            return
        }
        
        self.tableView.sizeToFit()
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0
        
        for string in strings {
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 44.0)
            let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16.0)], context: nil)
            
            let heightSize: CGSize = CGSize(width: view.bounds.width - 30, height: .greatestFiniteMagnitude)
            let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16.0)], context: nil)
            
            if maxWidth.width > width {
                width = maxWidth.width
            }
            
            height += 44
            
            height += CGFloat(((Int(maxHeight.height) / 16) - 1) * 16)
        }
        
        width += 2*20
        
        if let purpose = purpose {
            switch purpose {
            case .selectingFiltering:
                fallthrough
            case .selectingSorting:
                width += 44
                break
                
            default:
                break
            }
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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func setupIndex()
    {
        guard showIndex else {
            return
        }
        
        guard let strings = strings else {
            return
        }

        let a = "A"
            
        let sectionTitles = Array(Set(strings.map({ (string:String) -> String in
            if let string = stringWithoutPrefixes(string) {
                return String(string[..<a.endIndex])
            }
            
            return ""
        }))).sorted() { $0 < $1 }
        
        var indexes = [Int]()
        var counts = [Int]()
        
        for sectionTitle in sectionTitles {
            var counter = 0
            
            for index in 0..<strings.count {
                if var string = stringWithoutPrefixes(strings[index]) {
                    string = String(string[..<a.endIndex])
                    
                    if (sectionTitle == string) {
                        if (counter == 0) {
                            indexes.append(index)
                        }
                        counter += 1
                    }
                }
            }
            
            counts.append(counter)
        }
        
        section.titles = sectionTitles.count > 0 ? sectionTitles : nil
        
        section.indexes = indexes.count > 0 ? indexes : nil
        section.counts = counts.count > 0 ? counts : nil
    }
    
    @objc func willResignActive()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.willResignActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        
        setupIndex()
        
        tableView.reloadData()
        
        setPreferredContentSize()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

//        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if showIndex {
            return self.section.titles?.count ?? 0
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if showIndex {
            return self.section.counts?[section] ?? 0
        } else {
            return strings?.count ?? 0
        }
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        if (showIndex) {
            return self.section.titles
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        if (showIndex) {
            return index
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if (showIndex && showSectionHeaders) {
            return self.section.titles?[section]
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath)

        var index = -1
        
        if showIndex, let indexes = section.indexes {
            index = indexes[indexPath.section] + indexPath.row
        } else {
            index = indexPath.row
        }
        
        guard let purpose = purpose else {
            return cell
        }
        
        // Configure the cell...
        switch purpose {
        case .selectingAction:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
            
        case .selectingFiltering:
            switch globals.showing {
            case .all:
                if strings?[index] == Constants.All {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
            
            case .filtered:
                if strings?[index] == globals.filter {
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

        cell.textLabel?.text = strings?[index]

        return cell
    }

    override func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var index = -1
        
        if showIndex, let indexes = self.section.indexes {
            index = indexes[indexPath.section] + indexPath.row
        } else {
            index = indexPath.row
        }

        if let strings = strings, let purpose = purpose {
            delegate?.rowClickedAtIndex(index, strings: strings, purpose: purpose)
        }
    }
}
