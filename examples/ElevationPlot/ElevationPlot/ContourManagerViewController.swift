//
//  ContourManagerViewController.swift
//  ElevationPlot
//
//  Created by Steve Wainwright on 02/08/2022.
//

import UIKit

@objc protocol ContourManagerViewControllerDelegate: NSObjectProtocol{
    @objc optional func contourManagerViewControllerChoice(_ contourManagerViewController: ContourManagerViewController, userSelectedChoiceChanged changed: Bool, contourManagerCounter: Int)
}

class ContourManagerViewController: UITableViewController {
    
    weak var delegate: ContourManagerViewControllerDelegate?
    @IBOutlet var headerView: UIView?
    @IBOutlet var headerLabel: UILabel?
    
    var contourManagerCounter: Int = 0
    var contourManagerRecords: [ContourManagerRecord]?
    private var choiceChanged = false
    private var previousChoice: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        // Register the class for a header view reuse.
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "TableViewSectionHeaderViewIdentifier")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        choiceChanged = false
        
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            headerView?.frame = CGRect(x: 0 , y: 0, width: 0, height: 0)
//            headerLabel?.frame = CGRect(x: 0 , y: 0, width: 0, height: 0)
//            headerLabel?.text = ""
//        }
        

        tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        navigationController?.navigationBar.isTranslucent = false
        
        changePreferredContentSize()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _contourManagerRecords = contourManagerRecords {
            var noRecords: Int = 0
            if section == 0 {
                for record in _contourManagerRecords {
                    if record.functionExpression != nil {
                        noRecords += 1
                    }
                }
            }
            else {
                for record in _contourManagerRecords {
                    if record.data != nil {
                        noRecords += 1
                    }
                }
            }
            return noRecords
        }
        else {
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        if let _contourManagerRecords = contourManagerRecords {
            var currentContour: ContourManagerRecord?
            var counterRecords: Int = 0, counterAllRecords = 0
            if indexPath.section == 0 {
                for record in _contourManagerRecords {
                    if record.functionExpression != nil {
                        if indexPath.row == counterRecords {
                            currentContour = record
                            break;
                        }
                        counterRecords += 1
                    }
                    counterAllRecords += 1
                }
            }
            else {
                for record in _contourManagerRecords {
                    if record.data != nil {
                        if indexPath.row == counterRecords {
                            currentContour = record
                            break;
                        }
                        counterRecords += 1
                    }
                    counterAllRecords += 1
                }
            }
            if let _currentContour = currentContour {
                cell.textLabel?.text = _currentContour.plottitle
            }
            cell.textLabel?.textColor = .blue
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16.0)
            var backgroundConfiguration = cell.backgroundConfiguration
            backgroundConfiguration?.backgroundColor = .white
            cell.backgroundConfiguration = backgroundConfiguration
            cell.tag = counterAllRecords
            cell.accessoryType = counterAllRecords == contourManagerCounter ? .checkmark : .none
            if counterAllRecords == contourManagerCounter {
                previousChoice = IndexPath(row: indexPath.row, section: indexPath.section)
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TableViewSectionHeaderViewIdentifier") {
            if let tintColour = sectionHeaderView.tintColor,
               !tintColour.isEqual(UIColor.white) {
                sectionHeaderView.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: self.tableView(self.tableView, heightForHeaderInSection: section))
                sectionHeaderView.tintColor = UIColor.white
                var backgroundConfiguration = sectionHeaderView.backgroundConfiguration
                backgroundConfiguration?.backgroundColor = UIColor.gray
                sectionHeaderView.backgroundConfiguration = backgroundConfiguration
                var leadingEdgeConstraintConstant: CGFloat = 16.0
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, windowScene.interfaceOrientation.isLandscape {
                    leadingEdgeConstraintConstant = 50.0//44.0
                }
                var lab: UILabel
                if UIDevice.current.userInterfaceIdiom == .phone {
                    lab = UILabel(frame: CGRect(x: leadingEdgeConstraintConstant, y: 2.5, width: self.tableView.frame.size.width - leadingEdgeConstraintConstant * 2.0, height: 20.0))
                    lab.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.heavy)
                }
                else {
                    lab = UILabel(frame: CGRect(x: leadingEdgeConstraintConstant, y: 2.5, width: self.tableView.frame.size.width - leadingEdgeConstraintConstant * 2.0, height: 25.0))
                    lab.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.heavy)
                }
                lab.tag = 1
                lab.textColor = UIColor.white
                lab.backgroundColor = UIColor.clear
                if section == 0 {
                    lab.text = "Function Plots".uppercased()
                }
                else {
                    lab.text = "Raw Data".uppercased()
                }
                sectionHeaderView.contentView.addSubview(lab)
                lab.translatesAutoresizingMaskIntoConstraints = false
                
                sectionHeaderView.addConstraints([
                    NSLayoutConstraint(item: lab, attribute: .centerY, relatedBy: .equal, toItem: sectionHeaderView, attribute: .centerY, multiplier: 1.0, constant: 0.0),
                    NSLayoutConstraint(item: lab, attribute: .leading, relatedBy: .equal, toItem: sectionHeaderView, attribute: .leading, multiplier: 1.0, constant: leadingEdgeConstraintConstant),
                    NSLayoutConstraint(item: lab, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: lab.bounds.size.width),
                    NSLayoutConstraint(item: lab, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: lab.bounds.size.height)
                    ])
            }
            else {
                let label = sectionHeaderView.contentView.subviews[0]
                if label is UILabel {
                    let lab: UILabel? = (label as? UILabel)
                    if section == 0 {
                        lab?.text = "Function Plots".uppercased()
                    }
                    else {
                        lab?.text = "Raw Data".uppercased()
                    }
                }
            }
            return sectionHeaderView
        }
        else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return 25.0
        }
        else {
            return 30.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeight: CGFloat = 50.0
        if UIDevice.current.userInterfaceIdiom == .phone {
            rowHeight = 40.0
        }
        return rowHeight
    }

    
    // MARK: -
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            contourManagerCounter = cell.tag
            if let _previousChoice = previousChoice {
                choiceChanged = _previousChoice.compare(indexPath) != .orderedSame
                if choiceChanged {
                    if let cell = self.tableView.cellForRow(at: _previousChoice) {
                        cell.accessoryType = .none
                    }
                }
            }
            else {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
                    cell.accessoryType = .none
                }
                choiceChanged = true
            }
            previousChoice = IndexPath(row: indexPath.row, section: indexPath.section)
            if choiceChanged {
                notifyDelegateContourManageChoiceChanged()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        if !(self.presentationController is UIPopoverPresentationController) {
            self.dismiss(animated: true)
        }
    }
    
    // MARK: -
    // MARK: Actions delegate
    func notifyDelegateContourManageChoiceChanged() {
        if let _delegate = delegate,
           _delegate.responds(to: #selector(ContourManagerViewControllerDelegate.contourManagerViewControllerChoice(_:userSelectedChoiceChanged:contourManagerCounter:))) {
            _delegate.contourManagerViewControllerChoice!(self, userSelectedChoiceChanged: choiceChanged, contourManagerCounter: contourManagerCounter)
        }
        choiceChanged = false
    }
    
    // MARK: -
    // MARK: Miscellaneous Routines
    
    func changePreferredContentSize() {
        var height = headerView?.bounds.size.height ?? 48.0
        for i in 0..<numberOfSections(in: tableView) {
            height += tableView(tableView, heightForHeaderInSection: i)
            height += tableView(tableView, heightForFooterInSection: i)
            for j in 0..<tableView(tableView, numberOfRowsInSection: i) {
                height += tableView(tableView, heightForRowAt: IndexPath(row: j, section: i))
            }
        }
        if height > 600.0 {
            height = 600.0
        }
        preferredContentSize = CGSize(width: 350.0, height: height)
        // iPad UI
    }
}
